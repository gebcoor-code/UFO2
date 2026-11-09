# mkint.py - UFO2.INT (0.63.0): the original's intro (XBEGIN + XDEMO, the menu's "1") for port/mnu.asm mm_int:
# its 8 ZX banks (16K each; 0.64.0: in the order 0, 1, 2, 3, 4, 6, 7, 5 - bank 5 goes into ATM's page 5, CP/M's BIOS's
# RAM, past all the disk's reading) as they are when XBEGIN starts (its ST1_ - DI : LD (OLDSP+1),SP :
# LD SP,#BFF0), packed (mkico.py pk). The port runs it in place: banks in pages INTB+n (bank 5 - page 5, the ZX
# screen), its MEME (LD BC,#7FFD : AND 7 : OR 16 : OUT (C),A : RET - the only #7FFD) -> JP mi_mem.
#   python3 mkint.py SCL   - data/intro.bin from "UFO2 BIS.SCL" (the crack of v2.10: its loader's blocks - xin.py -
#                            run in a bare 128K, z80 module, till ST1_; 8 x 16K + ST1_ (2 bytes)); and
#                            data/mufo.bin - the menu's music (0.64.0; DANGEROU's block - DE #0701, #45 sectors to
#                            #7000 - run till its CALL XMUSIC: M_UFO at #EA4F, its INIT #EA60, PLAY #EA66 -
#                            #EA00..#FFFF of bank 0; its PLAY writes only there)
#   python3 mkint.py [OUT] - out/UFO2.INT from data/intro.bin
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.join(here, 'data/intro.bin')
ST1, MEME = 0x705A, 0x75C7                      # (port/mnu0.asm MI_GO, MI_MEME)
MEME_B = bytes.fromhex('01fd7fe607f610ed79c9')
if len(sys.argv) > 1 and sys.argv[1].lower().endswith('.scl'):
    import z80
    d = open(sys.argv[1], 'rb').read(); n = d[8]; flat = d[9 + 14 * n:]
    def blk(idx, cnt): return flat[(idx - 16) * 256:(idx - 16 + cnt) * 256]
    pg = [bytearray(16384) for _ in range(8)]
    idx = 0x0B * 16 + 6 - 1                     # (the loader: DE = #0B06 - track, sector 1..16; then in a row)
    for p, ad, cnt in ((1, 0xC000, 0x32), (4, 0xC000, 0x34), (0, 0xC000, 0x2C), (6, 0xC000, 0x20), (7, 0xC000, 0x20),
                       (3, 0xC000, 0x1C), (0, 0x7000, 0x22)):
        b = blk(idx, cnt); idx += cnt
        for i, x in enumerate(b):
            a = ad + i; pg[5 if a < 0x8000 else 2 if a < 0xC000 else p][a & 0x3FFF] = x
    m = z80.Z80Machine(); mem = m.memory; cur = [0]
    m.set_memory_block(0x4000, bytes(pg[5])); m.set_memory_block(0x8000, bytes(pg[2])); m.set_memory_block(0xC000, bytes(pg[0]))
    def pout(p, v):
        if (p & 0x8002) == 0:
            pg[cur[0]][:] = mem[0xC000:0x10000]; cur[0] = v & 7; m.set_memory_block(0xC000, bytes(pg[cur[0]]))
    m.set_output_callback(pout); m.set_input_callback(lambda p: 0 if (p & 0xFF) == 0x1F else 0xFF)
    m.sp = 0x6000; m.pc = 0x7000
    for k in range(10_000_000):
        m.ticks_to_stop = 1; m.run(); pc = m.pc
        if bytes(mem[pc:pc + 3]) == b'\xf3\xed\x73' and bytes(mem[pc + 5:pc + 8]) == b'\x31\xf0\xbf': break
    else: raise SystemExit('XBEGIN\'s start not reached')
    assert pc == ST1 and cur[0] == 0, (hex(pc), cur[0])
    pg[0][:] = mem[0xC000:0x10000]; pg[5][:] = mem[0x4000:0x8000]; pg[2][:] = mem[0x8000:0xC000]
    open(IMG, 'wb').write(b''.join(pg) + bytes([ST1 & 255, ST1 >> 8])); print('data/intro.bin written')
    m = z80.Z80Machine(); mem = m.memory
    m.set_memory_block(0x7000, blk(7 * 16, 0x45)); m.set_input_callback(lambda p: 0 if (p & 0xFF) == 0x1F else 0xFF)
    m.sp = 0x6000; m.pc = 0x7000
    for k in range(30_000_000):
        m.ticks_to_stop = 1; m.run()
        if m.pc == 0xEA60: break
    else: raise SystemExit('DANGEROU\'s XMUSIC not reached')
    assert bytes(mem[0xEA4F:0xEA54]) == b'M_UFO'
    open(os.path.join(here, 'data/mufo.bin'), 'wb').write(bytes(mem[0xEA00:0x10000])); print('data/mufo.bin written')
    sys.exit()
d = open(IMG, 'rb').read(); assert len(d) == 8 * 16384 + 2 and d[-2] | d[-1] << 8 == ST1
assert d[5 * 16384 + MEME - 0x4000:5 * 16384 + MEME - 0x4000 + len(MEME_B)] == MEME_B, 'MEME not where expected'
sys.path.insert(0, here)
from mkico import pk
out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, 'out/UFO2.INT')
p = pk(b''.join(d[b * 16384:(b + 1) * 16384] for b in (0, 1, 2, 3, 4, 6, 7, 5))); open(out, 'wb').write(p); print('UFO2.INT', len(p))
