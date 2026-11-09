# ATM CP/M hard disk image (as the author's ufo2ega.hdd for the emulator: drive C:, IDE ATM, CHS 723/15/38) with
# files: python3 mkhdd.py out.hdd file1 [file2 ...]  (and geometry.chs beside out.hdd)
# The image file is laid out as the emulator's disk: CHS 723/15/38, 512-byte sectors, (c * 15 + h) * 38 + s. CP/M's
# BIOS sees it as 5 heads x 17 sectors a track: its track T (T = 0 reserved) is cylinder T / 5, head T % 5, sectors
# 0..16 of it (the rest of each track and heads 5..14 unused). On that: 2K blocks from track 1; the directory =
# blocks 0-1 (128 entries, a free one: #E5 then zeros); 16-bit block numbers, 8 per entry (16K = one extent, RC up to
# #80). The image holds the disk's first 24 cylinders (7004160 bytes; till 0.62.0 - the author's 11616 sectors, 5947392:
# the files grew past it in 0.63.0).
import sys, os
out, files = sys.argv[1], sys.argv[2:]
SIZE, NDIR, SPT, HEADS, PSPT, PHEADS = 24 * 15 * 38 * 512, 128, 17, 5, 38, 15
img = bytearray(SIZE)
def put(L, data):                               # CP/M's 512-byte sector L (from the directory's start)
    t = L // SPT + 1; c, h = divmod(t, HEADS)
    o = ((c * PHEADS + h) * PSPT + L % SPT) * 512
    assert o + 512 <= SIZE, 'disk full'
    img[o:o + len(data)] = data
dirb = bytearray(NDIR * 32)
for i in range(NDIR): dirb[i * 32] = 0xE5
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
        for i in range(0, len(part), 2048):
            b = part[i:i + 2048]
            for j in range(0, len(b), 512): put(blk * 4 + j // 512, b[j:j + 512])
            bl.append(blk); blk += 1
        rc = min(128, rec - ex * 128)
        d = bytes([0]) + name + bytes([ex & 31, 0, ex >> 5, rc])
        for i in range(8): d += (bl[i] if i < len(bl) else 0).to_bytes(2, 'little')
        assert ent < NDIR, 'directory full'
        dirb[ent * 32:ent * 32 + 32] = d; ent += 1
for k in range(0, len(dirb), 512): put(k // 512, dirb[k:k + 512])
open(out, 'wb').write(img)
open(os.path.join(os.path.dirname(os.path.abspath(out)), 'geometry.chs'), 'wb').write(
    b'#UFO2 EGA HDD edition\r\n\r\nInterface=ATM\r\nCHS=723/15/38')
print(out, ent, 'entries,', blk, 'blocks')
