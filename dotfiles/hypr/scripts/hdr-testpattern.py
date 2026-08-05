#!/usr/bin/env python3
"""
Generate an HDR (PQ / BT.2020) reference test pattern.

The point: give a known-correct reference, so "does HDR look right?" becomes a
question with a checkable answer instead of a vibe.

Three independent tests on one screen:

  1. LUMINANCE ladder -- patches at exact nit values via the ST2084 (PQ) curve.
     A working HDR chain shows each step brighter than the last, up to the
     panel's peak, then stops. This panel peaks ~604 nits, so 600 and 1000
     should look near-identical (correct clipping) while 1 -> 400 is stepped.

  2. GAMUT pairs -- the SAME colour expressed two ways: as a pure BT.2020
     primary, and as a Rec.709 primary converted into the BT.2020 container.
     If the display honours BT.2020, the top half is visibly MORE saturated.
     Identical halves == gamut not being expanded == the desaturation bug.

  3. SHADOW detail -- sub-nit patches. OLED should resolve all of them.

Full 16-bit precision: patches are built in numpy, text is composited from a
PIL mask, and the result is piped to ffmpeg as raw rgb48le. PIL's RGB mode is
8-bit and silently clamps, so it is used only for glyph shapes.
"""

import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

W, H = 2560, 1440
FONT = "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"

# --- SMPTE ST 2084 (PQ) inverse EOTF: nits -> code value 0..1 ---------------
M1, M2 = 2610 / 16384, 2523 / 4096 * 128
C1, C2, C3 = 3424 / 4096, 2413 / 4096 * 32, 2392 / 4096 * 32


def pq(nits: float) -> float:
    y = max(0.0, nits / 10000.0) ** M1
    return ((C1 + C2 * y) / (1 + C3 * y)) ** M2


def code(nits: float) -> int:
    return int(round(pq(nits) * 65535))


# Rec.709 -> BT.2020 linear RGB. Expresses a 709 primary inside the wider
# container so it can be compared against a native BT.2020 primary.
R709_TO_2020 = np.array([
    [0.62740, 0.32930, 0.04330],
    [0.06910, 0.91950, 0.01140],
    [0.01640, 0.08800, 0.89560],
])


def patch(linear_rgb, nits):
    return np.array([code(c * nits) for c in linear_rgb], dtype=np.uint16)


