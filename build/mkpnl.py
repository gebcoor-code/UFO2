# mkpnl.py - UFO2.PNL: the fight's panels with PANEL.png's bottom panel, for UFO-2 EGA (ATM Turbo 2+, CP/M).
#   python3 mkpnl.py [FOLDER [OUT]]   (no arguments: PANEL.png beside this script, UFO2.PNL there too)
# In: FOLDER/PANEL.png (as mkico.py checks it: 240 x 52 - the bottom panel 197 x 40 as shown, then its 12 buttons
# active, 20 x 12 each; the fight's 11 colours), pnl_base.bin and pnl_lay.txt beside this script (the panels in the
# game's look and their layout: the game's build makes them - tools/mkpanel2.py; they belong to one version of
# UFO2.COM). Out: UFO2.PNL - put it beside UFO2.COM: the game takes its panels from it (UFO2.COM checks its header:
# another version's file is not used - the panels from UFO2.DAT then). What it takes from PANEL.png: the panel's
# background and frame, the buttons (both looks), the guns' cells' frames; the time bar's fills, the digits and the
# items in the cells are drawn over them in the game. Plain Python 3, nothing else needed.
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
import mkico
src = sys.argv[1] if len(sys.argv) > 1 else here
dst = sys.argv[2] if len(sys.argv) > 2 else src
lay = {}; buttons = []
for l in open(os.path.join(here, 'pnl_lay.txt')):
    t = l.split()
    if not t or t[0].startswith('#'): continue
    if t[0] == 'button': buttons.append(tuple(map(int, t[1:])))
    else: lay[t[0]] = list(map(int, t[1:]))
base = bytearray(open(os.path.join(here, 'pnl_base.bin'), 'rb').read())
assert len(base) == lay['records'][0] * 128, 'pnl_base.bin: not this layout'
pan = mkico.read(os.path.join(src, 'PANEL.png'), 240, 52)
BX, BY, BW, BH = lay['bot']
def lp(b): return (b & 7) | (b >> 3 & 8)                # a pair byte's left / right pixel
def rp(b): return (b >> 3 & 7) | (b >> 4 & 8)
def pair(l, r): return (l & 7) | (l & 8) << 3 | (r & 7) << 3 | (r & 8) << 4
# the static picture: OPG0 (parts 0, 2), OPG1 (1, 3); pair p of line y: part p & 3, byte y * 40 + p / 4 (+ #2000: 2, 3)
def boff(x, y):
    p = x >> 1; part = p & 3
    return (part & 1) * 16384 + (0x2000 if part >= 2 else 0) + y * 40 + (p >> 2)
img = [[0] * 320 for _ in range(200)]
for y in range(200):
    for x in range(0, 320, 2):
        b = base[boff(x, y)]; img[y][x] = lp(b); img[y][x + 1] = rp(b)
for y in range(BH):
    for x in range(BW): img[BY + y][BX + x] = pan[y][x]
for y in range(BY, BY + BH):
    for x in range(BX & ~1, (BX + BW + 1) & ~1, 2): base[boff(x, y)] = pair(img[y][x], img[y][x + 1])
A0 = 32768                                              # (the atlas after the two pages)
# the buttons: per button two blocks (normal, active) of 12 lines x rw / 2 pair bytes from rx
for (k, x, y, rx, rw, a) in buttons:
    for st in (0, 1):
        o = A0 + a + st * (rw // 2) * 12
        for yy in range(12):
            row = []
            for xx in range(rx, rx + rw):
                if x <= xx < x + 20: row.append(pan[40 + yy][20 * k + xx - x] if st else pan[y - BY + yy][xx - BX])
                else: row.append(img[y + yy][xx])
            for i in range(rw // 2): base[o + yy * (rw // 2) + i] = pair(row[2 * i], row[2 * i + 1])
# the guns' cells (gun * 2 + chosen: 28 x 28, 14 bytes a line): their frames
aw, wx, wy, n = lay['weapons']
for c in range(n):
    o = A0 + aw + c * 14 * 28
    for yy in range(28):
        for i in range(14):
            b = base[o + yy * 14 + i]; px = [lp(b), rp(b)]
            for h in (0, 1):
                xx = 2 * i + h
                if 1 <= xx <= 25 and (1 <= yy <= 17 or 19 <= yy <= 26): continue
                px[h] = pan[wy - BY + yy][wx - BX + xx]
            base[o + yy * 14 + i] = pair(px[0], px[1])
hdr = bytearray(b'PNL1') + b''.join(v.to_bytes(2, 'little') for v in lay['hdr']); hdr += bytes(128 - len(hdr))
open(os.path.join(dst, 'UFO2.PNL'), 'wb').write(bytes(hdr) + bytes(base))
print('UFO2.PNL', len(hdr) + len(base), 'bytes')
