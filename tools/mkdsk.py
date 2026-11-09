# ATM CP/M floppy (TRD 640K) with files: python3 mkdsk.py template.trd out.trd file1 [file2 ...]
# layout (as on the ATM CP/M disks): 8K system area, then 2K blocks; directory = blocks 0-1 (128 entries);
# 16-bit block numbers, 8 per entry (16K = one extent, RC up to #80)
import sys, os
tpl, out, files = sys.argv[1], sys.argv[2], sys.argv[3:]
img = bytearray(open(tpl, 'rb').read())
BASE, BS = 0x2000, 2048
NBLK = (len(img) - BASE) // BS
img[BASE:] = b'\xE5' * (len(img) - BASE)
blk, ent = 2, 0
for f in files:
    data = open(f, 'rb').read()
    rec = (len(data) + 127) // 128
    data += b'\x1A' * (rec * 128 - len(data))
    n, _, e = os.path.basename(f).upper().partition('.')
    name = (n[:8].ljust(8) + e[:3].ljust(3)).encode()
    for ex in range(max(1, (rec + 127) // 128)):
        part = data[ex * 16384:(ex + 1) * 16384]
        bl = []
        for i in range(0, len(part), BS):
            assert blk < NBLK, 'disk full'
            img[BASE + blk * BS:BASE + blk * BS + len(part[i:i + BS])] = part[i:i + BS]; bl.append(blk); blk += 1
        rc = min(128, rec - ex * 128)
        d = bytes([0]) + name + bytes([ex & 31, 0, ex >> 5, rc])
        for i in range(8): d += (bl[i] if i < len(bl) else 0).to_bytes(2, 'little')
        img[BASE + ent * 32:BASE + ent * 32 + 32] = d; ent += 1
open(out, 'wb').write(img)
print(out, ent, 'entries,', blk, 'of', NBLK, 'blocks')
