# xmenu_gen.py (0.65.0) - how data/xmenu.png was made (once: since then a picture to edit): python3 xmenu_gen.py XI1.SCR out.png
# XI1.SCR -> xmenu.png (320x200, the port's 16 colours): the start menu's screen in EGA, recoloured
import sys, math
from PIL import Image
P = [(0,0,0),(0,0,192),(192,0,0),(192,0,192),(0,192,0),(0,192,192),(192,192,0),(192,192,192),
     (0,0,0),(0,0,255),(255,0,0),(255,0,255),(0,255,0),(0,255,255),(255,255,0),(255,255,255)]
d = open(sys.argv[1], 'rb').read()
W, H = 256, 192
col = [[0] * W for _ in range(H)]
for y in range(H):
    for xb in range(32):
        b = d[((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | xb]; at = d[6144 + (y >> 3) * 32 + xb]
        for k in range(8): col[y][xb * 8 + k] = (at & 7) if b & (128 >> k) else (at >> 3 & 7)
TEXT_Y = 136
import copy
orig = copy.deepcopy(col)
for y in range(TEXT_Y, H):
    for x in range(120, W):
        if col[y][x] == 7: col[y][x] = 0
B4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
def dith(ramp, v, x, y):            # v 0..1 -> a ramp's colour, ordered dither between neighbours
    v = max(0.0, min(0.999, v)) * (len(ramp) - 1); i = int(v); f = v - i
    return ramp[i + 1] if i + 1 < len(ramp) and f * 16 > B4[y & 3][x & 3] + 0.5 else ramp[i]
# distance of black pixels to the nearest coloured one (outlines stay black)
INF = 99
dist = [[0 if col[y][x] else INF for x in range(W)] for y in range(H)]
for _ in range(3):
    for y in range(H):
        for x in range(W):
            if dist[y][x]:
                m = min(dist[yy][xx] for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)) if 0 <= yy < H and 0 <= xx < W)
                dist[y][x] = min(dist[y][x], m + 1)
# thickness of coloured areas (inside: darker - light from the top right)
thick = [[0] * W for _ in range(H)]
for y in range(H):
    for x in range(W):
        if col[y][x]:
            n = 0
            for r in range(1, 5):
                if all(0 <= y + dy < H and 0 <= x + dx < W and col[y + dy][x + dx] for dy, dx in ((r, 0), (-r, 0), (0, r), (0, -r))): n = r
                else: break
            thick[y][x] = n
out = Image.new('RGB', (320, 200)); px = out.load()
OX, OY = 32, 4
def sea(X, Y):                      # the background: the deep sea - black above, blue below (dithered)
    v = Y / 200.0
    return dith([0, 1, 9], v * 0.75, X, Y)
for Y in range(200):
    for X in range(320): px[X, Y] = P[sea(X, Y)]
TEXT_Y = 136
for y in range(H):
    for x in range(W):
        c = col[y][x]; X, Y = x + OX, y + OY
        light = (x - y) / 256.0
        t = thick[y][x]
        if c == 0:
            px[X, Y] = P[sea(X, Y) if dist[y][x] > 1 else 0]; continue
        if c == 7:
            if y < 100 and x > 110:                 # clouds -> the foam
                px[X, Y] = P[dith([5, 13, 15], 0.6 + light * 0.4 - t * 0.07, X, Y)]
            else: px[X, Y] = P[15 if t < 2 else 13]
            continue
        if c == 5:                                  # glass
            px[X, Y] = P[dith([9, 13, 15], 0.55 + light * 0.45 - t * 0.08, X, Y)]; continue
        side = x < 72 or x > 192
        ramp = [1, 7, 15] if side else [4, 12, 15]
        px[X, Y] = P[dith(ramp, 0.5 + light * 0.45 - t * 0.08, X, Y)]
