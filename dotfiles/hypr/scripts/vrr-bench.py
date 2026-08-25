#!/usr/bin/env python3
"""
vrr-bench -- compositor-agnostic VRR stability benchmark.

Answers "which compositor keeps the refresh rate steadier?" with numbers
instead of impressions. Works under Hyprland, KWin, or anything else: it only
needs /dev/dri and mpv.

WHY THIS EXISTS
  display-probe.py samples refresh every 200 ms and averages. At 240 Hz that
  folds ~48 frames into one number, which hides exactly the frame-to-frame
  oscillation that makes an OLED flicker. This tool blocks on every single
  vblank and records its timestamp, so the per-frame intervals are real.

WHAT IT MEASURES
  Per clip, from true per-vblank timestamps:
    hz_mean / hz_sd     instantaneous refresh
    d_mean / d_p99      |change in refresh between CONSECUTIVE frames|
                        <- this is the direct driver of OLED VRR flicker
    below48             % of frames under the panel's 48 Hz VRR floor
                        (LFC frame-doubling territory, a known flicker trigger)
    track_err           |actual refresh - the clip's nominal fps|
    skipped             % of samples where we missed a vblank (quality check)

LIMITATION
  This measures refresh behaviour, not emitted light. There is no photometer
  here. It proves which compositor produces more refresh instability; that
  flicker follows from it is an inference -- a well-supported one, but an
  inference.

USAGE
  vrr-bench.py gen                       # build the test clips (once)
  vrr-bench.py run --label hyprland      # log out, run again as --label plasma
  vrr-bench.py compare hyprland plasma
"""

from __future__ import annotations

import argparse
import ctypes
import fcntl
import glob
import json
import os
import re
import statistics
import subprocess
import sys
import time

CARD = "/dev/dri/card1"
HOME = os.path.expanduser("~")
BENCH = os.path.join(HOME, ".cache", "vrr-bench")
CLIPS = os.path.join(BENCH, "clips")
RESULTS = os.path.join(BENCH, "results")

W, H = 2560, 1440
FPS_SET = [24, 30, 48, 60, 90, 120]
CLIP_SECS = 20
VRR_FLOOR = 48       # panel EDID FreeSync range: 48-240 Hz
VRR_CEIL = 240.08


# ---------------------------------------------------------------------------
# amdgpu BTR ("Below The Range") model
# ---------------------------------------------------------------------------
# LFC is NOT done by the compositor or the monitor -- it is in the kernel:
#   drivers/gpu/drm/amd/display/modules/freesync/freesync.c :: apply_below_the_range()
#   enabled unconditionally via `config.btr = true` in amdgpu_dm.c
#
# The multiplier is NOT "smallest one above the VRR floor". The kernel picks the
# multiplier whose resulting frame duration lands nearest the MIDPOINT of the
# VRR range (btr.mid_point_in_us). Entry/exit use hysteresis thresholds.
#
# This model reproduced all six measured KWin refresh rates to <=0.01 Hz.
BTR_ENTRY_US = 19583   # frame time above this -> BTR engages (~51.06 fps)
BTR_EXIT_US = 17083    # frame time below this -> BTR disengages (~58.54 fps)


def btr_predict(fps: float, vmin=VRR_FLOOR, vmax=VRR_CEIL):
    """Return (predicted_refresh_hz, multiplier, btr_active)."""
    min_dur, max_dur = 1e6 / vmax, 1e6 / vmin
    mid = (min_dur + max_dur) / 2.0
    dur = 1e6 / fps
    if dur <= BTR_ENTRY_US:          # starts out of BTR and never enters
        return fps, 1, False
    mult = min(range(1, 11), key=lambda m: abs(dur / m - mid))
    return fps * mult, mult, True


def naive_predict(fps: float, vmin=VRR_FLOOR):
    """The rule I originally (wrongly) proposed: smallest multiple >= floor."""
    for m in range(1, 11):
        if fps * m >= vmin:
            return fps * m, m
    return fps, 1


# ---------------------------------------------------------------------------
# DRM vblank -- blocking, one sample per actual vblank
# ---------------------------------------------------------------------------
class _Req(ctypes.Structure):
    _fields_ = [("type", ctypes.c_uint32), ("sequence", ctypes.c_uint32), ("signal", ctypes.c_ulong)]


class _Reply(ctypes.Structure):
    _fields_ = [("type", ctypes.c_uint32), ("sequence", ctypes.c_uint32),
                ("tval_sec", ctypes.c_long), ("tval_usec", ctypes.c_long)]


