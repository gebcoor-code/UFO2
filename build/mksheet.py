# out/allsprites.png: every sprite coloured - the fighters and aliens (UFO2.SPR, xspr.asm's colours xs_lm0), the one
# not in focus (xs_lf: blue; the one in focus as drawn, red), the location tiles (mktil.py's out/tilesheet.png: run mktil.py -s first); 2 x. The tiles' part is
# what mktil.py -e reads back (edited by hand) - it starts at y 358 (1 x).
import os, re
import pngio
here = os.path.dirname(os.path.abspath(__file__))
PAL = [(0, 0, 0), (0, 0, 192), (192, 0, 0), (96, 0, 0), (96, 192, 96), (255, 96, 96), (192, 192, 0), (192, 192, 192),
       (192, 96, 0), (0, 0, 255), (255, 0, 0), (96, 192, 0), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
asm = open(os.path.join(here, '../port/xspr.asm')).read()
def table(name): return [int(v) for v in re.search(r'^' + name + r'\s+db\s+([0-9, ]+)', asm, re.M).group(1).split(',')]
LM0, LF = table('xs_lm0'), table('xs_lf')
from mkico import unpk
spr = unpk(open(os.path.join(here, 'out/UFO2.SPR'), 'rb').read())
BG = (28, 28, 28); W = 16 * 18 + 40
hero = pngio.new(W, 30 + (136 // 16 + 1) * 28 + 30 + 28, BG); hp = hero.load()
def fr(k, lm, im, ox, oy):
    for y in range(24):
        for x in range(16):
            b = spr[k * 192 + y * 8 + x // 2]; v = (b >> 4) if x % 2 == 0 else b & 15
            if v != 8: im.rows[oy + y][ox + x] = PAL[lm[v]]
for k in range(136): fr(k, LF if k < 16 or k == 128 else LM0, hero, 40 + (k % 16) * 18, 24 + (k // 16) * 28)   # (ours: blue)
y0 = 24 + (136 // 16 + 1) * 28 + 6
for k in range(16): fr(k, LM0, hero, 40 + k * 18, y0 + 16)               # (the one in focus: red)
tiles = pngio.open_png(os.path.join(here, 'out/tilesheet.png'))
assert hero.height + 18 == 358
o = pngio.new(W, hero.height + tiles.height + 20, BG); o.paste(hero, (0, 0)); o.paste(tiles, (0, hero.height + 18))
o = o.scaled(2)
o.text(6, 6, 'FIGHTERS, ALIENS (UFO2.SPR)', (255, 255, 255), 2)
o.text(6, 2 * y0, 'IN FOCUS (RED; THE OTHERS BLUE)', (255, 255, 255), 2)
o.text(6, 2 * hero.height + 8, 'TILES (UFO2.TIL): XM0, XM11 BY ALONE CODER, THE REST BY ANALOGY', (255, 255, 255), 1)
o.save(os.path.join(here, 'out/allsprites.png')); print('allsprites.png', o.size)
