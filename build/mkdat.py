# UFO2.DAT (v72: packed): UFO2.COM reads it as one stream (128-byte records), port/title.asm lz_blk unpacks it.
#   31 bytes: the SNA's header (27) + PC (2) + #7FFD + TR-DOS flag
#   blocks (each 16K at most, unpacked into STAGE): flag 0 = all zeros (16K), 1 = LPC stream (lpc.py: the 4 tail
#   bytes, tokens, #80; literals not rotated) - its own length only by the end mark
#   - 8 banks: 5, 2, the paged one, then 0..7 without those (as SNA)
#   - the fight's panels: 16K pages OPG0.. (the last one shorter)
#   - the disk: the tracks the game reads (li 0 = 4, 1 = 5, 2.. = 55..127), 4 per 16K page dpages[0..18]
#   - MPG's MX code (port/ufo2x.bin: port/mx.asm; ram_init.asm mx_load), TLPG's hooks' part (port/ufo2p.bin: xpnt.asm)
# Packed blocks are cached (out/lzc/<sha1>) - pack_opt is slow.
import os, re, hashlib
import lpc
D = os.path.dirname(os.path.abspath(__file__))
C = os.path.join(D, 'out/lzc'); os.makedirs(C, exist_ok=True)
B = os.environ.get('UFO_BIN', os.path.join(D, '../port'))     # (NedoOS: the bins of its own build, its own out)
O = os.environ.get('UFO_OUT', os.path.join(D, 'out'))
def blk(b):
    if not any(b) and len(b) == 16384: return b'\0'
    h = hashlib.sha1(b).hexdigest(); f = os.path.join(C, h)
    if os.path.exists(f): p = open(f, 'rb').read()
    else:
        p = lpc.pack_opt(b); assert lpc.unpack(p) == b; open(f, 'wb').write(p)
    return b'\1' + unrot(p)
def unrot(p):                       # lpc.py's literals are rotated (the game's DELPC: RRCA) - ours are not
    p = bytearray(p); j = 4
    while True:
        a = p[j]
        if a < 0x80: t = (a >> 4) & 15; j += 2
        elif a < 0xC0:
            j += 1; t = a & 0x3F
            if t == 0: break
        else: t = p[j + 1] >> 4; j += 3
        for k in range(j, j + t): p[k] = lpc.rr(p[k])
        j += t
    return bytes(p)
sna = open(os.path.join(D, 'out/UFO2.SNA'), 'rb').read(); assert len(sna) == 131103
pnl = open(os.path.join(D, 'out/UFO2.PNL'), 'rb').read()
n = int(re.search(r'PN2_PNL equ (\d+)', open(os.path.join(D, '../port/pn2_tab.inc')).read()).group(1))
assert (len(pnl) + 127) // 128 == n, (len(pnl), n)
img = open(os.path.join(D, 'data/ufo2img.dat'), 'rb').read(); assert len(img) == 364544
# the encyclopedia's 60 pictures (20 LPC blocks, the game's files #36..#49): never loaded now (mods.py) - zeros; their
# RAM (DAT bytes 125000.., 163819): page 8 (131072..) is port/enl.asm's buffer (a picture read from UFO2.ENC)
img = img[:182344] + bytes(163819) + img[182344 + 163819:]
# (0.59.2) the maps edited: data/til/src/XL<name>.LND (the til tools' maps) that differ from the disk's file (XDISK2.A80:
# l2, l3, l5a..) - packed anew (lpc.pack_opt, the game's DELPC) into its place; it must fit before the next file
BASE = 68608
tab = re.findall(r'DEFB\s+(\d+),(\d+)\s*;#(\d+) \((\w+)\)', open(os.path.join(D, '../UFO2SRC/ASM80/XDISK2.A80'), encoding='cp866').read())
img = bytearray(img)
for i, (sec, sh, no, name) in enumerate(tab):
    f = os.path.join(D, 'data/til/src/XL%s.LND' % name[1:].upper())
    if not re.fullmatch(r'l\d+[a-d]?', name) or not os.path.exists(f): continue
    o = BASE + int(sec) * 1024 + int(sh) * 4; n = img[o] | img[o + 1] << 8
    new = open(f, 'rb').read(); assert len(new) == 8192, f
    if lpc.unpack(bytes(img[o + 2:o + 2 + n])) == new: continue
    room = (int(tab[i + 1][0]) * 1024 + int(tab[i + 1][1]) * 4) - (int(sec) * 1024 + int(sh) * 4)
    h = hashlib.sha1(b'map' + new).hexdigest(); cf = os.path.join(C, h)
    if os.path.exists(cf): pk = open(cf, 'rb').read()
    else: pk = lpc.pack_opt(new); assert lpc.unpack(pk) == new; open(cf, 'wb').write(pk)
    assert len(pk) + 2 <= room, ('XL' + name[1:], len(pk) + 2, room)
    img[o:o + 2 + len(pk)] = bytes([len(pk) & 255, len(pk) >> 8]) + pk
    print('XL%s.LND: the map edited - packed in (%d of %d bytes)' % (name[1:].upper(), len(pk) + 2, room))
img = bytes(img)
out = bytearray(sna[:27] + sna[49179:49183])
pg = sna[49181] & 7
bank = {5: sna[27:27 + 16384], 2: sna[27 + 16384:27 + 32768], pg: sna[27 + 32768:27 + 49152]}
o = 49183
for k in range(8):
    if k in bank: continue
    bank[k] = sna[o:o + 16384]; o += 16384
nb = 0
for k in [5, 2, pg] + [k for k in range(8) if k not in (5, 2, pg)]: out += blk(bank[k]); nb += 1
pp = pnl + b'\x1a' * ((-len(pnl)) % 128)
for i in range(0, len(pp), 16384): out += blk(pp[i:i + 16384]); nb += 1
def trk(t): return img[(t if t < 16 else t - 55 + 16) * 4096:][:4096]
tl = [trk(4), trk(5)] + [trk(t) for t in range(55, 128)]
for i in range(0, len(tl), 4): out += blk(b''.join(tl[i:i + 4])); nb += 1
mx = open(os.path.join(B, 'ufo2o.bin'), 'rb').read() + open(os.path.join(B, 'ufo2x.bin'), 'rb').read() + open(os.path.join(B, 'ufo2p.bin'), 'rb').read(); assert 0 < len(mx) <= 16384   # MPG's objects' code (port/obj.asm) and MX (port/mx.asm)
out += blk(mx + bytes(max(0, 64 - len(mx)))); nb += 1
out += b'\x1a' * ((-len(out)) % 128)
open(os.path.join(O, 'UFO2.DAT'), 'wb').write(out)
print('UFO2.DAT', len(out), 'bytes,', nb, 'blocks')