class _VB(ctypes.Union):
    _fields_ = [("request", _Req), ("reply", _Reply)]


_RELATIVE = 0x1
_IOCTL = (3 << 30) | (ctypes.sizeof(_VB) << 16) | (ord("d") << 8) | 0x3A


class VBlank:
    def __init__(self, card=CARD):
        self.fd = os.open(card, os.O_RDWR)

    def wait(self, pipe: int):
        """Block until the next vblank on `pipe`; return (sequence, timestamp)."""
        u = _VB()
        u.request.type = _RELATIVE | (pipe << 1)
        u.request.sequence = 1
        fcntl.ioctl(self.fd, _IOCTL, u)
        return u.reply.sequence, u.reply.tval_sec + u.reply.tval_usec / 1e6

    def probe(self, pipe: int) -> bool:
        try:
            u = _VB()
            u.request.type = _RELATIVE | (pipe << 1)
            u.request.sequence = 0
            fcntl.ioctl(self.fd, _IOCTL, u)
            return True
        except OSError:
            return False

    def close(self):
        os.close(self.fd)


# ---------------------------------------------------------------------------
# KMS -- works under any compositor
# ---------------------------------------------------------------------------
def kms_connectors():
    """Connector names in KMS order, plus whether each is connected."""
    try:
        raw = subprocess.run(["proptest", "-M", "amdgpu"], capture_output=True,
                             text=True, timeout=20).stdout
    except Exception:
        return []
    out = []
    for m in re.finditer(r"^Connector (\d+) \(([^)]+)\)", raw, re.M):
        name = m.group(2)
        base = os.path.basename(glob.glob(f"/sys/class/drm/card*-{name}")[0]) if glob.glob(
            f"/sys/class/drm/card*-{name}") else None
        st = ""
        if base:
            try:
                st = open(f"/sys/class/drm/{base}/status").read().strip()
            except OSError:
                pass
        out.append((name, st == "connected"))
    return out


def pipe_for(monitor: str):
    """Map a connector name to a DRM pipe index, without needing a compositor.

    AMD assigns pipes to connected connectors in KMS order, so the Nth
    connected connector is pipe N. Verified on this machine against measured
    refresh (DP-1 -> pipe 0 @240 Hz, DP-2 -> pipe 1 @60 Hz).
    """
    idx = 0
    for name, connected in kms_connectors():
        if not connected:
            continue
        if name == monitor:
            return idx
        idx += 1
    return None


def vrr_active() -> bool:
    try:
        raw = subprocess.run(["proptest", "-M", "amdgpu"], capture_output=True,
                             text=True, timeout=20).stdout
    except Exception:
        return False
    for m in re.finditer(r"^CRTC \d+(.*?)(?=^CRTC |^Connector |\Z)", raw, re.M | re.S):
        v = re.search(r"VRR_ENABLED:.*?value: (\d+)", m.group(1), re.S)
        if v and v.group(1) == "1":
            return True
    return False