def main(out_png_free_path):
    buf = np.zeros((H, W, 3), dtype=np.uint16)
    mask = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(mask)
    big = ImageFont.truetype(FONT, 42)
    mid = ImageFont.truetype(FONT, 28)
    small = ImageFont.truetype(FONT, 23)

    def rect(x0, y0, x1, y1, rgb):
        buf[max(0, y0):min(H, y1), max(0, x0):min(W, x1)] = rgb

    d.text((60, 34), "HDR REFERENCE PATTERN   --   PQ (ST2084) / BT.2020", font=big, fill=255)
    d.text((60, 88), "LG UltraGear+ OLED   EDID peak 604 nits, 277 nits full-screen average",
           font=small, fill=255)

    # ---------------- 1. luminance ladder ----------------
    d.text((60, 150), "1. LUMINANCE  --  each step should be clearly brighter than the one before",
           font=mid, fill=255)
    ladder = [1, 10, 50, 100, 203, 400, 600, 1000]
    x0, y0, pw, ph, gap = 60, 196, 290, 210, 12
    for i, nits in enumerate(ladder):
        x = x0 + i * (pw + gap)
        v = code(nits)
        rect(x, y0, x + pw, y0 + ph, (v, v, v))
        d.text((x + 8, y0 + ph + 8), f"{nits} nits", font=mid, fill=255)
    d.text((60, y0 + ph + 46),
           "EXPECT: 1->400 obviously stepped.   600 and 1000 nearly IDENTICAL (panel clips ~604).",
           font=small, fill=255)
    d.text((60, y0 + ph + 74),
           "IF ALL PATCHES LOOK EQUALLY BRIGHT  ->  PQ curve not applied.  HDR is broken.",
           font=small, fill=255)

    # ---------------- 2. gamut pairs ----------------
    gy = 570
    d.text((60, gy), "2. GAMUT  --  TOP half = pure BT.2020 primary,   BOTTOM half = Rec.709 primary",
           font=mid, fill=255)
    prim = [("RED", (1, 0, 0)), ("GREEN", (0, 1, 0)), ("BLUE", (0, 0, 1)),
            ("CYAN", (0, 1, 1)), ("MAGENTA", (1, 0, 1)), ("YELLOW", (1, 1, 0))]
    NITS = 203  # HDR reference white, ITU-R BT.2408
    pwd, phd, g2, y1 = 390, 300, 14, gy + 48
    for i, (name, rgb) in enumerate(prim):
        x = 60 + i * (pwd + g2)
        rect(x, y1, x + pwd, y1 + phd // 2, patch(rgb, NITS))
        rect(x, y1 + phd // 2, x + pwd, y1 + phd, patch(R709_TO_2020 @ np.array(rgb, float), NITS))
        rect(x, y1 + phd // 2 - 2, x + pwd, y1 + phd // 2 + 2, (0, 0, 0))
        d.text((x + 8, y1 + phd + 8), name, font=mid, fill=255)
    d.text((60, y1 + phd + 46),
           "EXPECT: the TOP half of every pair is visibly MORE saturated than the bottom.",
           font=small, fill=255)
    d.text((60, y1 + phd + 74),
           "IF TOP AND BOTTOM MATCH  ->  BT.2020 not being expanded.  This is the desaturation bug.",
           font=small, fill=255)

    # ---------------- 3. shadow detail ----------------
    by = 1105
    d.text((60, by), "3. SHADOW  --  every square should be distinguishable from pure black",
           font=mid, fill=255)
    shades = [0.0, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0, 2.0]
    sw, sh = 290, 150
    for i, nits in enumerate(shades):
        x = 60 + i * (sw + 12)
        v = code(nits)
        rect(x, by + 42, x + sw, by + 42 + sh, (v, v, v))
        o = code(40)
        rect(x, by + 42, x + sw, by + 44, (o, o, o))
        rect(x, by + 40 + sh, x + sw, by + 42 + sh, (o, o, o))
        rect(x, by + 42, x + 2, by + 42 + sh, (o, o, o))
        rect(x + sw - 2, by + 42, x + sw, by + 42 + sh, (o, o, o))
        d.text((x + 6, by + 42 + sh + 6), f"{nits} nit", font=small, fill=255)

    # composite text at ~120 nits so it is legible but never glaring
    m = np.array(mask, dtype=np.float32) / 255.0
    lv = code(120)
    for c in range(3):
        buf[:, :, c] = np.maximum(buf[:, :, c], (m * lv).astype(np.uint16))

    raw = buf.astype("<u2").tobytes()
    print(f"  built {W}x{H} rgb48le, {len(raw)/1e6:.1f} MB raw")
    print(f"  sanity  PQ(100)={pq(100):.4f}  PQ(203)={pq(203):.4f}  PQ(604)={pq(604):.4f}")
    return raw


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "/tmp/opencode/disp/hdr_pattern.mkv"
    raw = main(out)
    md = "G(8500,39850)B(6550,2300)R(35400,14600)WP(15635,16450)L(6040000,1)"
    cmd = [
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-f", "rawvideo", "-pix_fmt", "rgb48le", "-s", f"{W}x{H}", "-r", "10", "-i", "-",
        "-vf", "scale=out_color_matrix=bt2020nc,format=yuv420p10le,setparams=color_primaries=bt2020:color_trc=smpte2084:colorspace=bt2020nc",
        "-c:v", "libx265", "-preset", "ultrafast", "-crf", "12",
        "-color_primaries", "bt2020", "-color_trc", "smpte2084", "-colorspace", "bt2020nc",
        "-x265-params",
        f"colorprim=bt2020:transfer=smpte2084:colormatrix=bt2020nc:master-display={md}:max-cll=604,277:hdr10=1:repeat-headers=1",
        "-t", "3600", "-loop", "1",
        out,
    ]
    # -loop on rawvideo input isn't valid; feed a handful of identical frames instead
    cmd.remove("-loop"); cmd.remove("1")
    p = subprocess.run(cmd, input=raw * 20, capture_output=True)
    if p.returncode:
        print(p.stderr.decode()[-1500:])
        sys.exit(1)
    print(f"  wrote {out}")
