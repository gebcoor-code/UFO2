# (0.58.1: made the first XHERO_sheet.png - UFO2.SPR is made from that sheet now: mkspr.py data/spr out)
# UFO2.SPR: the fighters' / aliens' coloured pictures (Alone Coder's NedoOS UFO-2, XHERO.bmp: its row pairs = colours,
# masks; frame k of xHERO (16 x 24, 8 x 16 per race) = colour row 2*(k//16), column k%16; xDIE (128..135) row 16).
# A frame: 24 lines x 8 bytes, a byte = 2 pixels (high nibble the left one): the LOGICAL colour (xspr.asm's xs_lm0
# puts each on a palette slot; 8 = none). 136 frames x 192 = 26112 bytes. With -p: preview.png of the humans too.
import os, sys
from PIL import Image
here = os.path.dirname(os.path.abspath(__file__))
im = Image.open(os.path.join(here, 'data/extra/src/XHERO.bmp')); px = im.load()
# NedoOS's palette index -> the logical colour (xspr.asm): 0 black, 1 white, 2 olive, 3 dark red, 4 red, 5 light grey,
# 6 green, 7 brown, 8 none, 9 grey-green, 10 maroon, 11 pink, 12 blue-grey, 13 teal, 14 orange, 15 dark grey
LOG = {0: 12, 1: 1, 2: 12, 3: 13, 4: 9, 5: 6, 6: 2, 7: 7, 8: 4, 9: 3, 10: 10, 11: 11, 12: 5, 13: 15, 14: 14, 15: 0, 16: 8}
def frame(k):
    r, c = (2 * (k // 16), k % 16) if k < 128 else (16, k - 128)
    return [[px[c * 16 + x, r * 24 + y] for x in range(16)] for y in range(24)]
F = [frame(k) for k in range(136)]
# the humans: NedoOS drew frames 0..2, 12, 13 as red divers; the rest are still the ZX pictures in white (1) and black.
# Those coloured by analogy: from a diver frame of the same pose where there is one (3 <- 2, 10, 11 <- 2 mirrored,
# 14, 15 <- 12, 13): its pixels where both have him, else its colour nearest (within 2); the rest lit as the divers
# are: an edge towards the bottom / right maroon, towards the top / left pink, inside dark red
TPL = {3: (2, 0), 10: (2, 1), 11: (2, 1), 14: (12, 0), 15: (13, 0)}   # (4..9: col_analogy)
COLD = (9, 10, 11, 2, 3, 12, 13)
def col_white(k):
    f = [row[:] for row in F[k]]
    t = None
    if k in TPL:
        s, mir = TPL[k]; t = [row[::-1] if mir else row[:] for row in F[s]]
    def lit(y, x):
        out = lambda yy, xx: not (0 <= yy < 24 and 0 <= xx < 16) or F[k][yy][xx] in (15, 16)
        if out(y + 1, x) or out(y, x + 1): return 10
        if out(y - 1, x) or out(y, x - 1): return 11
        return 9
    for y in range(24):
        for x in range(16):
            if t and F[k][y][x] != 16 and t[y][x] != 16:
                f[y][x] = t[y][x]; continue          # (the pose's own picture where both have him)
            if F[k][y][x] != 1: continue
            c = None
            if t:
                for d in range(3):
                    cand = [t[yy][xx] for yy in range(y - d, y + d + 1) for xx in range(x - d, x + d + 1)
                            if 0 <= yy < 24 and 0 <= xx < 16 and t[yy][xx] in COLD]
                    if cand: c = max(set(cand), key=cand.count); break
            f[y][x] = c if c is not None else lit(y, x)
    return f
# the poses with no diver frame (4..9: the back views): by analogy - each pixel takes the colour of the divers' pixel
# whose ZX surroundings (5 x 5: none / ink / paper, xhero.dat) and height in the figure are the most alike
XH = open(os.path.join(here, 'data/xhero.dat'), 'rb').read()
def zx(k):
    f = XH[k * 96:k * 96 + 96]; z = [[None] * 16 for _ in range(24)]
    for y in range(24):
        for b in range(2):
            m, v = f[y * 4 + b * 2], f[y * 4 + b * 2 + 1]
            for x in range(8):
                if m & (0x80 >> x): z[y][b * 8 + x] = 1 if v & (0x80 >> x) else 0
    return z
def nb(z, y, x):
    return tuple(z[y + dy][x + dx] if 0 <= y + dy < 24 and 0 <= x + dx < 16 else None
                 for dy in range(-2, 3) for dx in range(-2, 3))
DIV = [(k, zx(k)) for k in (0, 1, 2, 12, 13)]
SAMP = [(nb(z, y, x), y, F[k][y][x]) for k, z in DIV for y in range(24) for x in range(16) if z[y][x] is not None]
W5 = [3 if abs(i // 5 - 2) <= 1 and abs(i % 5 - 2) <= 1 else 1 for i in range(25)]
SAMPB = [t for t in SAMP if t[2] not in (2, 3, 12, 13, 15)]      # (the back views: no visor, no black)
def col_analogy(k):
    z = zx(k); f = [row[:] for row in F[k]]; samp = SAMPB if 4 <= k <= 9 else SAMP
    for y in range(24):
        for x in range(16):
            if z[y][x] is None: continue
            n = nb(z, y, x)
            best = min(samp, key=lambda s: sum(w for w, a, b in zip(W5, n, s[0]) if a != b) + abs(s[1] - y) * 0.5)
            f[y][x] = best[2]
    return f
for k in [3, 10, 11, 14, 15]:          # the same pose: the diver's pixels where both have him, the rest by analogy
    s_, mir = TPL[k]; t = [row[::-1] if mir else row[:] for row in F[s_]]; a = col_analogy(k)
    F[k] = [[t[y][x] if F[k][y][x] != 16 and t[y][x] != 16 else a[y][x] for x in range(16)] for y in range(24)]
for k in range(4, 10): F[k] = col_analogy(k)
out = bytearray()
for k in range(136):
    for y in range(24):
        for b in range(8):
            out.append(LOG[F[k][y][2 * b]] << 4 | LOG[F[k][y][2 * b + 1]])
assert len(out) == 26112
from mkico import pk
open(os.path.join(here, 'out/UFO2.SPR'), 'wb').write(pk(bytes(out)))     # (packed: port/mz.asm)
if '-p' in sys.argv:
    pal = im.getpalette()
    P = Image.new('RGB', (16 * 20, 2 * 30), (60, 60, 60))
    for k in range(16):
        for y in range(24):
            for x in range(16):
                for row, src in ((0, frame(k)), (1, F[k])):
                    c = src[y][x]
                    if c != 16: P.putpixel((k * 20 + 2 + x, row * 30 + 3 + y), tuple(pal[c * 3:c * 3 + 3]))
    P.resize((P.width * 4, P.height * 4), Image.NEAREST).save(sys.argv[sys.argv.index('-p') + 1])
