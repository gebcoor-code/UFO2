# the title picture (data/xtitle.png, 320x200, the port's 16 colours) -> out/UFO2.IMG: the EGA screen's memory
# as it is: page 1 +#0000, page 1 +#2000, page 5 +#0000, page 5 +#2000 (8000 bytes each, 40 a line)
from PIL import Image
import os
D = os.path.dirname(os.path.abspath(__file__))
P = [(0,0,0),(0,0,192),(192,0,0),(192,0,192),(0,192,0),(0,192,192),(192,192,0),(192,192,192),
     (0,0,0),(0,0,255),(255,0,0),(255,0,255),(0,255,0),(0,255,255),(255,255,0),(255,255,255)]
im = Image.open(os.path.join(D, 'data/xtitle.png')).convert('RGB'); assert im.size == (320, 200)
px = im.load(); idx = {}
for i, c in enumerate(P): idx.setdefault(c, i)
def col(x, y):
    c = px[x, y]
    if c not in idx: raise SystemExit('colour %r at %d,%d not in the palette' % (c, x, y))
    return idx[c]
parts = [bytearray(8000) for _ in range(4)]          # pairs 0 mod 4, 2, 1, 3 -> parts 0, 1, 2, 3
for y in range(200):
    for p in range(160):
        l, r = col(2 * p, y), col(2 * p + 1, y)
        b = (l & 7) | (l & 8) << 3 | (r & 7) << 3 | (r & 8) << 4
        q = p & 3; k = {0: 0, 2: 1, 1: 2, 3: 3}[q]
        parts[k][y * 40 + p // 4] = b
# RLE per part (port/title.asm t_part): c < #80: c+1 bytes as they are; c >= #80: the next byte c-#7E times (2..129)
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
def unrle(c):
    o = bytearray(); i = 0
    while i < len(c):
        b = c[i]; i += 1
        if b < 0x80: o += c[i:i + b + 1]; i += b + 1
        else: o += bytes([c[i]]) * (b - 0x7E); i += 1
    return bytes(o)
out = b''
for k in parts:
    c = rle(bytes(k)); assert unrle(c) == bytes(k); out += c
assert len(out) <= 32000
from mkico import pk
assert len(out) <= 20480                                # (port/title.asm: read below #9000)
open(os.path.join(D, 'out/UFO2.IMG'), 'wb').write(pk(out)); print('UFO2.IMG', len(out), 'packed', len(pk(out)))
