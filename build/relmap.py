# Map labels of the source build onto the release (snapshot + decompressed modules):
# for every listing line that has a 16-bit operand naming a label, find the same instruction in the release image
# (local alignment +-48 bytes, operand bytes masked) and read the release's value -> votes per label.
#   python3 relmap.py out/main.lst LABEL [LABEL...]   (no labels: all)
import re, sys, collections
S = '/tmp/claude-0/-home-claude/1aea26be-28a6-5a6e-b0ff-e540c3320bb1/scratchpad/'
def img(parts):
    m = bytearray(65536)
    for addr, data in parts: m[addr:addr + len(data)] = data
    return m
bk = [open('../snap/bank%d.bin' % i, 'rb').read() for i in range(8)]
swap = open('out/swap_rel.bin', 'rb').read()
rel = {
    'main': img([(0x4000, bk[5]), (0x8000, bk[2]), (0x7580, swap)]),
    'mod2': img([(0x4000, bk[5]), (0x8000, bk[2])]),
    'mod3': bytearray(img([(0x4000, open(S + 'x3.bin', 'rb').read())])),
    'mod1': bytearray(img([(0x4000, open(S + 'x1.bin', 'rb').read())])),
    'lesha': bytearray(img([(0x4000, open(S + 'x0.bin', 'rb').read())])),
}
sym = {}
for l in open('out/sym.txt'):
    m = re.match(r'(\S+): (?:EQU )?0x([0-9A-F]+)', l)
    if m: sym[m.group(1)] = int(m.group(2), 16)

ours = collections.defaultdict(lambda: bytearray(65536))
lines = []
seg = 'main'; skip = False
LRE = re.compile(r'^\s*\d+\+*([0-9A-F]{4}) ((?:[0-9A-F]{2} )*)\s*(.*)$')
for raw in open(sys.argv[1], encoding='cp866', errors='replace'):
    m = LRE.match(raw.rstrip('\n'))
    if not m: continue
    addr = int(m.group(1), 16); bs = bytes(int(x, 16) for x in m.group(2).split()); src = m.group(3)
    if 'DISP' in src:
        if 'l_LESHA' in src: seg = 'lesha'
        elif 'l_ASMBL1' in src: seg = 'mod1'
        elif 'l_ASMBL2' in src: seg = 'mod2'
        elif 'l_ASMBL3' in src: seg = 'mod3'
    if re.match(r'\s*ENT\b', src): seg = 'main'
    if re.match(r'\s*PAGE\s+[1347]', src): skip = True
    if re.match(r'\s*PAGE\s+0', src): skip = False
    if skip or '...' in raw: continue
    for k, b in enumerate(bs): ours[seg][addr + k] = b
    lines.append((seg, addr, bs, src))

want = set(sys.argv[2:])
votes = collections.defaultdict(collections.Counter)
for seg, addr, bs, src in lines:
    if len(bs) < 3: continue
    for name in re.findall(r'\bl_\w+', src):
        if want and name not in want: continue
        if name not in sym: continue
        # operand position: last two bytes for LD rr,nn / CALL / JP / LD (nn); DEFW: every pair
        if src.split()[0] in ('DEFW',) or (src.split() and src.split()[0].startswith('l_') and 'DEFW' in src):
            continue
        opos = len(bs) - 2
        ov = bs[opos] | bs[opos + 1] << 8
        delta = ov - sym[name]
        if abs(delta) > 4096: continue
        R = rel[seg]; O = ours[seg]
        best = None
        for d in range(-48, 49):
            sc = 0
            for k in list(range(-14, 0)) + list(range(0, opos)) + list(range(len(bs), len(bs) + 14)):
                a = addr + k
                if 0 <= a + d < 65536 and O[a] == R[a + d]: sc += 1
            if best is None or sc > best[0]: best = (sc, d)
        if best[0] < 22: continue
        a = addr + best[1] + opos
        rv = R[a] | R[a + 1] << 8
        votes[name][rv - delta] += 1
for name in sorted(votes):
    c = votes[name].most_common(3)
    print('%-12s ours %04X  release %s' % (name, sym[name], ' '.join('%04X(%d)' % kv for kv in c)))
