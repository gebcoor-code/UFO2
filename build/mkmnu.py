# mkmnu.py - UFO2.MNU (0.61.1): the start menu - its code (port/ufo2m.bin: port/mnu.asm, assembled with zxl.asm), then
# (0.64.0) its music (data/mufo.bin: the original's M_UFO with its player, #EA00..#FFFF - 44 records; mkint.py), then
# its 4 EGA screens (320x200, the port's 16 colours): 0 - the title (data/xtitle.png, "LOADING." - lines 2..14,
# x 0..167 - black), 1 - the menu (data/xmenu.png), 2 - the author (data/xauthor.png), 3 - Copper Feet
# (data/xcopper.png). Each: its length (2 bytes), its 4 parts RLE packed as UFO2.IMG's (mkimg.py; page 1 +#0000,
# +#2000, page 5 +#0000, +#2000), one after another; where each starts - into the code (mnu.asm mm_tab, offset 6).
# port/mnu.asm reads them into pages MNPG..MNPG+3 (64K).
#   python3 mkmnu.py [OUT]
import os, sys
from PIL import Image
here = os.path.dirname(os.path.abspath(__file__))
code = bytearray(open(os.path.join(os.environ.get('UFO_BIN', os.path.join(here, '../port')), 'ufo2m.bin'), 'rb').read())
assert code[:2] == b'MN' and code[3] == 0xC3
P = [(0,0,0),(0,0,192),(192,0,0),(192,0,192),(0,192,0),(0,192,192),(192,192,0),(192,192,192),
     (0,0,0),(0,0,255),(255,0,0),(255,0,255),(0,255,0),(0,255,255),(255,255,0),(255,255,255)]
idx = {}
for i, c in enumerate(P): idx.setdefault(c, i)
def rle(d):
    o = bytearray(); i = 0; lit = bytearray()
    def flush():
        while lit:
            k = lit[:128]; o.append(len(k) - 1); o.extend(k); del lit[:128]
    while i < len(d):
        j = i
        while j < len(d) and d[j] == d[i] and j - i < 129: j += 1
        if j - i >= 3: flush(); o.append(j - i + 0x7E); o.append(d[i]); i = j
        else: lit.append(d[i]); i += 1
    flush(); return bytes(o)
def screen(name, black=None):
    im = Image.open(os.path.join(here, 'data', name)).convert('RGB'); assert im.size == (320, 200), name
    px = im.load()
    def col(x, y):
        if black and black[0] <= x <= black[1] and black[2] <= y <= black[3]: return 0
        c = px[x, y]
        if c not in idx: raise SystemExit('data/%s: colour %r at %d,%d not in the palette' % (name, c, x, y))
        return idx[c]
    parts = [bytearray(8000) for _ in range(4)]      # pairs 0 mod 4, 2, 1, 3 -> page 1 +0, +#2000, page 5 +0, +#2000
    for y in range(200):
        for p in range(160):
            l, r = col(2 * p, y), col(2 * p + 1, y)
            parts[{0: 0, 2: 1, 1: 2, 3: 3}[p & 3]][y * 40 + p // 4] = (l & 7) | (l & 8) << 3 | (r & 7) << 3 | (r & 8) << 4
    e = b''.join(rle(bytes(k)) for k in parts)
    assert len(e) + 2 <= 0x7000, '%s: %d bytes packed, 28K at most' % (name, len(e))
    return len(e).to_bytes(2, 'little') + e
data = bytearray(); tab = []
for name, bl in (('xtitle.png', (0, 167, 2, 14)), ('xmenu.png', None), ('xauthor.png', None), ('xcopper.png', None)):
    data += bytes(-len(data) % 256)             # (0.65.1: each from a 256 boundary - mm_tab in 256s, 5 pages)
    tab.append(len(data) >> 8); data += screen(name, bl)
assert len(data) <= 5 * 0x4000, 'UFO2.MNU: the screens %d bytes, 80K at most' % len(data)
for k, v in enumerate(tab): code[6 + 2 * k:8 + 2 * k] = v.to_bytes(2, 'little')
mu = open(os.path.join(here, 'data/mufo.bin'), 'rb').read(); assert len(mu) == 0x1600 and mu[0x4F:0x54] == b'M_UFO'
out = code + bytes(-len(code) % 128) + mu + data
out += bytes(-len(out) % 128)
open(sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, 'out/UFO2.MNU'), 'wb').write(out)
print('UFO2.MNU: code %d, screens at %s (256s), %d bytes' % (len(code), ' '.join(str(a) for a in tab), len(out)))