# ---------------------------------------------------------------------------
# clip generation
# ---------------------------------------------------------------------------
def cmd_gen(args):
    os.makedirs(CLIPS, exist_ok=True)
    fps_set = [int(x) for x in args.fps.split(",") if x.strip()] or FPS_SET
    print(f"  generating {len(fps_set)} clips into {CLIPS}\n")
    # Mid-grey background with moving lighter/darker bars. Average picture
    # level stays essentially constant, which keeps the panel's ABL (automatic
    # brightness limiter) out of the measurement -- otherwise we'd be mixing
    # two unrelated flicker sources.
    vf = (
        "drawbox=x='mod(t*520\\,{w}+260)-260':y=0:w=260:h={h}:color=0xA8A8A8:t=fill,"
        "drawbox=x=0:y='mod(t*300\\,{h}+180)-180':w={w}:h=180:color=0x585858:t=fill,"
        "drawtext=fontfile=/usr/share/fonts/TTF/DejaVuSans-Bold.ttf:"
        "text='%{{n}}  |  {fps} fps':x=60:y=60:fontsize=64:fontcolor=0xE0E0E0"
    )
    for fps in fps_set:
        out = os.path.join(CLIPS, f"vrr_{fps}.mp4")
        cmd = [
            "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
            "-f", "lavfi", "-i", f"color=c=0x808080:s={W}x{H}:r={fps}:d={CLIP_SECS}",
            "-vf", vf.format(w=W, h=H, fps=fps),
            "-c:v", "libx264", "-preset", "veryfast", "-crf", "20",
            "-pix_fmt", "yuv420p", "-r", str(fps),
            out,
        ]
        t0 = time.time()
        p = subprocess.run(cmd, capture_output=True)
        if p.returncode:
            print(p.stderr.decode()[-800:])
            return 1
        sz = os.path.getsize(out) / 1e6
        print(f"    vrr_{fps:<3}.mp4   {sz:5.1f} MB   {time.time()-t0:4.1f}s")

    print("\n  verifying constant average picture level (guards against ABL)...")
    for fps in fps_set:
        out = os.path.join(CLIPS, f"vrr_{fps}.mp4")
        p = subprocess.run(
            ["ffprobe", "-hide_banner", "-loglevel", "error", "-f", "lavfi",
             f"movie={out},signalstats", "-show_entries", "frame_tags=lavfi.signalstats.YAVG",
             "-of", "json", "-read_intervals", "%+#40"],
            capture_output=True, text=True)
        try:
            d = json.loads(p.stdout)
            ys = [float(f["tags"]["lavfi.signalstats.YAVG"]) for f in d.get("frames", [])
                  if "tags" in f]
            if ys:
                spread = max(ys) - min(ys)
                ok = "OK" if spread < 3.0 else "!! varies"
                print(f"    {fps:>3} fps  YAVG {statistics.fmean(ys):6.2f}  spread {spread:5.2f}  {ok}")
        except Exception:
            print(f"    {fps:>3} fps  (could not verify)")
    print(f"\n  done. now run:  {sys.argv[0]} run --label <hyprland|plasma>")
    return 0


# ---------------------------------------------------------------------------
# measurement
# ---------------------------------------------------------------------------
def measure(vb: VBlank, pipe: int, secs: float):
    """Collect true per-vblank intervals."""
    samples = []
    skipped = 0
    prev_seq, prev_t = vb.wait(pipe)
    t_end = time.time() + secs
    while time.time() < t_end:
        seq, t = vb.wait(pipe)
        dseq = seq - prev_seq
        dt = t - prev_t
        if dseq == 1 and dt > 0:
            samples.append(dt)
        elif dseq > 1:
            skipped += dseq - 1
        prev_seq, prev_t = seq, t
    return samples, skipped


def analyse(intervals, skipped, nominal_fps):
    hz = [1.0 / i for i in intervals if i > 0]
    if len(hz) < 10:
        return None
    deltas = [abs(hz[i] - hz[i - 1]) for i in range(1, len(hz))]
    srt = sorted(deltas)
    p99 = srt[min(len(srt) - 1, int(0.99 * (len(srt) - 1)))] if srt else 0.0
    below = 100.0 * sum(1 for h in hz if h < VRR_FLOOR) / len(hz)
    total = len(hz) + skipped
    return {
        "frames": len(hz),
        "hz_mean": statistics.fmean(hz),
        "hz_sd": statistics.pstdev(hz),
        "hz_min": min(hz),
        "hz_max": max(hz),
        "d_mean": statistics.fmean(deltas) if deltas else 0.0,
        "d_p99": p99,
        "below48": below,
        "track_err": abs(statistics.fmean(hz) - nominal_fps),
        "skipped_pct": 100.0 * skipped / total if total else 0.0,
    }


