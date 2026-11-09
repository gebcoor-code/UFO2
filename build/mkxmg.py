# mkxmg.py - xmgame.bin: the game's own location tiles (UFO-2 ZX, disk 2) for mkmap.py. A one-off tool.
#   python3 mkxmg.py   (reads data/ufo2img.dat, data/xm0.lpc, data/xm1.lpc, ../UFO2SRC/ASM80/XDISK2.A80; writes xmgame.bin here)
# In: the game's disk 2 image (data/ufo2img.dat; the files as XDISK2.A80 lists them: #1..#19 = m2, m3, m4, m5, m10, m7, m8,
# m9, m6, m11..m20 - the tile sets XM2..XM20, LPC packed, 2 bytes of length first), XM0.LPC / XM1.LPC (the interceptor's
# and the UFO's tiles, resident in the game: XPAGE.A80 xSHIP / xUFO).
# Out: xmgame.bin = zlib of: for XM0, XM1, .. XM20 in turn: count (1 byte: 16, 48, 32 or 80) + count x 128 bytes (a tile:
# 32 lines x (mask, ink) x 2 columns, as the game draws it). XM2..XM20's 192-byte head (xATR, xCONV) is left out.
# Plain Python 3, nothing else needed.
import os, re, zlib
import lpc
here = os.path.dirname(os.path.abspath(__file__))
img = open(os.path.join(here, 'data/ufo2img.dat'), 'rb').read()
BASE = 68608                                    # file #1 (m2) in ufo2img.dat; XDISK2: sector (1K), offset / 4
tab = re.findall(r'DEFB\s+(\d+),(\d+)\s*;#(\d+) \((\w+)\)', open(os.path.join(here, '../UFO2SRC/ASM80/XDISK2.A80'), encoding='cp866').read())
def unpack(d): return lpc.unpack(d[2:2 + (d[0] | d[1] << 8)])
sets = {0: unpack(open(os.path.join(here, 'data/xm0.lpc'), 'rb').read()),
        1: unpack(open(os.path.join(here, 'data/xm1.lpc'), 'rb').read())}
for sec, sh, no, name in tab:
    if not re.fullmatch(r'm\d+', name): continue
    u = unpack(img[BASE + int(sec) * 1024 + int(sh) * 4:])
    assert len(u) in (192 + 32 * 128, 192 + 80 * 128), (name, len(u))
    sets[int(name[1:])] = u[192:]
assert sorted(sets) == list(range(21)) and len(sets[0]) == 2048 and len(sets[1]) == 6144
out = b''.join(bytes([len(sets[n]) // 128]) + sets[n] for n in range(21))
open(os.path.join(here, 'xmgame.bin'), 'wb').write(zlib.compress(out, 9))
print('xmgame.bin:', ', '.join('XM%d %d' % (n, len(sets[n]) // 128) for n in range(21)))
