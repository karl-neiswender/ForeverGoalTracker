"""Draws the rounded-corner pieces the progress bars are built from (Bars.lua, B.Round).

Media/round-cap-<h>-l.tga and -r.tga: a mask for one end of a bar whose inside is h units tall,
white, its alpha cutting that end's two corners at the bar's inner radius. The game allows at
most three masks on a texture, so each end takes one mask covering both its corners; the corners
depend on the height, so there is one pair per bar height in use (BAR_HEIGHTS, which must match
Bars.lua's CAP_HEIGHTS). The image is 64 x 128 and drawn pre-stretched: shown at radius x h
units, its quarter ellipses become circles. Bars.lua sets the masks to clamp to white.

Media/round-ring-<r>.tga, r = 2..6: the top-left quarter of a 1-unit outline with radius r,
drawn so that the image, shown r units square, has a ring 1 unit thick. Bars.lua flips it with
texcoords for the other corners.

Run from the repo root: python tools/round-corners.py (needs Pillow).
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
MEDIA = os.path.join(HERE, "..", "Media")
SS = 8  # supersampling per side
BAR_HEIGHTS = (4, 5, 6, 9, 10, 24)  # every NewBar height in use, outline included


def radius(height):
    """Bars.lua's B.Radius: 4, or half a thin bar; square under 4 tall."""
    return 0 if height < 4 else min(4, height // 2)


def coverage(w, h, inside):
    """A w x h alpha image: the share of each pixel's samples where inside(u, v), u and v 0..1."""
    img = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    px = img.load()
    for y in range(h):
        for x in range(w):
            hits = 0
            for sy in range(SS):
                for sx in range(SS):
                    if inside((x + (sx + 0.5) / SS) / w, (y + (sy + 0.5) / SS) / h):
                        hits += 1
            px[x, y] = (255, 255, 255, round(255 * hits / (SS * SS)))
    return img


def main():
    for height in BAR_HEIGHTS:
        h, ri = height - 2, radius(height) - 1  # the inside: 1 in from the outline
        if ri < 1:
            continue

        def inside(u, v, h=h, ri=ri):
            x, y = u * ri, v * h  # in units; the left end, its corners' centres at x = ri
            if y < ri:
                return (x - ri) ** 2 + (y - ri) ** 2 <= ri * ri
            if y > h - ri:
                return (x - ri) ** 2 + (y - (h - ri)) ** 2 <= ri * ri
            return True

        left = coverage(64, 128, inside)
        left.save(os.path.join(MEDIA, "round-cap-%d-l.tga" % h), orientation=1)
        left.transpose(Image.FLIP_LEFT_RIGHT).save(os.path.join(MEDIA, "round-cap-%d-r.tga" % h), orientation=1)
    for r in range(2, 7):
        inner = (r - 1) / r

        def ring(u, v, inner=inner):
            d = ((u - 1) ** 2 + (v - 1) ** 2) ** 0.5  # centre: the image's bottom-right corner
            return inner <= d <= 1

        coverage(64, 64, ring).save(os.path.join(MEDIA, "round-ring-%d.tga" % r), orientation=1)
    print("wrote round-cap-<h>-l/r for bar heights %s and round-ring-2..6 to Media" % (BAR_HEIGHTS,))


if __name__ == "__main__":
    main()
