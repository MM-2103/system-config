#!/usr/bin/env python3
"""
display-probe -- objective display state for Hyprland on AMD KMS.

Built because "does this look different to you?" is a terrible way to debug a
display. Everything here is read from the kernel or the compositor; nothing
relies on human perception.

Sources of truth, in order of trustworthiness:
  1. DRM/KMS connector + CRTC properties (proptest)  -- what the panel is told
  2. DRM vblank counter (ioctl)                      -- what the panel does
  3. hyprctl                                         -- what Hyprland intends

These disagree more often than you'd hope. In particular, Hyprland's
`hyprctl monitors -> vrr` and `colorManagementPreset` are statements of intent
that can silently fail to reach the hardware. Trust 1 and 2 over 3.

Commands
  snapshot            one-shot full state
  watch [-s SECS]     sample refresh rate + detect state changes over time
  verify              compare live state against the on-disk Lua config

Usage
  scripts/display-probe.py snapshot
  scripts/display-probe.py watch -s 20
  scripts/display-probe.py verify
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
CONFIG = os.path.expanduser("~/.config/hypr/lua/monitors.lua")

EOTF_NAMES = {
    0: "SDR (traditional gamma)",
    1: "HDR (traditional gamma)",
    2: "SMPTE ST2084 (PQ)",
    3: "HLG",
}
COLORSPACE_NAMES = {
    0: "Default (sRGB)",
    2: "BT709_YCC",
    7: "opRGB",
    9: "BT2020_RGB",
    10: "BT2020_YCC",
}


# --------------------------------------------------------------------------
# DRM vblank -- actual refresh rate, straight from the hardware counter
# --------------------------------------------------------------------------
class _Req(ctypes.Structure):
    _fields_ = [("type", ctypes.c_uint32), ("sequence", ctypes.c_uint32), ("signal", ctypes.c_ulong)]


class _Reply(ctypes.Structure):
    _fields_ = [
        ("type", ctypes.c_uint32),
        ("sequence", ctypes.c_uint32),
        ("tval_sec", ctypes.c_long),
        ("tval_usec", ctypes.c_long),
    ]


class _VBlank(ctypes.Union):
    _fields_ = [("request", _Req), ("reply", _Reply)]


_DRM_VBLANK_RELATIVE = 0x1
_HIGH_CRTC_SHIFT = 1
_IOCTL_WAIT_VBLANK = (3 << 30) | (ctypes.sizeof(_VBlank) << 16) | (ord("d") << 8) | 0x3A


class VBlankReader:
    """Reads the DRM vblank sequence counter. No DRM master required."""

    def __init__(self, card: str = CARD):
        self.fd = os.open(card, os.O_RDWR)

    def sample(self, pipe: int):
        u = _VBlank()
        u.request.type = _DRM_VBLANK_RELATIVE | (pipe << _HIGH_CRTC_SHIFT)
        u.request.sequence = 0
        fcntl.ioctl(self.fd, _IOCTL_WAIT_VBLANK, u)
        return u.reply.sequence, u.reply.tval_sec + u.reply.tval_usec / 1e6

    def pipes(self):
        found = []
        for p in range(8):
            try:
                self.sample(p)
                found.append(p)
            except OSError:
                pass
        return found

    def close(self):
        os.close(self.fd)


# --------------------------------------------------------------------------
# KMS properties
# --------------------------------------------------------------------------

def _proptest_raw() -> str:
    try:
        return subprocess.run(["proptest", "-M", "amdgpu"], capture_output=True,
                              text=True, timeout=20).stdout
    except Exception:
        return ""

def read_kms():
    """Parse proptest output into {connector: {...}} plus CRTC VRR state."""
    raw = _proptest_raw()
    if not raw:
        return {}, {}, "proptest produced no output"

    connectors = {}
    for m in re.finditer(r"^Connector (\d+) \(([^)]+)\)(.*?)(?=^Connector |\Z)", raw, re.M | re.S):
        cid, name, body = m.group(1), m.group(2), m.group(3)
        info = {"id": cid}

        bpc = re.search(r"max bpc:.*?value: (\d+)", body, re.S)
        info["max_bpc"] = int(bpc.group(1)) if bpc else None

        cs = re.search(r"Colorspace:.*?value: (\d+)", body, re.S)
        info["colorspace"] = int(cs.group(1)) if cs else None

        vc = re.search(r"vrr_capable:.*?value: (\d+)", body, re.S)
        info["vrr_capable"] = int(vc.group(1)) if vc else None

        hm = re.search(r"HDR_OUTPUT_METADATA:.*?value:\n((?:\t+[0-9a-f]+\n)*)", body, re.S)
        blob = "".join(re.findall(r"[0-9a-f]{8,}", hm.group(1))) if hm else ""
        info["hdr"] = decode_hdr(blob)

        connectors[name] = info

    crtcs = {}
    for m in re.finditer(r"^CRTC (\d+)(.*?)(?=^CRTC |^Connector |\Z)", raw, re.M | re.S):
        cid, body = m.group(1), m.group(2)
        v = re.search(r"VRR_ENABLED:.*?value: (\d+)", body, re.S)
        if v:
            crtcs[cid] = int(v.group(1))

    return connectors, crtcs, None


def decode_hdr(hexs: str):
    if not hexs:
        return None
    b = bytes.fromhex(hexs)
    if len(b) < 30:
        return {"raw": hexs}
    u = lambda o: int.from_bytes(b[o : o + 2], "little")
    return {
        "eotf": b[4],
        "eotf_name": EOTF_NAMES.get(b[4], f"unknown({b[4]})"),
        "primaries": [(u(6), u(8)), (u(10), u(12)), (u(14), u(16))],
        "white": (u(18), u(20)),
        "mastering_max": u(22),
        "mastering_min": u(24),
        "max_cll": u(26),
        "max_fall": u(28),
    }


# --------------------------------------------------------------------------
# Hyprland
# --------------------------------------------------------------------------
def hypr(*args):
    try:
        out = subprocess.run(
            ["hyprctl", "-i", "0", *args, "-j"], capture_output=True, text=True, timeout=15
        ).stdout
        return json.loads(out)
    except Exception:
        return None


def hypr_state():
    mons = hypr("monitors") or []
    clients = hypr("clients") or []
    fs = [
        c
        for c in clients
        if c.get("mapped") and c.get("fullscreen", 0) == 2
    ]
    return mons, fs


# --------------------------------------------------------------------------
# Reporting
# --------------------------------------------------------------------------
def connected_connectors():
    """Connector names in KMS order that are actually connected.

    Compositor-independent -- used as a fallback so this tool still works
    outside Hyprland (e.g. when comparing against KWin).
    """
    out = []
    for name in re.findall(r"^Connector \d+ \(([^)]+)\)", _proptest_raw(), re.M):
        paths = glob.glob(f"/sys/class/drm/card*-{name}")
        if not paths:
            continue
        try:
            if open(os.path.join(paths[0], "status")).read().strip() == "connected":
                out.append(name)
        except OSError:
            pass
    return out


def pipe_map(mons, pipes):
    """Map DRM pipe index -> connector name.

    AMD assigns pipes in connector order, so pipe N corresponds to the Nth
    connected connector. Verified on this machine against measured refresh
    (DP-1 -> pipe 0 @240 Hz, DP-2 -> pipe 1 @60 Hz).
    """
    ordered = [m["name"] for m in sorted(
        [m for m in mons if not m.get("disabled")], key=lambda m: m["id"])]
    if not ordered:  # no hyprctl -- fall back to KMS
        ordered = connected_connectors()
    return {p: (ordered[i] if i < len(ordered) else f"pipe{p}") for i, p in enumerate(pipes)}


def cmd_snapshot(_args):
    conns, crtcs, err = read_kms()
    mons, fs = hypr_state()
    if err:
        print(f"  !! {err}")

    print("=" * 72)
    print(f"  display-probe snapshot   {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 72)

    vb = VBlankReader()
    pipes = vb.pipes()
    pmap = pipe_map(mons, pipes)

    for m in mons:
        name = m["name"]
        k = conns.get(name, {})
        print(f"\n  {name}  ({m['description'][:46]})")
        print(f"    mode            {m['width']}x{m['height']} @ {m['refreshRate']:.2f} Hz (nominal)")

        # measured
        pi = next((p for p, n in pmap.items() if n == name), None)
        if pi is not None:
            try:
                s0, t0 = vb.sample(pi)
                time.sleep(0.5)
                s1, t1 = vb.sample(pi)
                meas = (s1 - s0) / (t1 - t0)
                print(f"    MEASURED        {meas:.2f} Hz   <- actual vblank rate")
            except OSError:
                pass

        print(f"    scale/transform {m['scale']} / {m['transform']}")
        print(f"    hyprland says   vrr={m['vrr']}  cm={m.get('colorManagementPreset')}  fmt={m['currentFormat']}")

        cs = k.get("colorspace")
        print(f"    KERNEL says     colorspace={COLORSPACE_NAMES.get(cs, cs)}  max_bpc={k.get('max_bpc')}  vrr_capable={k.get('vrr_capable')}")

        h = k.get("hdr")
        if h:
            print(f"    HDR             ACTIVE -- {h['eotf_name']}")
            print(f"                    mastering max={h['mastering_max']} min={h['mastering_min']} "
                  f"MaxCLL={h['max_cll']} MaxFALL={h['max_fall']}")
        else:
            print(f"    HDR             off (no HDR_OUTPUT_METADATA)")

    print(f"\n  CRTC VRR_ENABLED: " + (", ".join(f"{c}={v}" for c, v in crtcs.items()) or "none"))
    active = [c for c, v in crtcs.items() if v == 1]
    print(f"  VRR ACTUALLY ACTIVE: {'YES on CRTC ' + ','.join(active) if active else 'NO'}")

    if fs:
        print("\n  fullscreen windows:")
        for c in fs:
            print(f"    {c['class']!r} ws={c['workspace']['id']} mon={c['monitor']} "
                  f"content={c.get('contentType')!r} handler={c.get('fullscreenHandler')!r}")
    else:
        print("\n  fullscreen windows: none")

    vb.close()
    print()


def cmd_watch(args):
    """Sample refresh rate + state. Refresh VARIANCE is the objective flicker metric."""
    vb = VBlankReader()
    pipes = vb.pipes()
    mons, _ = hypr_state()
    pmap = pipe_map(mons, pipes)

    target = args.monitor
    pi = next((p for p, n in pmap.items() if n == target), None)
    if pi is None:
        print(f"  monitor {target!r} not found. known: {list(pmap.values())}")
        return 1

    print(f"  watching {target} (pipe {pi}) for {args.secs}s -- play/interact now\n")
    samples = []
    last_state = None
    changes = []
    t_start = time.time()
    prev = vb.sample(pi)

    while time.time() - t_start < args.secs:
        time.sleep(args.interval)
        cur = vb.sample(pi)
        dt = cur[1] - prev[1]
        if dt > 0:
            hz = (cur[0] - prev[0]) / dt
            samples.append((time.time() - t_start, hz))
        prev = cur

        conns, crtcs, _ = read_kms()
        k = conns.get(target, {})
        st = (
            k.get("colorspace"),
            k.get("max_bpc"),
            bool(k.get("hdr")),
            (k.get("hdr") or {}).get("eotf"),
            tuple(sorted(crtcs.items())),
        )
        if last_state is not None and st != last_state:
            changes.append((time.time() - t_start, last_state, st))
            print(f"  [{time.time()-t_start:6.1f}s] STATE CHANGE")
            _diff_state(last_state, st)
        last_state = st

    vb.close()

    if not samples:
        print("  no samples collected")
        return 1

    hzs = [h for _, h in samples]
    mean = statistics.fmean(hzs)
    sd = statistics.pstdev(hzs) if len(hzs) > 1 else 0.0
    srt = sorted(hzs)
    pct = lambda p: srt[min(len(srt) - 1, max(0, int(round(p / 100 * (len(srt) - 1)))))]
    p1, p50, p99 = pct(1), pct(50), pct(99)

    print(f"\n  {'-'*66}")
    print(f"  REFRESH RATE over {args.secs}s ({len(hzs)} samples)")
    print(f"    mean {mean:8.2f} Hz")
    print(f"    min  {min(hzs):8.2f} Hz")
    print(f"    max  {max(hzs):8.2f} Hz")
    print(f"    range{max(hzs)-min(hzs):8.2f} Hz")
    print(f"    stdev{sd:8.2f} Hz")
    print(f"    p1   {p1:8.2f} Hz   p50 {p50:7.2f}   p99 {p99:7.2f}")

    print(f"\n  {_sparkline(hzs)}")

    # Distribution shape matters more than the summary stats. A single broad
    # hump = the game's own frame rate varying. Two or more clusters = extra
    # presenters (compositor, overlays) driving the panel independently, in
    # which case capping the game alone will NOT flatten the refresh.
    print(f"\n  DISTRIBUTION")
    lo, hi = min(hzs), max(hzs)
    nb = 12
    if hi - lo > 1e-6:
        width = (hi - lo) / nb
        bins = [0] * nb
        for h in hzs:
            bins[min(nb - 1, int((h - lo) / width))] += 1
        peak = max(bins) or 1
        for i, c in enumerate(bins):
            a, b = lo + i * width, lo + (i + 1) * width
            bar = "#" * int(round(40 * c / peak))
            pctg = 100 * c / len(hzs)
            print(f"    {a:6.0f}-{b:<6.0f} {bar:<40} {pctg:5.1f}%")

    # With VRR active the panel tracks the presented frame rate, so this
    # distribution IS the frame rate distribution. The 1st percentile is the
    # practical floor -- cap below it and the cap always holds, which keeps
    # refresh flat and makes OLED VRR flicker impossible.
    nominal = 240.0
    for m in (hypr("monitors") or []):
        if m["name"] == args.monitor:
            nominal = m["refreshRate"]
    divisors = [d for d in (240, 120, 96, 80, 60, 48, 40) if abs(nominal - 240) < 5]
    if not divisors:
        divisors = [int(nominal / n) for n in range(1, 7)]
    print()
    if max(hzs) - min(hzs) > 3.0:
        # A cap only stabilises the refresh while the GPU can actually meet it.
        # Below the cap the panel free-runs again, so what matters is how OFTEN
        # you'd fall short and how far -- not merely whether p1 clears the cap.
        print("  FRAME CAP OPTIONS")
        print(f"    {'cap':>6}  {'below cap':>10}  {'residual swing':>15}   verdict")
        print("    " + "-" * 62)
        for d in sorted(divisors, reverse=True):
            if d > max(hzs):
                continue
            miss = [h for h in hzs if h < d - 0.5]
            pctm = 100 * len(miss) / len(hzs)
            swing = (d - min(miss)) if miss else 0.0
            if pctm < 2:
                v = "flat -- no flicker possible"
            elif swing < 8:
                v = "tiny dips, very likely fine"
            elif pctm < 25:
                v = "occasional dips"
            else:
                v = "still modulating -- too high"
            print(f"    {d:>6}  {pctm:9.1f}%  {swing:14.1f}Hz   {v}")
        print()
        print(f"    'below cap' = share of time the GPU could not sustain it.")
        print(f"    'residual swing' = how far refresh would still travel underneath it.")
        print(f"    Divisors of {nominal:.0f} are used so that if VRR ever drops out you")
        print(f"    still land on exact VSync cadence.")
    print()
    if sd < 1.0 and (max(hzs) - min(hzs)) < 3.0:
        print("  VERDICT: refresh is STABLE.")
        print("           VRR is not modulating the panel -> no VRR-induced flicker possible.")
        print("           Any flicker you still see is NOT from variable refresh.")
    else:
        print("  VERDICT: refresh is VARYING.")
        print(f"           The panel is being re-clocked across a {max(hzs)-min(hzs):.0f} Hz range.")
        print("           On OLED this is the classic cause of brightness flicker.")

    if changes:
        print(f"\n  {len(changes)} state change(s) detected during the run (see above).")
    return 0


def _diff_state(a, b):
    labels = ["colorspace", "max_bpc", "hdr_active", "eotf", "crtc_vrr"]
    for i, lab in enumerate(labels):
        if a[i] != b[i]:
            av, bv = a[i], b[i]
            if lab == "colorspace":
                av, bv = COLORSPACE_NAMES.get(av, av), COLORSPACE_NAMES.get(bv, bv)
            if lab == "eotf":
                av, bv = EOTF_NAMES.get(av, av), EOTF_NAMES.get(bv, bv)
            print(f"            {lab}: {av}  ->  {bv}")


def _sparkline(vals):
    blocks = "▁▂▃▄▅▆▇█"
    lo, hi = min(vals), max(vals)
    if hi - lo < 1e-9:
        return blocks[0] * min(len(vals), 66) + f"   (flat at {lo:.1f} Hz)"
    step = (hi - lo) / (len(blocks) - 1)
    n = min(len(vals), 66)
    stride = max(1, len(vals) // n)
    s = "".join(blocks[min(len(blocks) - 1, int((vals[i] - lo) / step))] for i in range(0, len(vals), stride))
    return f"{lo:.0f}Hz {s[:66]} {hi:.0f}Hz"


def cmd_verify(_args):
    """Compare what the config asks for against what the hardware is doing."""
    try:
        cfg = open(CONFIG).read()
    except OSError as e:
        print(f"  cannot read {CONFIG}: {e}")
        return 1

    blocks = re.findall(r"hl\.monitor\(\{(.*?)\}\)", cfg, re.S)
    wanted = []
    for b in blocks:
        d = {}
        for key in ("output", "cm", "mode"):
            m = re.search(rf'{key}\s*=\s*"([^"]*)"', b)
            if m:
                d[key] = m.group(1)
        for key in ("vrr", "bitdepth", "transform"):
            m = re.search(rf"{key}\s*=\s*(\d+)", b)
            if m:
                d[key] = int(m.group(1))
        if d.get("output"):
            wanted.append(d)

    conns, crtcs, _ = read_kms()
    mons, _ = hypr_state()
    vrr_any = any(v == 1 for v in crtcs.values())

    print("  config (on disk)  vs  hardware (kernel)\n")
    ok = True
    for w in wanted:
        out = w["output"]
        if out == "":
            continue
        mon = next((m for m in mons if m["name"] == out or out.startswith("desc:") and
                    m["description"].startswith(out[5:])), None)
        if not mon:
            print(f"  {out:44} not currently connected -- skipped")
            continue
        k = conns.get(mon["name"], {})
        print(f"  {mon['name']}  ({out})")

        if "bitdepth" in w:
            live = k.get("max_bpc")
            match = live == w["bitdepth"]
            ok &= match
            print(f"    bitdepth   want {w['bitdepth']:<12} kernel {live!s:<12} {'OK' if match else 'MISMATCH'}")

        if "cm" in w:
            live_cs = k.get("colorspace")
            hdr_on = bool(k.get("hdr"))
            expect = {"srgb": 0, "auto": None, "wide": 9, "hdr": 9}.get(w["cm"])
            if hdr_on:
                # While HDR is engaged the output is legitimately BT2020_RGB
                # regardless of the configured SDR preset -- not a mismatch.
                note = "OK (overridden by active HDR)"
                match = True
            elif expect is None:
                note, match = "", True
            else:
                match = live_cs == expect
                note = "OK" if match else "MISMATCH"
            ok &= match
            print(f"    cm         want {w['cm']:<12} kernel {COLORSPACE_NAMES.get(live_cs, live_cs)!s:<12} {note}")

        if "vrr" in w:
            want_vrr = w["vrr"]
            if want_vrr == 0:
                match = not vrr_any
                verdict = "OK" if match else "MISMATCH -- VRR IS ACTIVE but config says off"
            else:
                verdict = f"(mode {want_vrr}; VRR currently {'ACTIVE' if vrr_any else 'inactive'})"
                match = True
            ok &= match
            print(f"    vrr        want {want_vrr:<12} kernel {'ENABLED' if vrr_any else 'disabled':<12} {verdict}")
        print()

    print("  " + ("all checked values match" if ok else "!! DIVERGENCE -- live state does not match config"))
    if not ok:
        print("     Hyprland silently drops monitor changes that the atomic commit rejects.")
        print("     A full modeset (mode/bitdepth/cm change, or DPMS cycle) usually forces them through.")
    return 0 if ok else 2


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd")

    sub.add_parser("snapshot", help="one-shot full state")

    w = sub.add_parser("watch", help="sample refresh rate + state changes")
    w.add_argument("-s", "--secs", type=float, default=15.0)
    w.add_argument("-i", "--interval", type=float, default=0.25)
    w.add_argument("-m", "--monitor", default="DP-1")

    sub.add_parser("verify", help="live state vs on-disk config")

    args = ap.parse_args()
    if args.cmd == "watch":
        return cmd_watch(args)
    if args.cmd == "verify":
        return cmd_verify(args)
    return cmd_snapshot(args)


if __name__ == "__main__":
    sys.exit(main() or 0)
