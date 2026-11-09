# xin.py SCL OUTDIR: the intro (key 1) and the instruction (key 3) of "UFO2 BIS.SCL" (crack v2.10): its loader
# (#61A8) reads them by DE = track (logical, side in bit 0) / sector 1..16 (the SCL's data = the disk from track 1);
# the blocks follow each other (DE kept). Each block: the 128K page (#7FFD) and where.
import sys, os
scl, out = sys.argv[1:3]; os.makedirs(out, exist_ok=True)
d = open(scl, 'rb').read(); n = d[8]; flat = d[9 + 14 * n:]
def blk(idx, cnt): return flat[(idx - 16) * 256:(idx - 16 + cnt) * 256]
def chain(tr, sc, parts):
    idx = tr * 16 + sc - 1; r = []
    for pg, ad, cnt in parts: r.append((pg, ad, blk(idx, cnt))); idx += cnt
    return r
INSTR = chain(0x1C, 6, [(7, 0xDB00, 0x25), (0, 0x7000, 0x57)])            # run: #7FFD = #10, CALL #7000
INTRO = chain(0x0B, 6, [(1, 0xC000, 0x32), (4, 0xC000, 0x34), (0, 0xC000, 0x2C), (6, 0xC000, 0x20), (7, 0xC000, 0x20),
                        (3, 0xC000, 0x1C), (0, 0x7000, 0x22)])
for nm, ps in (('instr', INSTR), ('intro', INTRO)):
    for pg, ad, b in ps:
        fn = '%s_p%d_%04X.bin' % (nm, pg, ad); open(os.path.join(out, fn), 'wb').write(b); print(fn, len(b))