# bubbles in the margins
import random
r = random.Random(7)
for _ in range(14):
    cx = r.choice([r.randrange(4, 28), r.randrange(292, 316)]); cy = r.randrange(20, 196); rad = r.choice([1, 2, 2, 3, 4])
    for yy in range(cy - rad - 1, cy + rad + 2):
        for xx in range(cx - rad - 1, cx + rad + 2):
            if not (0 <= xx < 320 and 0 <= yy < 200): continue
            dd = math.hypot(xx - cx, yy - cy)
            if abs(dd - rad) < 0.6: px[xx, yy] = P[13 if yy < cy else 5]
            if rad > 1 and xx == cx + rad // 2 and yy == cy - rad // 2: px[xx, yy] = P[15]
# ---- the menu's lines anew (0.65.0): 4 of them, 15 apart, right-aligned at x 287; the glyphs from XI1's lines
# (their columns), the missing ones (4, E, G, -) drawn in their style; rows from the capitals' top (16 a glyph)
def cut(y0, a, b): return [[1 if orig[y][x] == 7 else 0 for x in range(a, b + 1)] for y in range(y0, y0 + 16)]
SRC = [(138, [('1', 169, 174), ('.', 178, 179), ('В', 187, 195), ('в', 197, 204), ('е', 206, 211), ('д', 213, 220),
              ('н', 229, 236), ('и', 238, 246)]),
       (158, [('2', 188, 195), ('И', 207, 217), ('Г', 221, 229), ('Р', 232, 240), ('А', 242, 252)]),
       (175, [('3', 144, 151), ('н', 176, 183), ('с', 185, 190), ('т', 192, 199), ('р', 200, 207), ('у', 209, 216),
              ('к', 218, 226), ('ц', 228, 235), ('я', 246, 252)])]
G = {}
for y0, gl in SRC:
    for n, a, b in gl: G.setdefault(n, cut(y0, a, b))
G['е'] = cut(138, 206, 211)
def draw(rows): return [[1 if c == '#' else 0 for c in r] for r in rows] + [[0] * len(rows[0])] * (16 - len(rows))
G['4'] = draw(['.....##.', '....###.', '...#.##.', '..#..##.', '.#...##.', '#....##.', '########', '.....##.',
               '.....##.', '.....##.', '.....##.', '....####'])
G['E'] = draw(['########', '.##...##', '.##....#', '.##.....', '.##..#..', '.######.', '.##..#..', '.##.....',
               '.##.....', '.##....#', '.##...##', '########'])
G['G'] = draw(['...####.#', '..##...##', '.##.....#', '##.......', '##.......', '##.......', '##...####', '##....##.',
               '##....##.', '.##...##.', '..##..##.', '...####..'])
G['A'] = G['А']
G['П'] = draw(['###########', '.##.....##.', '.##.....##.', '.##.....##.', '.##.....##.', '.##.....##.', '.##.....##.',
               '.##.....##.', '.##.....##.', '.##.....##.', '.##.....##.', '####...####'])
E4 = ['.' * 10] * 4
G['о'] = draw(['.......'] * 4 + ['..###..', '.##..##', '##...##', '##...##', '##...##', '##...##', '##..##.', '..###..'])
G['ю'] = draw(['..........'] * 4 + ['###..###..', '.##.##.##.', '.##.##.##.', '.#####.##.', '.##.##.##.', '.##.##.##.',
               '.##.##.##.', '###..###..'])
G['-'] = draw(['.....', '.....', '.....', '.....', '.....', '.....', '.....', '#####', '#####'])
LINES = ['1. Введение', '2. ИГРА', '3. Инструкция', '4. Про EGA-версию']
mask = {}
for k, ln in enumerate(LINES):
    top = 136 + 15 * k
    width = sum(4 if n == ' ' else len(G[n][0]) + 1 for n in ln) - 1
    x = 287 - width + 1; digit = True
    for n in ln:
        if n == ' ': x += 4; digit = False; continue
        g = G[n]
        for yy, r in enumerate(g):
            for xx, v in enumerate(r):
                if v: mask[(x + xx, top + yy)] = (digit, yy)
        x += len(g[0]) + 1
for (X, Y) in list(mask):
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            q = (X + dx, Y + dy)
            if q not in mask and 0 <= q[0] < 320 and 0 <= q[1] < 200: px[q] = P[0]
for (X, Y), (dig, r) in mask.items():
    px[X, Y] = P[(10 if r < 7 else 2) if dig else (14 if r < 7 else 6)]

out.save(sys.argv[2])
