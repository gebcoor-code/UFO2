# port/txrb.bin: the text recognition's table (port/epg.asm TX_RB, textr.asm tx_rcg) from the game's font (out/b5.bin
# at l_FONT, 128 x 8 bytes - as port/xtil.asm tx_init copies it): 512 entries (the character + 1; TA - 0 as it is,
# 1 / 2 a tall letter's upper / lower half, its 4 lines each twice - with the tag: the 8 bytes' sum & #FC), each
# pattern once, at its hash (per line: rotated left, the byte XORed in) * 2 or the first free one past it (wrapping);
# all 128 as they are first, then the upper halves, then the lower ones (as tx_rp finds them); not a half with
# one byte (and zeros) only: a button's edge, a frame's line would be one
import re
sym = {}
for l in open('out/sym.txt'):
    m = re.match(r'(\S+): (?:EQU )?0x([0-9A-F]+)', l)
    if m: sym[m.group(1)] = int(m.group(2), 16)
b5 = open('out/b5.bin', 'rb').read(); f = sym['l_FONT'] - 0x4000; gf = b5[f:f + 1024]
def pat(k, ta):
    g = gf[8 * k:8 * k + 8]
    if ta == 0: return bytes(g)
    h = g[:4] if ta == 1 else g[4:]
    return bytes(v for v in h for _ in (0, 1))
def hsh(p):
    x = 0
    for v in p: x = (((x << 1) | (x >> 7)) & 255) ^ v
    return x
tb = bytearray(1024)
for ta in (0, 1, 2):
    for k in range(128):
        if ta and len(set(pat(k, ta)) - {0}) < 2: continue  # (a half that is one line's byte only - '_' -
                                                        #  is in a button's edge: not a letter there)
        p = pat(k, ta); tag = sum(p) & 0xFC; i = hsh(p) * 2; found = False
        while tb[2 * i]:
            if tb[2 * i + 1] & 0xFC == tag and pat(tb[2 * i] - 1, tb[2 * i + 1] & 3) == p: found = True; break
            i = (i + 1) % 512
        if not found: tb[2 * i] = k + 1; tb[2 * i + 1] = tag | ta
open('../port/txrb.bin', 'wb').write(tb)
bf = bytearray(256)                             # port/txbf.bin (textr.asm tx_flt): per hash a bit per tag's bits 2..4
for i in range(512):
    if tb[2 * i]:
        p = pat(tb[2 * i] - 1, tb[2 * i + 1] & 3); bf[hsh(p)] |= 1 << ((sum(p) >> 2) & 7)
open('../port/txbf.bin', 'wb').write(bf)
print('txrb.bin: %d entries' % sum(1 for i in range(512) if tb[2 * i]))