def cmd_run(args):
    os.makedirs(RESULTS, exist_ok=True)
    pipe = pipe_for(args.monitor)
    if pipe is None:
        print(f"  could not map {args.monitor} to a DRM pipe. connectors seen:")
        for n, c in kms_connectors():
            print(f"    {n}  {'connected' if c else 'disconnected'}")
        return 1

    fps_set = [int(x) for x in args.fps.split(",") if x.strip()] or FPS_SET
    clips = [(f, os.path.join(CLIPS, f"vrr_{f}.mp4")) for f in fps_set]
    missing = [c for _, c in clips if not os.path.exists(c)]
    if missing:
        print(f"  clips missing -- run `{sys.argv[0]} gen` first")
        return 1

    print(f"  vrr-bench  label={args.label}  monitor={args.monitor} (pipe {pipe})")
    print(f"  {args.secs:.0f}s measured per clip, {len(clips)} clips\n")
    print("  !! do not move the mouse or change focus during the run !!\n")
    print(f"  {'clip':>7} {'VRR':>4} {'measured':>9} {'BTR pred':>9} {'naive':>7} {'err':>7} {'hz_sd':>6} {'d_mean':>7}")
    print("  " + "-" * 72)

    vb = VBlank()
    out = {"label": args.label, "monitor": args.monitor, "when": time.strftime("%F %T"),
           "secs": args.secs, "clips": {}}

    for fps, path in clips:
        proc = subprocess.Popen(
            ["mpv", "--fullscreen", f"--fs-screen-name={args.monitor}",
             "--vo=gpu-next", "--video-sync=audio", "--loop", "--no-osc",
             "--no-terminal", "--no-audio", "--cursor-autohide=0", path],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(args.settle)
        vrr = vrr_active()
        try:
            ivals, skipped = measure(vb, pipe, args.secs)
        finally:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
            time.sleep(1.0)

        r = analyse(ivals, skipped, fps)
        if not r:
            print(f"  {fps:>6}    --  (too few samples)")
            continue
        r["vrr"] = vrr
        out["clips"][str(fps)] = r
        pred, mult, btr = btr_predict(fps)
        naive, _ = naive_predict(fps)
        r["btr_pred"], r["btr_mult"], r["btr_active"], r["naive_pred"] = pred, mult, btr, naive
        print(f"  {fps:>5}fps {'ON' if vrr else 'off':>4} {r['hz_mean']:9.2f} "
              f"{pred:7.1f}({mult}x) {naive:7.1f} {r['hz_mean']-pred:+7.2f} "
              f"{r['hz_sd']:6.2f} {r['d_mean']:7.2f}")

    vb.close()
    dest = os.path.join(RESULTS, f"{args.label}.json")
    with open(dest, "w") as f:
        json.dump(out, f, indent=2)
    print(f"\n  saved {dest}")
    return 0


def cmd_compare(args):
    data = {}
    for lab in (args.a, args.b):
        p = os.path.join(RESULTS, f"{lab}.json")
        if not os.path.exists(p):
            print(f"  missing {p}")
            return 1
        data[lab] = json.load(open(p))

    a, b = args.a, args.b
    print(f"\n  {a}  vs  {b}\n")
    print("  d_mean = average |change in refresh| between consecutive frames.")
    print("  This is the quantity an OLED converts into visible flicker.\n")
    print(f"  {'clip':>7} | {a[:11]:>26} | {b[:11]:>26} |")
    print(f"  {'':>7} | {'d_mean':>8} {'d_p99':>8} {'<48':>7} | {'d_mean':>8} {'d_p99':>8} {'<48':>7} | winner")
    print("  " + "-" * 82)
    wins = {a: 0, b: 0}
    for fps in FPS_SET:
        k = str(fps)
        ra, rb = data[a]["clips"].get(k), data[b]["clips"].get(k)
        if not ra or not rb:
            continue
        w = a if ra["d_mean"] < rb["d_mean"] else b
        ratio = max(ra["d_mean"], rb["d_mean"]) / max(1e-6, min(ra["d_mean"], rb["d_mean"]))
        wins[w] += 1
        print(f"  {fps:>5}fps | {ra['d_mean']:8.2f} {ra['d_p99']:8.2f} {ra['below48']:6.1f}% |"
              f" {rb['d_mean']:8.2f} {rb['d_p99']:8.2f} {rb['below48']:6.1f}% | {w} ({ratio:.1f}x)")
    print()
    for lab in (a, b):
        ds = [c["d_mean"] for c in data[lab]["clips"].values()]
        if ds:
            print(f"    {lab:<12} overall mean d_mean = {statistics.fmean(ds):7.3f} Hz")
    print(f"\n    clip wins: {a} {wins[a]}, {b} {wins[b]}")
    print("\n    Reminder: this measures refresh stability, not emitted light.")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    g = sub.add_parser("gen", help="generate the test clips")
    g.add_argument("--fps", default="", help="comma list, e.g. 20,25,26,40,55")

    r = sub.add_parser("run", help="play every clip and measure")
    r.add_argument("--label", required=True, help="e.g. hyprland / plasma")
    r.add_argument("--monitor", default="DP-1")
    r.add_argument("--secs", type=float, default=15.0)
    r.add_argument("--settle", type=float, default=4.0)
    r.add_argument("--fps", default="", help="comma list; defaults to the standard set")

    c = sub.add_parser("compare", help="compare two runs")
    c.add_argument("a")
    c.add_argument("b")

    args = ap.parse_args()
    return {"gen": cmd_gen, "run": cmd_run, "compare": cmd_compare}[args.cmd](args)


if __name__ == "__main__":
    sys.exit(main() or 0)
