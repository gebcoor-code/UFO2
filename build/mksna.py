# UFO2.SNA (128K) from the source build: modules packed (LPC) into bank 0 as XCOM2.A80 does, table at #4000.
import re, lpc
sym = {}
for l in open('out/sym.txt'):
    m = re.match(r'(\S+): (?:EQU )?0x([0-9A-F]+)', l)
    if m: sym[m.group(1)] = int(m.group(2), 16)
b5 = bytearray(open('out/b5.bin', 'rb').read()); b2 = open('out/b2.bin', 'rb').read()
main = b5 + b2                      # #4000..#BFFF
p0 = open('out/p0.bin', 'rb').read()
def mainseg(a, e): return bytes(main[a - 0x4000:e - 0x4000])
def p0seg(a, e): return p0[a - 0xC000:e - 0xC000]
mods = [mainseg(sym['l_LESHA'], sym['MOD0_E']), p0seg(sym['l_ASMBL1'], sym['MOD1_E']),
        p0seg(sym['l_ASMBL2'], sym['MOD2_E']), p0seg(sym['l_ASMBL3'], sym['MOD3_E'])]
bank0 = bytearray(16384); pos = 0; table = []
for k in (1, 2, 3, 0):              # BLK2..BLK4, BLK1 (XCOM2 order)
    pk = lpc.pack_opt(mods[k]); assert lpc.unpack(pk) == mods[k]
    blk = len(pk).to_bytes(2, 'little') + pk
    table.append((k, 0xC000 + pos + 2)); bank0[pos:pos + len(blk)] = blk; pos += len(blk)
    print('module %d: %d -> %d' % (k, len(mods[k]), len(pk)))
assert pos <= 0x3FF0, 'bank 0 full'
bank0[0x3FF0:0x3FF0 + 11] = 'Моя работа!'.encode('cp866')
for k, a in table: b5[2 * k:2 * k + 2] = a.to_bytes(2, 'little')
for k in range(8, 16): b5[k] = 1
banks = {0: bytes(bank0), 1: open('out/p1.bin', 'rb').read(), 2: b2, 3: open('out/p3.bin', 'rb').read(),
         4: open('out/p4.bin', 'rb').read(), 5: bytes(b5), 6: bytes(16384), 7: open('out/p7.bin', 'rb').read()}
# SNA: I, HL',DE',BC',AF', HL,DE,BC,IY,IX, IFF2, R, AF, SP, IM, border; 48K; PC, #7FFD, TR-DOS; other banks
hdr = bytes([0x41]) + bytes(16) + bytes([0, 0]) + bytes([0, 0]) + bytes([0, 0]) + (0x4030).to_bytes(2, 'little') + bytes([1, 0])
assert len(hdr) == 27
pc = sym['l_JP_ST']
sna = hdr + banks[5] + banks[2] + banks[7] + pc.to_bytes(2, 'little') + bytes([0x17, 0])
for k in (0, 1, 3, 4, 6): sna += banks[k]
open('out/UFO2.SNA', 'wb').write(sna); print('UFO2.SNA', len(sna), 'PC %04X' % pc)
