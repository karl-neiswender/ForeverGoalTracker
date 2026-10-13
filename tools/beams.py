"""Draws the light-shaft textures for banner art effects (white, alpha only,
tinted and faded in code):
  Media/beam.tga   a vertical beam of light, narrow at the top and broad at
                   the bottom, soft at every edge (moonbeam, angelic light)
  Media/shaft.tga  one sunray: it starts at the texture's center and runs to
                   the right edge, widening and fading as it goes; code turns
                   it to point anywhere from a light source
  Media/shaft-wide.tga  the same, much thicker and softer: the long, slow
                   "visible sunlight" layer behind the thin rays
  Media/gleam.tga  a small four-point glint with a soft core (light catching
                   a coin)
  Media/streak.tga a crisp, thin sunray streak from the center to the right
                   edge, barely widening, fading along its length
  Media/light-mask.tga  the photo's own fades as a mask for the lights:
                   clear on the left, darkened at the top, faded at the
                   bottom, so lights sit under the art's darkening

Run from the repo root:  python tools/beams.py
"""
import math, os, struct

def smooth(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)

def save(name, w, h, alpha):
    pixels = bytearray()
    for y in range(h):
        for x in range(w):
            pixels += bytes((255, 255, 255, round(max(0.0, min(1.0, alpha(x, y))) * 255)))
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28)
    out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Media", name + ".tga")
    with open(out, "wb") as f:
        f.write(header + bytes(pixels))
    print("wrote", out)

def beam(x, y, W=128, H=256):
    t = (y + 0.5) / H                      # 0 at the top, 1 at the bottom
    dx = abs((x + 0.5) / W - 0.5)          # 0 in the middle, 0.5 at the sides
    half = 0.20 + 0.30 * t                 # wide top, broader bottom (Karl: wider tops)
    across = math.exp(-2.2 * (dx / half) ** 2)
    streaks = 0.88 + 0.12 * math.sin(dx / half * 9.0)   # faint lines inside
    along = smooth(0.0, 0.18, t) * (1 - smooth(0.62, 1.0, t)) * (1.0 - 0.25 * t)
    return across * streaks * along

def shaft(x, y, S=256):
    t = ((x + 0.5) - S / 2) / (S / 2)     # 0 at the source (center), 1 at the right edge
    if t <= 0:
        return 0.0
    lat = abs((y + 0.5) - S / 2) / (S / 2)
    width = 0.04 + 0.20 * t                # widening away from the source
    across = math.exp(-2.0 * (lat / width) ** 2)
    along = smooth(0.0, 0.10, t) * (1 - t) ** 0.8
    return across * along

def shaft_wide(x, y, S=256):
    t = ((x + 0.5) - S / 2) / (S / 2)
    if t <= 0:
        return 0.0
    lat = abs((y + 0.5) - S / 2) / (S / 2)
    width = 0.10 + 0.32 * t
    across = math.exp(-1.4 * (lat / width) ** 2)
    along = smooth(0.0, 0.18, t) * (1 - t) ** 1.0
    return across * along

def gleam(x, y, S=64):
    dx, dy = (x + 0.5) / S - 0.5, (y + 0.5) / S - 0.5
    r = math.hypot(dx, dy)
    core = math.exp(-(r / 0.07) ** 2)
    arms = (math.exp(-(dy / 0.018) ** 2) + math.exp(-(dx / 0.018) ** 2)) * max(0.0, 1 - r / 0.5) ** 2
    return min(1.0, core + 0.8 * arms)

def streak(x, y, S=256):
    t = ((x + 0.5) - S / 2) / (S / 2)
    if t <= 0:
        return 0.0
    lat = abs((y + 0.5) - S / 2) / (S / 2)
    width = 0.012 + 0.03 * t
    across = math.exp(-2.5 * (lat / width) ** 2)
    along = smooth(0.0, 0.06, t) * (1 - t) ** 0.55
    return across * along

def light_mask(x, y, S=256):
    u, v = (x + 0.5) / S, (y + 0.5) / S
    left = u                                   # the art's own left-to-right fade
    top = 1 - 0.65 * (1 - smooth(0.0, 0.28, v))  # its darkened top
    bottom = 1 - smooth(0.62, 1.0, v)          # its faded bottom
    return left * top * bottom

save("beam", 128, 256, beam)
save("streak", 256, 256, streak)
save("light-mask", 256, 256, light_mask)
save("shaft", 256, 256, shaft)
save("shaft-wide", 256, 256, shaft_wide)
save("gleam", 64, 64, gleam)
