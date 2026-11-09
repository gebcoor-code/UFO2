import collections
# ATM Turbo 2+ CP/M test bench (for UFO2.COM): 64 RAM pages, windows by ports #3FF7/#7FF7/#BFF7/#FFF7
# (value = #7F - page for RAM), CP/M BDOS stubs (console, open, sequential / random read), screen modes from
# ESC M0 (320x200x16) / M1 (text) / M2 (640x200), Kempston mouse, ZX keyboard matrix (#FE), IM2 50 Hz.
#   python3 atmsim.py prog.com diskdir script outdir
# script: wait N | key K [frames] (K = ZX key: a..z 0..9 enter space caps sym) | mouse DX DY [btn] | shot NAME
#         | peek ADDR N | log
import sys, os, z80
from PIL import Image

com, diskdir, scriptf, outdir = sys.argv[1:5]
os.makedirs(outdir, exist_ok=True)
m = z80.Z80Machine(); mem = m.memory
pages = [bytearray(16384) for _ in range(64)]
if os.environ.get('RNDMEM'):      # RNDMEM=seed: the RAM's pages random at the start (as a real machine's)
    import random; random.seed(int(os.environ['RNDMEM'])); pages = [bytearray(random.randbytes(16384)) for _ in range(64)]
win = [0, 4, 2, 3]
def page_of(w): return win[w]
def flush():
    for w in range(4): pages[win[w]][:] = mem[w * 0x4000:(w + 1) * 0x4000]
ALIASW = []
def setwin(w, p):
    if win[w] == p: return
    pages[win[w]][:] = mem[w * 0x4000:(w + 1) * 0x4000]
    for o in range(4):          # the leaving page still in another window: that copy is stale, refresh it
        if o != w and win[o] == win[w]:
            if not ALIASW: ALIASW.append(1); print('warning: page %d in windows %d and %d pc %04X frame %d' % (win[w], w, o, m.pc, frames))
            m.set_memory_block(o * 0x4000, bytes(pages[win[w]]))
    # the same page in another window: take its live copy
    for o in range(4):
        if o != w and win[o] == p: pages[p][:] = mem[o * 0x4000:(o + 1) * 0x4000]
    win[w] = p
    m.set_memory_block(w * 0x4000, bytes(pages[p]))
    if os.environ.get('DBGPG') and p == int(os.environ['DBGPG']): print('dbgpg', w, frames, 'pc %04X' % m.pc, sum(1 for b in pages[p] if b), win, pages[p][0x3A00], mem[w * 0x4000 + 0x3A00])
    if ZXT: zxt_mark(w)
    alias_upd()
    # keep aliases coherent: windows showing the same page get the same bytes
def readpage(p):
    for w in range(4):
        if win[w] == p: return bytes(mem[w * 0x4000:(w + 1) * 0x4000])
    return bytes(pages[p])

BIOS = 0xEA00
def setb(a, bs): m.set_memory_block(a, bytes(bs))
setb(0, [0xC3, 0x03, BIOS >> 8, 0x01, 0x00, 0xC3, 0x06, 0xDC])
setb(0xF900, [0xFA] * 257); setb(0xFAFA, [0xFB, 0xED, 0x4D])
setb(0xF000, [0xED, 0x5E, 0x3E, 0xF9, 0xED, 0x47, 0xFB, 0xC3, 0x00, 0x01])
for a in (0x0000, 0x0005, BIOS + 3, BIOS + 27): m.set_breakpoint(a)
setb(0x100, open(com, 'rb').read())
for st in os.environ.get('STUBS', '').split(','):   # STUBS=ADDR:HEX,..: bytes put there (BIOS entries)
    if st: sa, sb = st.split(':'); setb(int(sa, 16), bytes.fromhex(sb))
if os.environ.get('TAIL'): tl = (' ' + os.environ['TAIL'].upper()).encode(); setb(0x80, bytes([len(tl)]) + tl + b'\0')   # TAIL=args: the command line
m.pc = 0xF000; m.sp = 0xDC00

files = {}; fnames = {}
for fn in os.listdir(diskdir):
    n, _, e = fn.upper().partition('.')
    k = (n[:8].ljust(8) + e[:3].ljust(3)).encode(); files[k] = open(os.path.join(diskdir, fn), 'rb').read(); fnames[k] = fn
dma = 0x80; console = []; mode = ['text']; esc = []
keyq = []; dlog = []; pend = []
def ret():
    sp = m.sp; m.pc = mem[sp] | mem[sp + 1] << 8; m.sp = sp + 2
def conout(ch):
    console.append(ch)
    s = bytes(console[-3:])
    if s == b'\x1bM0': mode[0] = 'ega'
    elif s == b'\x1bM1': mode[0] = 'text'
    elif s == b'\x1bM2': mode[0] = 'hires'
def bdos():
    global dma
    c = m.c; de = m.de; a = 0
    if c == 9:
        while mem[de] != 0x24: conout(mem[de]); de += 1
    elif c == 2: conout(m.e)
    elif c == 26: dma = de
    elif c == 15:
        a = 0 if bytes(mem[de + 1:de + 12]) in files else 255
        if os.environ.get('ENCDRV') and bytes(mem[de + 1:de + 12]) == b'UFO2    ENC':   # ENCDRV=N (1 = A:): UFO2.ENC only there
            dv = mem[de] or 2; a = 0 if dv == int(os.environ['ENCDRV']) else 255; dlog.append('open ENC %d %d' % (dv, a))
    elif c == 20:
        d = files[bytes(mem[de + 1:de + 12])]
        r = mem[de + 32] + 128 * mem[de + 12]
        if r * 128 >= len(d): a = 1
        else:
            blk = d[r * 128:r * 128 + 128]; blk += b'\x1a' * (128 - len(blk)); setb(dma, blk)
            r += 1; mem[de + 32] = r & 127; mem[de + 12] = r >> 7
    elif c in (33, 34):
        name = bytes(mem[de + 1:de + 12]); d = files[name]
        r = mem[de + 33] | mem[de + 34] << 8 | mem[de + 35] << 16
        dlog.append('%s %d' % ('R' if c == 33 else 'W', r))
        if c == 33:
            if r * 128 >= len(d): a = 6
            else:
                blk = d[r * 128:r * 128 + 128]; blk += b'\x1a' * (128 - len(blk)); setb(dma, blk)
        else:
            d = bytearray(d); d[r * 128:r * 128 + 128] = bytes(mem[dma:dma + 128]); files[name] = bytes(d)
    elif c == 19:
        name = bytes(mem[de + 1:de + 12]); dlog.append('del'); a = 0 if name in files else 255; files.pop(name, None)
    elif c == 22:
        name = bytes(mem[de + 1:de + 12]); files[name] = b''; dlog.append('make')
        fnames[name] = (name[:8].decode().strip() + '.' + name[8:].decode().strip())
    elif c == 21:
        name = bytes(mem[de + 1:de + 12]); r = mem[de + 32] + 128 * mem[de + 12]
        d = bytearray(files[name]); d[r * 128:r * 128 + 128] = bytes(mem[dma:dma + 128]); files[name] = bytes(d)
        r += 1; mem[de + 32] = r & 127; mem[de + 12] = r >> 7; dlog.append('w %d' % (r - 1))
    elif c == 16:
        dlog.append('close'); name = bytes(mem[de + 1:de + 12])
        if os.environ.get('DISKW') and name in fnames: open(os.path.join(diskdir, fnames[name]), 'wb').write(files[name])   # DISKW=1: written back
    elif c == 35:
        n = (len(files.get(bytes(mem[de + 1:de + 12]), b'')) + 127) // 128; mem[de + 33] = n & 255; mem[de + 34] = n >> 8 & 255; mem[de + 35] = n >> 16
    elif c == 6: a = keyq.pop(0) if keyq else 0
    elif c == 25: a = 1
    elif c == 37: dlog.append('reset %04X' % de)
    else: print('BDOS ?', c)
    m.a = a; m.l = a; m.h = 0; ret()

# ---- ports
mx = my = 0; mb = 0xFF; zxkeys = set()
MATRIX = ['caps z x c v', 'a s d f g', 'q w e r t', '1 2 3 4 5', '0 9 8 7 6', 'p o i u y', 'enter l k j h', 'space sym m n b']
KEYPOS = {}
for row, ks in enumerate(MATRIX):
    for bit, k in enumerate(ks.split()): KEYPOS[k] = (row, bit)
def port_in(p):
    if p == 0xFBDF: return mx & 255
    if p == 0xFFDF: return my & 255
    if p == 0xFADF: return mb
    if (p & 0xFF) == 0xFE:
        hi = p >> 8; r = 0x1F
        for k in zxkeys:
            row, bit = KEYPOS[k]
            if not (hi >> row) & 1: r &= ~(1 << bit)
        return r | 0xE0
    return 0xFF
plog = []
AYS = [0]; AYR = [0] * 16; AYF = {}; AYA = []
DBGB = []
def port_out(p, v):
    if (p & 0xFF) == 0x0B and os.environ.get('DBGOUT'): DBGB.append(v); (print('dbg', bytes(DBGB).hex(), 'frame %d' % frames), DBGB.clear()) if len(DBGB) >= int(os.environ['DBGOUT']) else None; return
    if (p & 0xFF) == 0xF7 and (p & 0x3FFF) == 0x3FF7:
        w = p >> 14
        if not (v & 0x40): print('ROM in window', w, hex(v), 'pc %04X sp %04X frame %d win %s' % (m.pc, m.sp, frames, win)); return
        setwin(w, ((~v) & 0x3F) & (31 if os.environ.get('MEM512') else 63))
        if os.environ.get('PW0') and w == 0: print('pw0', win[0], 'pc %04X frame %d' % (m.pc, frames))
        if os.environ.get('PWIN') and '%d:%d' % (w, win[w]) == os.environ['PWIN']: print('pwin %d=%d pc %04X sp %04X frame %d stk %s' % (w, win[w], m.pc, m.sp, frames, ' '.join('%04X' % (mem[(m.sp + 2 * k) & 0xFFFF] | mem[(m.sp + 2 * k + 1) & 0xFFFF] << 8) for k in range(6))))
    elif (p & 0xFF) == 0x77:
        mode[0] = {3: 'zx', 0: 'ega', 2: 'hires', 6: 'text'}.get(v & 7, 'ega'); plog.append('FF77=%02X' % v)
        PEN[0] = (p >> 8) == 0xBD               # (#BD77: #FF is the palette, the entry by the border)
    elif (p & 0xFF) in (0xFE, 0xF6): PEN[1] = (v & 7) | (8 if (p & 0xFF) == 0xF6 else 0)
    elif (p & 0xFF) == 0xFF and PEN[0]:
        q = ~v & 0xFF; lv = lambda mn, lo: (255 if mn and lo else 192 if mn else 96 if lo else 0)
        EP[PEN[1]] = (lv(q & 2, q & 64), lv(q & 16, q & 128), lv(q & 1, q & 32))
        if os.environ.get('PALLOG'): print('pal %d=%s frame %d pc %04X' % (PEN[1], EP[PEN[1]], frames, m.pc))   # PALLOG=1: each palette write
    elif (p & 0xC0FF) == 0xC0FD: AYS[0] = v & 15
    elif (p & 0xC0FF) == 0x80FD:
        AYR[AYS[0]] = v
        if AYS[0] == 13: AYF.setdefault(frames, 0); AYF[frames] += 1      # (the player writes R13 last... or not at all)
        if AYS[0] == 10: AYA.append((frames, AYR[8] | AYR[9] << 4 | v << 8))
        if AYS[0] == 7 and os.environ.get('AYMIX'): AYA.append((frames, 0x10000 | v))      # (AYMIX: the mixer's writes too)
    elif (p & 0xFF) == 0xFD and (p >> 8) == 0x7F:
        plog.append('7FFD=%02X@%d' % (v, frames)); FL.append(frames)
        scr2[0] = (v >> 3) & 1
m.set_input_callback(port_in); m.set_output_callback(port_out)
# the write callbacks below (diagnostics) go through master_w: a page mapped in two windows at once is one memory
# on the machine - a write through either is mirrored into the other (each window has its own copy here)
USERW = [None]; ALI = [[], [], [], []]; REMARK = []        # REMARK: functions (w) putting a diagnostic's marks back
def set_userw(f): USERW[0] = f
def master_w(a, v):
    if USERW[0]: USERW[0](a, v)
    else: mem[a] = v
    for o in ALI[a >> 14]: mem[o * 0x4000 + (a & 0x3FFF)] = mem[a]
m.set_write_callback(master_w)
def alias_upd():
    for w in range(4):
        new = [o for o in range(4) if o != w and win[o] == win[w]]
        if new == ALI[w]: continue
        if new and not ALI[w]: m.mark_addrs(w * 0x4000, 0x4000, m.WRITE_MARK)
        elif not new and ALI[w]:
            m.unmark_addrs(w * 0x4000, 0x4000, m.WRITE_MARK)
            for f in REMARK: f(w)
        ALI[w] = new
if os.environ.get('WMARK'):
    def _wcb(a, v):
        if v != mem[a]: print('wmark %04X <- %02X (was %02X) pc %04X sp %04X frame %d win %s' % (a, v, mem[a], m.pc, m.sp, frames, win))
        mem[a] = v
    set_userw(_wcb)
    for a in os.environ['WMARK'].split(','): m.mark_addr(int(a, 16), m.WRITE_MARK)
if os.environ.get('STKW'):              # STKW=lo,hi: the lowest address written there (a stack's depth)
    _slo, _shi = [int(x, 16) for x in os.environ['STKW'].split(',')]; STKM = [0x10000]
    def _sw(a, v):
        if a < STKM[0] and win[0] == 0 and frames >= int(os.environ.get('STKF', '0')): STKM[0] = a; print('stkw %04X pc %04X frame %d' % (a, m.pc, frames)) if os.environ.get('STKP') else None
        mem[a] = v
    set_userw(_sw)
    for o in range(_slo, _shi): m.mark_addr(o, m.WRITE_MARK)
if os.environ.get('PWATCH'):           # PWATCH=page,lo,hi (offsets hex): who writes there (any window), unique PCs
    _pp, _plo, _phi = [int(x, 16) for x in os.environ['PWATCH'].split(',')]; PWS = set()
    def _pw(a, v):
        if win[a >> 14] == _pp and (m.pc, a >> 14, frames) not in PWS and mem[a] != v:
            PWS.add((m.pc, a >> 14, frames)); print('pwatch %04X <- %02X pc %04X sp %04X frame %d win %s' % (a, v, m.pc, m.sp, frames, win))
        mem[a] = v
    set_userw(_pw)
    def _pwm(w): m.mark_addrs(w * 0x4000 + _plo, _phi - _plo, m.WRITE_MARK)
    for w in range(4): _pwm(w)
    REMARK.append(_pwm)
if os.environ.get('RWATCH'):            # RWATCH=lo,hi (hex, window 0's page 0): who reads there - PC, its page; rwatch.txt
    _rlo, _rhi = [int(x, 16) for x in os.environ['RWATCH'].split(',')]; RWC = {}; RWB = int(os.environ.get('RWBW', '0'), 16)   # RWBW: a flag (page 0) - only while it is set
    def _rw(a):
        if win[0] == 0 and _rlo <= a < _rhi and mem[RWB]:
            k = (m.pc, win[m.pc >> 14] if m.pc >= 0x4000 else 0); RWC[k] = RWC.get(k, 0) + 1
        return mem[a]
    m.set_read_callback(_rw)
    for o in range(_rlo, _rhi): m.mark_addr(o, m.READ_MARK)
if os.environ.get('PRWATCH'):          # PRWATCH=page,lo,hi (offsets hex): who reads there (any window) - unique PCs
    _qp, _qlo, _qhi = [int(x, 16) for x in os.environ['PRWATCH'].split(',')]; PRS = set()
    def _prw(a):
        if win[a >> 14] == _qp and (m.pc, win[m.pc >> 14]) not in PRS:
            PRS.add((m.pc, win[m.pc >> 14])); print('prwatch %04X pc %04X pcpage %d frame %d win %s' % (a, m.pc, win[m.pc >> 14], frames, win))
        return mem[a]
    m.set_read_callback(_prw)
    for w in range(4):
        for o in range(_qlo, _qhi): m.mark_addr(w * 0x4000 + o, m.READ_MARK)
if os.environ.get('WLOW'):              # game code (PC >= #4000) writing below LO (hex): the ROM-sink habits
    WLO = int(os.environ['WLOW'], 16); WSEEN = set()
    def _wl(a, v):
        if m.pc >= 0x4000 and (m.pc, a >> 8) not in WSEEN:
            WSEEN.add((m.pc, a >> 8)); print('wlow %04X <- %02X pc %04X sp %04X frame %d' % (a, v, m.pc, m.sp, frames))
        mem[a] = v
    set_userw(_wl)
    for a in range(0, WLO): m.mark_addr(a, m.WRITE_MARK)

WCN = {}; PRF = {}                     # WCOUNT=page:lo:hi,..: writes there counted by (PC, its window's page, the page, offset / 256)
if os.environ.get('WCOUNT'):            # PROF2=1 (with 'prof2' / 'prof2off' in the script): PC samples (page, PC) every 1000 ticks
    _wr = [tuple(int(x, 16) for x in it.split(':')) for it in os.environ['WCOUNT'].split(',')]
    _wpg = set(r[0] for r in _wr)
    def _wc(a, v):
        pg = win[a >> 14]
        if pg in _wpg:
            o = a & 0x3FFF
            for r in _wr:
                if r[0] == pg and r[1] <= o < r[2]:
                    k = (m.pc, win[m.pc >> 14] if m.pc >= 0x4000 else 0, pg, o >> 8); WCN[k] = WCN.get(k, 0) + 1; break
        mem[a] = v
    set_userw(_wc)
    def _wcm(w):
        for r in _wr: m.mark_addrs(w * 0x4000 + r[1], r[2] - r[1], m.WRITE_MARK)
    for w in range(4): _wcm(w)
    REMARK.append(_wcm)
# ZXTAG=lo-hi,..[;PG,..]: who wrote each byte of the EGA buffers (pages 1, 3, 5, 7) and the screen cache's EGA pages
# (56, 57): the conversion of the ZX screen (PC in lo..hi, or PC >= #C000 with one of the pages PG in W3) or ours;
# an LDI / LDIR copy takes its source byte's tag. shot NAME also writes NAME_z.png (the conversion's pixels shown
# magenta over the picture dimmed - dark: a flat colour) and prints "zx N pattern M" (such bytes in the shown buffer; M:
# not flat - two colours in the byte or against its left neighbour, converted too)
ZXT = {}; ZXR = []; ZXP3 = set(); ZXLR = [None, 0]
if os.environ.get('ZXTAG'):
    _a, _, _b = os.environ['ZXTAG'].partition(';')
    ZXR = [tuple(int(x, 16) for x in r.split('-')) for r in _a.split(',') if r]
    ZXP3 = set(int(x) for x in _b.split(',') if x)
    ZXT = {p: bytearray(16384) for p in (1, 3, 5, 7, 56, 57)}
ZXW = {p: [0] * 16384 for p in ZXT} if os.environ.get('ZXWHO') else None
# ZXSRC=1 (with ZXTAG): the ZX sources too - who wrote each byte of screen 7 (page 15) and of bank 2 (page 10: DSCR),
# copies (one instruction reading then writing: LDI / LDIR) taking their source's writer; shot prints "zxsrc NAME"
# - the converted EGA bytes (picture x 0..255, y 4..195) by the writer of their screen 7 byte (pixels) / attribute
ZXS = {10: [0] * 16384, 15: [0] * 16384} if os.environ.get('ZXSRC') else {}; ZSR = [None, 0]     # ZXWHO=x0,y0,x1,y1: the last writers (PC, W3, frame) of the shown buffer's bytes there, at each shot
def zxt_pc():
    pc = m.pc
    if pc >= 0xC000 and win[3] in ZXP3: return 1
    for lo, hi in ZXR:
        if lo <= pc < hi: return 1
    return 0
def zxt_r(a):
    u = ZXS.get(win[a >> 14])
    if u is not None: ZSR[0] = m.pc; ZSR[1] = u[a & 0x3FFF]
    t = ZXT.get(win[a >> 14])
    if t is not None: ZXLR[0] = m.pc; ZXLR[1] = t[a & 0x3FFF]
    return mem[a]
def zxt_w(a, v):
    u = ZXS.get(win[a >> 14])
    if u is not None: u[a & 0x3FFF] = ZSR[1] if ZSR[0] == m.pc else (m.pc | (win[m.pc >> 14] if m.pc >= 0x4000 else 0) << 16)
    t = ZXT.get(win[a >> 14])
    if t is not None:
        k = zxt_pc()
        if not k and ZXLR[0] == m.pc: k = ZXLR[1]
        t[a & 0x3FFF] = k
        if ZXW: ZXW[win[a >> 14]][a & 0x3FFF] = m.pc | win[3] << 16 | frames << 24
    mem[a] = v
def zxt_mark(w):
    if win[w] in ZXT or win[w] in ZXS: m.mark_addrs(w * 0x4000, 0x4000, m.READ_MARK | m.WRITE_MARK)
    else: m.unmark_addrs(w * 0x4000, 0x4000, m.READ_MARK | m.WRITE_MARK)
if ZXT:
    m.set_read_callback(zxt_r); set_userw(zxt_w); REMARK.append(zxt_mark)
    for _w in range(4): zxt_mark(_w)
exited = False; frames = 0
TPF = int(os.environ.get('TPF', '143360'))       # (TPF=71680: a 3.5 MHz machine)
GSP = [int(x, 16) for x in os.environ['GSPAN'].split(',')] if os.environ.get('GSPAN') else None; GST = [0]; GH = {}
ATS = {}; PROFC = {}; PROFON = [0]; PSH = int(os.environ.get('PSH', '8'))
BPC = {int(a, 16): {} for a in os.environ.get('BPCOUNT', '').split(',') if a}
for a in BPC: m.set_breakpoint(a)
BPW = [int(a, 16) for a in os.environ.get('BPW', '').split(',') if a]
PLD = int(os.environ.get('PLDUMP', '-1'), 16); PLDN = [0]   # PLDUMP=pc: the plane (pages 28, 29) -> plNNN.bin there
DRWL = int(os.environ.get('DRAWLOG', '-1'), 16)   # DRAWLOG=pc (pl_sq): the draw's 8 bytes there
BPL = [int(a, 16) for a in os.environ.get('BPLOG', '').split(',') if a]
TXS = [int(x, 16) for x in os.environ['TXSTAT'].split(',')] if os.environ.get('TXSTAT') else None; TXC = [0, 0, 0]
BPCOND = compile(os.environ['BPCOND'], 'bc', 'eval') if os.environ.get('BPCOND') else None   # BPCOND=expr: BPLOG's hits only then
CHKA = int(os.environ.get('CHKA', '-1'), 16) if os.environ.get('CHKA') else -1; CHKB = int(os.environ['CHKB'], 16) if os.environ.get('CHKB') else -1; CHKS = [None, 0, 0]
BPL += [a for a in (CHKA, CHKB) if a >= 0]
CRR = [int(x, 16) for x in os.environ['CRASH'].split(',')] if os.environ.get('CRASH') else None   # CRASH=lo,hi: stop when PC gets there
BPS = {}                                # BPSET=pc:addr=val,... (a write when PC gets there)
for it in os.environ.get('BPSET', '').split(','):
    if it:
        pc_, av = it.split(':'); a_, v_ = av.split('='); BPS.setdefault(int(pc_, 16), []).append((int(a_, 16), int(v_, 16)))
for a in BPL: m.set_breakpoint(a)
if TXS: m.set_breakpoint(TXS[0])
if CRR:
    for a in range(CRR[0], CRR[1]): m.set_breakpoint(a)
for a in BPS: m.set_breakpoint(a)
FIXA = {int(x.split(':')[0], 16): int(x.split(':')[1], 16) for x in os.environ.get('FIXA', '').split(',') if x}   # FIXA=PC:A,..: A set there (LD A,R's randomness out)
for a in FIXA: m.set_breakpoint(a)
if DRWL >= 0: m.set_breakpoint(DRWL)
if PLD >= 0: m.set_breakpoint(PLD)
BPHL = int(os.environ.get('BPHL', '-1'), 16)
BPT = [int(a, 16) for a in os.environ.get('BPTIME', '').split(',') if a]; BPT_S = [None]; BPT_L = []
for a in BPT: m.set_breakpoint(a)
def prof():
    # sample PC every 2000 ticks for one frame
    for i in range(70):
        m.ticks_to_stop = 2000; m.run(); k_ = (m.pc >> PSH) | ((win[3] << 20) if m.pc >= 0xC000 else ((win[1] << 20) if 0x4000 <= m.pc < 0x8000 else 0)); PROFC[k_] = PROFC.get(k_, 0) + 1
OLDT = os.environ.get('OLDT')
COV = [int(x, 16) for x in os.environ['COV'].split(',')] if os.environ.get('COV') else None   # COV=lo,hi,flag: W0 code run while (flag)
COVS = set(); COVA = [False]
def cov_arm():
    f = mem[COV[2]] != 0
    if f and not COVA[0]:
        for a in range(COV[0], COV[1]):
            if a not in COVS: m.set_breakpoint(a)
        COVA[0] = True
    elif not f and COVA[0]:
        for a in range(COV[0], COV[1]):
            if a not in COVS: m.clear_breakpoint(a)
        COVA[0] = False
DIL = [] if os.environ.get('DILOG') else None
TRH = collections.deque(maxlen=int(os.environ.get('TRACEN', '300'))); TRC = compile(os.environ['TRACEC'], 'c', 'eval') if os.environ.get('TRACEC') else None
PRON = [0]; DRN = [0, None]; DRL = []
def frame():
    global exited, frames
    if PROFON[0]: prof()
    if COV: cov_arm()
    m.ticks_to_stop = TPF
    TRF = int(os.environ.get('TRACEF', '0'))
    while True:
        if TRF and frames >= TRF:                # TRACEF=frame: the last PCs (one instruction at a time) printed at an exit
            left = m.ticks_to_stop; m.ticks_to_stop = 1; ev = m.run(); used = 1 - m.ticks_to_stop; m.ticks_to_stop = left - max(1, used)
            TRH.append('%04X/%d/%04X' % (m.pc, win[3], m.sp) + ('/w1=%d' % win[1] if os.environ.get('TRW1') else '') + ('/i%d/f%d/%04X' % (m.iff1, frames, mem[m.sp] | mem[(m.sp + 1) & 0xFFFF] << 8) if os.environ.get('TRX') else ''))
            if m.ticks_to_stop <= 0: ev |= m._TICKS_LIMIT_HIT
            if m.pc == 0 or win[3] == 0 or (TRC and eval(TRC)) or (os.environ.get('TRACEP') and frames >= int(os.environ['TRACEP'])): print('trace', ' '.join(TRH)); exited = True; return
            if os.environ.get('TRFIX') and not (ev & m._BREAKPOINT_HIT):    # TRFIX=1: the frame's end as without the trace
                if m.ticks_to_stop > 0: continue
                break
        elif PRON[0] and m.ticks_to_stop > 1000:
            left = m.ticks_to_stop; m.ticks_to_stop = 1000; ev = m.run(); left -= 1000 - m.ticks_to_stop; m.ticks_to_stop = left
            if os.environ.get('DIRUN'):
                if not m.iff1:
                    if DRN[0] == 0: DRN[1] = (frames, m.pc, win[m.pc >> 14] if m.pc >= 0x4000 else 0)
                    DRN[0] += 1
                elif DRN[0]: DRL.append((DRN[0], DRN[1], (m.pc, win[m.pc >> 14] if m.pc >= 0x4000 else 0))); DRN[0] = 0
            k_ = (win[m.pc >> 14] if m.pc >= 0x4000 else 0, m.pc) if not (os.environ.get("PROFDI") and not m.iff1) else (1000 + (win[m.pc >> 14] if m.pc >= 0x4000 else 0), m.pc); PRF[k_] = PRF.get(k_, 0) + 1
            if not (ev & m._BREAKPOINT_HIT): continue
        else: ev = m.run()
        if ev & m._BREAKPOINT_HIT:
            pc = m.pc
            if pc == 5: bdos(); continue
            if COV and COVA[0] and COV[0] <= pc < COV[1] and pc not in COVS and pc not in BPL:
                COVS.add(pc); m.clear_breakpoint(pc); continue
            if pc == BIOS + 27 and win[3] == 3: dlog.append('sel %d' % m.c); m.hl = 0x1234 if m.c < int(os.environ.get('NDRV', '2')) else 0; ret(); continue     # (CP/M's BIOS only: our code may be at that address in another page)
            if pc == 0 and (mem[1] | mem[2] << 8) != BIOS + 3: m.pc = mem[1] | mem[2] << 8; continue     # (#0000's JP changed - a warm boot caught)
            if pc == 0 or (pc == BIOS + 3 and win[3] == 3): print('exit: pc %04X sp %04X win %s stk %s' % (pc, m.sp, win, ' '.join('%04X' % (mem[(m.sp + 2 * k) & 0xFFFF] | mem[(m.sp + 2 * k + 1) & 0xFFFF] << 8) for k in range(8)))); exited = True; (print('trace', ' '.join(TRH)) if TRH else None); (open(os.environ['EXITDUMP'], 'wb').write(bytes(mem[:0x10000])) if os.environ.get('EXITDUMP') else None); print('regs af %02X bc %04X de %04X hl %04X ix %04X iy %04X i %02X' % (m.a, m.bc, m.de, m.hl, m.ix, m.iy, m.i)); return
            if pc in BPS: [setb(a, [v]) for a, v in BPS[pc]]
            if TXS and pc == TXS[0] and win[3] == 53:    # TXSTAT=line_out,cr,fmask: its groups - all 8 cells text (CM_S, TA 0) / some / none
                _cr = mem[TXS[1]]; _fm = mem[TXS[2]]; _tp = readpage(59)
                for _g in range(4):
                    if _fm >> _g & 1:
                        _n = sum(1 for _c in range(8) if _tp[0x2000 + _cr * 32 + _g * 8 + _c] and not _tp[0x1000 + _cr * 32 + _g * 8 + _c])
                        TXC[0 if _n == 8 else 1 if _n else 2] += 1
            if pc in FIXA: m.a = FIXA[pc]; (setb(0x404D, [0, 0]) if pc == int(os.environ.get('FIXS', '5DB7'), 16) else None)   # (the frame counter too: the location's randomness)
            if CRR and CRR[0] <= pc < CRR[1] and frames >= CRR[2]: print('crash: pc %04X frame %d sp %04X af %04X bc %04X de %04X hl %04X ix %04X win %s stk %s' % (pc, frames, m.sp, m.a << 8, m.bc, m.de, m.hl, m.ix, win, ' '.join('%04X' % (mem[(m.sp - 8 + 2 * k) & 0xFFFF] | mem[(m.sp - 7 + 2 * k) & 0xFFFF] << 8) for k in range(16)))); exited = True; return
            if pc == CHKA and win[1] == 30: CHKS[0] = readpage(28) + readpage(29); CHKS[1] = frames
            if pc == CHKB and win[1] in (30, 31):
                if CHKS[0] is not None:
                    nb = readpage(28) + readpage(29); dd = sum(1 for i in range(len(nb)) if nb[i] != CHKS[0][i])
                    CHKS[2] += 1
                    print('CHK diff %d frame %d' % (dd, frames)) if dd else print('CHK ok frame %d' % frames)
                    CHKS[0] = None
            if pc == PLD:
                PLDN[0] += 1; open(os.path.join(outdir, 'pl%03d.bin' % PLDN[0]), 'wb').write(bytes(readpage(28) + readpage(29))); (open(os.path.join(outdir, 'w0%03d.bin' % PLDN[0]), 'wb').write(bytes(mem[:0x4000])) if os.environ.get('PLW0') else None); print('pldump %d frame %d' % (PLDN[0], frames))
            if pc == DRWL and win[1] in (30, 31, 62): print('drw %d %s' % (frames, bytes(mem[(m.sp + 2 + i) & 0xFFFF] for i in range(10)).hex()))
            if pc in BPL and pc not in (CHKA, CHKB) and (not BPCOND or eval(BPCOND)): print('hit %04X ix %04X:%s frame %d tick %d sp %04X a %02X hl %04X de %04X bc %04X w3 %s ix4 %04X ix6 %04X ix8 %04X' % (pc, m.ix, bytes(mem[m.ix:m.ix+8]).hex(), frames, TPF - m.ticks_to_stop, m.sp, m.a, m.hl, m.de, m.bc, win, mem[(m.ix+4)&0xFFFF] | mem[(m.ix+5)&0xFFFF] << 8, mem[(m.ix+6)&0xFFFF] | mem[(m.ix+7)&0xFFFF] << 8, mem[(m.ix+8)&0xFFFF] | mem[(m.ix+9)&0xFFFF] << 8), ' '.join('%04X' % (mem[w] | mem[w + 1] << 8) for w in BPW), 'stk', ' '.join('%04X' % (mem[(m.sp + 2 * k) & 0xFFFF] | mem[(m.sp + 2 * k + 1) & 0xFFFF] << 8) for k in range(int(os.environ.get('BPSTK', '0')))))
            if pc in BPT:
                t = frames * TPF + TPF - m.ticks_to_stop
                if pc == BPT[0]: BPT_S[0] = t
                elif BPT_S[0] is not None: BPT_L.append(t - BPT_S[0]); BPT_S[0] = None
            if pc in BPC and (pc != BPHL or 0xC0 <= m.h < 0xDB): k = (pc, mem[m.sp] | mem[(m.sp + 1) & 0xFFFF] << 8); BPC[pc][k] = BPC[pc].get(k, 0) + 1
            m.step_over_breakpoint()
            continue
        if (ev & m._END_OF_FRAME) and not (ev & m._TICKS_LIMIT_HIT) and m.ticks_to_stop > 0 and not OLDT: continue   # (the library's own 100000-T frame: not ours)
        break
    frames += 1
    if DIL is not None and not m.iff1: DIL.append((frames, m.pc, win[3]))
    if os.environ.get('INTLOG') and int(os.environ['INTLOG'].split(',')[0]) <= frames <= int(os.environ['INTLOG'].split(',')[1]): print('int %d dis %s pc %04X iff1 %d sp %04X w %s i %02X vec %04X' % (frames, m.int_disabled, m.pc, m.iff1, m.sp, win, m.i, mem[(m.i << 8) | 0xFF] | mem[((m.i << 8) + 0x100) & 0xFFFF] << 8))
    _pc0 = m.pc; m.on_handle_active_int()
    if os.environ.get('INTLOG') and int(os.environ['INTLOG'].split(',')[0]) <= frames <= int(os.environ['INTLOG'].split(',')[1]): print('  after pc %04X (was %04X) sp %04X' % (m.pc, _pc0, m.sp))

ZXP = [(0, 0, 0), (0, 0, 192), (192, 0, 0), (192, 0, 192), (0, 192, 0), (0, 192, 192), (192, 192, 0), (192, 192, 192),
       (0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]
scr2 = [0]; FL = []
EP = list(ZXP); PEN = [False, 0]                # the EGA palette as set through #BD77 / border / #FF
def shot_zx(name):
    sc = readpage(5)
    img = Image.new('RGB', (320, 200)); P = img.load()
    for y in range(192):
        a = ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for x in range(256):
            b = sc[a + (x >> 3)]; at = sc[0x1800 + (y >> 3) * 32 + (x >> 3)]; br = 8 if at & 64 else 0
            c = ((at & 7) | br) if b & (0x80 >> (x & 7)) else (((at >> 3) & 7) | br)
            P[x + 32, y + 4] = ZXP[c]
    img.resize((960, 600), Image.NEAREST).save(os.path.join(outdir, name + '.png'))
def txmap(name):                    # TXMAP=1: screen 7's text map (CM_S, TA_S) against screen 7's pixels at each shot
    tp = readpage(59); s7 = readpage(15); gf = tp[0x2800:0x2C00]
    def cell(r, c): return bytes(s7[((r & 0x18) << 8) | (l << 8) | ((r & 7) << 5) | c] for l in range(8))
    def gl(ch, ta):
        g = gf[8 * ch:8 * ch + 8]
        if ta == 0: return bytes(g)
        h = g[:4] if ta == 1 else g[4:]
        return bytes(v for v in h for _ in (0, 1))
    pats = {}
    for ch in range(128):
        for ta in (0, 1, 2):
            p = gl(ch, ta)
            if len(set(p)) > 1: pats.setdefault(p, (ch + 1, ta)); pats.setdefault(bytes(255 - v for v in p), (ch + 1, ta))
    ok = blank = pic = miss = 0; L = []
    for r in range(24):
        for c in range(32):
            x = cell(r, c); m = tp[0x2000 + r * 32 + c]; ta = tp[0x1000 + r * 32 + c]
            if m:
                if ta == 3: ok += 1; continue
                g = gl(m - 1, ta)
                if x == g or x == bytes(255 - v for v in g): ok += 1
                elif len(set(x)) == 1: blank += 1; L.append('b%d,%d' % (r, c))
                else: pic += 1; L.append('%d,%d' % (r, c))
            elif x in pats: miss += 1; L.append('m%d,%d' % (r, c))
    if ZXS:
        W = collections.Counter()
        for it in L:
            if it[0] in 'mb': continue
            r, c = map(int, it.split(','))
            for l in range(8): W[ZXS[15][((r & 0x18) << 8) | (l << 8) | ((r & 7) << 5) | c]] += 1
        print('txmapw', name, ' '.join('%04X/%d:%d' % (t & 0xFFFF, t >> 16, n) for t, n in W.most_common(8)))
    print('txmap', name, 'ok', ok, 'stale_blank', blank, 'stale_other', pic, 'missing', miss, ' '.join(sorted(L, key=lambda t: t[0] != 'b')[:40]))
def shot(name):
    if mode[0] == 'zx': return shot_zx(name)
    if mode[0] == 'hires':
        p5 = readpage(5); p1 = readpage(1)
        img = Image.new('RGB', (640, 200)); P = img.load()
        for y in range(200):
            for col in range(80):
                o = y * 40 + (col >> 1) + (0x2000 if col & 1 else 0); b = p5[o]; at = p1[o]
                ink = (at & 7) | (8 if at & 64 else 0); pap = ((at >> 3) & 7) | (8 if at & 128 else 0)
                for k in range(8): P[col * 8 + k, y] = ZXP[ink if b & (128 >> k) else pap]
        img.resize((1280, 600), Image.NEAREST).save(os.path.join(outdir, name + '.png')); return
    p1 = readpage(3 if scr2[0] else 1); p5 = readpage(7 if scr2[0] else 5)
    img = Image.new('RGB', (320, 200)); P = img.load()
    for y in range(200):
        for k in range(160):
            g = k & 3; o = y * 40 + (k >> 2) + (0x2000 if g >= 2 else 0)
            b = (p1 if g in (0, 2) else p5)[o]
            l = (b & 7) | ((b >> 3) & 8); r = ((b >> 3) & 7) | ((b >> 4) & 8)
            P[k * 2, y] = EP[l]; P[k * 2 + 1, y] = EP[r]
    img.resize((960, 600), Image.NEAREST).save(os.path.join(outdir, name + '.png'))
    if os.environ.get('TXMAP'): txmap(name)
    if ZXT:
        t1 = ZXT[3 if scr2[0] else 1]; t5 = ZXT[7 if scr2[0] else 5]; n = npat = 0; Q = img.copy().load()
        for y in range(200):
            for k in range(160):
                g = k & 3; o = y * 40 + (k >> 2) + (0x2000 if g >= 2 else 0)
                if (t1 if g in (0, 2) else t5)[o]:
                    n += 1; fl = Q[k * 2, y] == Q[k * 2 + 1, y] and (k == 0 or Q[k * 2 - 1, y] == Q[k * 2, y] or not lt)
                    if not fl: npat += 1
                    P[k * 2, y] = P[k * 2 + 1, y] = (110, 0, 110) if fl else (255, 0, 255)
                else:
                    for x in (k * 2, k * 2 + 1): c = P[x, y]; P[x, y] = (c[0] // 3, c[1] // 3, c[2] // 3)
                lt = (t1 if g in (0, 2) else t5)[o]
        img.resize((960, 600), Image.NEAREST).save(os.path.join(outdir, name + '_z.png')); print('zx', name, n, 'pattern', npat)
        if ZXS:
            cp = collections.Counter(); ca = collections.Counter()
            for y in range(4, 196):
                zy = y - 4
                for k in range(128):
                    g = k & 3; o = y * 40 + (k >> 2) + (0x2000 if g >= 2 else 0)
                    if (t1 if g in (0, 2) else t5)[o]:
                        cx = k >> 2; cp[ZXS[15][((zy & 0xC0) << 5) | ((zy & 7) << 8) | ((zy & 0x38) << 2) | cx]] += 1
                        ca[ZXS[15][0x1800 + (zy >> 3) * 32 + cx]] += 1
            print('zxsrc', name, 'pix', ' '.join('%04X/%d:%d' % (t & 0xFFFF, t >> 16, c) for t, c in cp.most_common(25)))
            print('zxsrc', name, 'atr', ' '.join('%04X/%d:%d' % (t & 0xFFFF, t >> 16, c) for t, c in ca.most_common(15)))
        if ZXW:
            x0, y0, x1, y1 = (int(v) for v in os.environ['ZXWHO'].split(',')); cw = collections.Counter()
            for y in range(y0, y1):
                for k in range(x0 // 2, x1 // 2):
                    g = k & 3; o = y * 40 + (k >> 2) + (0x2000 if g >= 2 else 0); pg = (3 if scr2[0] else 1) if g in (0, 2) else (7 if scr2[0] else 5)
                    v = ZXW[pg][o]; cw[(v & 0xFFFF, (v >> 16) & 0xFF, v >> 24, ZXT[pg][o])] += 1
            print('zxwho', name, ' '.join('%04X/%d@%d%s:%d' % (k[0], k[1], k[2], 'z' if k[3] else '', c) for k, c in cw.most_common(20)))

WPG = [int(x, 16) for x in os.environ.get('WPG', '').split(':') if x]
def wpgv():
    pg, a = WPG
    for w in range(4):
        if win[w] == pg: return mem[w * 0x4000 + a]
    return pages[pg][a]
def wait_ctx(stub=False):        # step until the game halts with its own windows (not in an interrupt)
    last = wpgv() if WPG else None; hist = collections.deque(maxlen=24)
    for k in range(3000000):
        if WPG:
            hist.append(m.pc); v = wpgv()
            if v != last: print('wpg %02X -> %02X frame %d win %s pcs %s stk %s' % (last, v, frames, win, ' '.join('%04X' % x for x in hist), ' '.join('%04X' % (mem[(m.sp + 2 * j) & 0xFFFF] | mem[(m.sp + 2 * j + 1) & 0xFFFF] << 8) for j in range(10)))); last = v
        if win[1] == 13 and win[2] == 10 and m.halted and (0x4000 <= m.pc < 0xC000 or 0x3D80 <= m.pc < 0x3D84): return
        m.ticks_to_stop = 1; ev = m.run()
        if ev & m._BREAKPOINT_HIT:
            if m.pc == 5: bdos()
            else:
                if m.pc in BPL: print('whit %04X w3 %d hl %04X de %04X bc %04X a %02X ix4 %04X ix6 %04X' % (m.pc, win[3], m.hl, m.de, m.bc, m.a, mem[(m.ix+4)&0xFFFF] | mem[(m.ix+5)&0xFFFF] << 8, mem[(m.ix+6)&0xFFFF] | mem[(m.ix+7)&0xFFFF] << 8))
                m.step_over_breakpoint()
    print('wait_ctx: no')

for line in open(scriptf):
    t = line.split()
    if not t or t[0].startswith('#'): continue
    if exited: print('exited'); break
    c = t[0]
    if c == 'wait':
        for i in range(int(t[1])):
            frame()
            if exited: break
    elif c == 'key':
        zxkeys.add(t[1])
        for i in range(int(t[2]) if len(t) > 2 else 5): frame()
        zxkeys.discard(t[1]); frame(); frame()
    elif c == 'keys':           # keys K1+K2.. [frames]: held together
        ks = t[1].split('+'); [zxkeys.add(k) for k in ks]
        for i in range(int(t[2]) if len(t) > 2 else 5): frame()
        [zxkeys.discard(k) for k in ks]; frame(); frame()
    elif c == 'mouse':
        dx, dy = int(t[1]), int(t[2]); b = int(t[3]) if len(t) > 3 else 0
        steps = max(1, max(abs(dx), abs(dy)) // 4)
        for i in range(steps):
            mx += dx // steps; my -= dy // steps; frame()
        if b: mb = 0xFE; frame(); frame(); frame(); mb = 0xFF; frame()
    elif c == 'goto':           # ZX coordinates; the game keeps the cursor at #465B (x), #465C (y)
        tx, ty = int(t[1]), int(t[2])
        for it in range(40):
            GC = int(os.environ.get('GCOORD', '465B'), 16) - 0x4000; cx = readpage(13)[GC]; cy = readpage(13)[GC + 1]
            dx = tx - cx; dy = ty - cy
            if dx == 0 and dy == 0: break
            mx += max(-30, min(30, dx)); my -= max(-30, min(30, dy)); frame(); frame()
    elif c == 'watch':          # watch ADDR STEPS [press]: step, print PC when the byte (page 13) changes
        a = int(t[1], 16); last = readpage(13)[a - 0x4000]; hist = []
        if len(t) > 3: mb = 0xFE
        for k in range(int(t[2])):
            hist.append(m.pc); hist = hist[-12:]
            m.ticks_to_stop = 1; ev = m.run()
            if ev & m._BREAKPOINT_HIT:
                if m.pc == 5: bdos()
                else: m.step_over_breakpoint()
            if k % 25000 == 24999: m.on_handle_active_int()
            if k == 100000: mb = 0xFF
            v = readpage(13)[a - 0x4000] if win[1] == 13 else last
            if v != last: print('watch %02X -> %02X at step %d pcs %s' % (last, v, k, ' '.join('%04X' % x for x in hist))); last = v
    elif c == 'pgwt':           # pgwt PAGE OFF FRAMES: in slices of 40 T: the PC, W3, stack where that page's byte changed
        pg, a = int(t[1]), int(t[2], 16)
        def pgv3():
            for w in range(4):
                if win[w] == pg: return mem[w * 0x4000 + a]
            return pages[pg][a]
        last = pgv3()
        for k in range(int(t[3])):
            left = TPF; hist = collections.deque(maxlen=8)
            while left > 0:
                m.ticks_to_stop = min(40, left); before = m.ticks_to_stop
                ev = m.run()
                left -= before - m.ticks_to_stop
                if ev & m._BREAKPOINT_HIT:
                    if m.pc == 5: bdos()
                    else: m.step_over_breakpoint()
                hist.append(m.pc)
                v = pgv3()
                if v != last: print('pgwt %02X -> %02X frame %d pcs %s w %s sp %04X stk %s' % (last, v, frames, ' '.join('%04X' % x for x in hist), win, m.sp, ' '.join('%04X' % (mem[(m.sp + 2 * j) & 0xFFFF] | mem[(m.sp + 2 * j + 1) & 0xFFFF] << 8) for j in range(10)))); last = v
                if (ev & m._END_OF_FRAME) and not (ev & m._TICKS_LIMIT_HIT) and m.ticks_to_stop > 0: pass
            frames += 1; m.on_handle_active_int()
    elif c == 'pgwf':           # pgwf PAGE OFF FRAMES: frame by frame, print the frames where that page's byte changed
        pg, a = int(t[1]), int(t[2], 16)
        def pgv2():
            for w in range(4):
                if win[w] == pg: return mem[w * 0x4000 + a]
            return pages[pg][a]
        last = pgv2(); print('pgwf start %02X frame %d win %s' % (last, frames, win))
        for k in range(int(t[3])):
            frame(); v = pgv2()
            if v != last: print('pgwf %02X -> %02X frame %d' % (last, v, frames)); last = v
        print('pgwf end %02X' % pgv2())
    elif c == 'pgw':            # pgw PAGE OFF STEPS: step, print frame, PCs, W3 when that page's byte changes
        pg, a = int(t[1]), int(t[2], 16); hist = collections.deque(maxlen=16)
        def pgv():
            for w in range(4):
                if win[w] == pg: return mem[w * 0x4000 + a]
            return pages[pg][a]
        last = pgv()
        for k in range(int(t[3])):
            hist.append(m.pc)
            m.ticks_to_stop = 1; ev = m.run()
            if ev & m._BREAKPOINT_HIT:
                if m.pc == 5: bdos()
                else: m.step_over_breakpoint()
            if m.halted or k % 25000 == 24999: m.on_handle_active_int()
            v = pgv()
            if v != last: print('pgw %02X -> %02X step %d frame %d w3 %d ix %04X stk %s pcs %s' % (last, v, k, frames, win[3], m.ix, ' '.join('%04X' % (mem[(m.sp + 2 * j) & 0xFFFF] | mem[(m.sp + 2 * j + 1) & 0xFFFF] << 8) for j in range(8)), ' '.join('%04X' % x for x in hist))); last = v
    elif c == 'rp': a = int(t[1], 16); print('rp', t[1], readpage(13)[a - 0x4000:a - 0x4000 + int(t[2])].hex(), 'oldbtn/svc', bytes(mem[0x9B6:0x9BA]).hex())
    elif c == 'prof': PROFON[0] = 1; PROFC.clear()
    elif c == 'prof2': PRON[0] = 1
    elif c == 'prof2off': PRON[0] = 0
    elif c == 'prof2dump':       # prof2dump NAME: the samples so far -> NAME.txt in the output folder, cleared
        open(os.path.join(outdir, t[1] + '.txt'), 'w').write('\n'.join('%d %d %04X' % (n, k[0], k[1]) for k, n in sorted(PRF.items(), key=lambda x: -x[1]))); PRF.clear()
    elif c == 'conkey': keyq.append(int(t[1], 16))   # conkey HH: a key for BDOS 6
    elif c == 'press': mb = 0xFE
    elif c == 'release': mb = 0xFF
    elif c == 'mclick':         # the middle button (Kempston D2)
        mb = 0xFB
        for i in range(8): frame()
        mb = 0xFF
        for i in range(8): frame()
    elif c == 'rclick':         # the right button (Kempston D1)
        mb = 0xFD
        for i in range(8): frame()
        mb = 0xFF
        for i in range(8): frame()
    elif c == 'click':
        mb = 0xFE
        for i in range(8): frame()
        mb = 0xFF
        for i in range(8): frame()
    elif c == 'set':            # set REG VALUE (hex): a b c d e h l hl de bc
        pend.append((t[1], int(t[2], 16)))
    elif c == 'dlog': print('disk', len(dlog), dlog[:6], dlog[-4:]); dlog.clear()
    elif c == 'trace':          # trace N: N instructions, PCs printed (ours and the game's)
        out = []
        for k in range(int(t[1])):
            out.append('%04X' % m.pc); m.ticks_to_stop = 1; ev = m.run()
            if ev & m._BREAKPOINT_HIT:
                if m.pc == 5: bdos()
                else: m.step_over_breakpoint()
        print(' '.join(out))
    elif c == 'wwatch':         # wwatch ADDR: step until the byte at ADDR (as mapped now) changes; last PCs
        a = int(t[1], 16); last = mem[a]; hist = collections.deque(maxlen=40)
        for k in range(30000000):
            hist.append('%04X/%04X' % (m.pc, m.sp))
            m.ticks_to_stop = 1; ev = m.run()
            if ev & m._BREAKPOINT_HIT:
                if m.pc == 5: bdos()
                else: m.step_over_breakpoint()
            if m.halted or k % 25000 == 24999: m.on_handle_active_int()
            if mem[a] != last: break
        print('wwatch %02X -> %02X step %d' % (last, mem[a], k), ' '.join(hist), 'win', win, 'hl %04X de %04X bc %04X' % (m.hl, m.de, m.bc))
    elif c == 'pwatch':         # pwatch: step until page 63's first byte (seen in W3) changes; last PCs
        last = None; hist = collections.deque(maxlen=60)
        for k in range(30000000):
            hist.append('%04X/%04X/%d' % (m.pc, m.sp, win[3]))
            m.ticks_to_stop = 1; ev = m.run()
            if ev & m._BREAKPOINT_HIT:
                if m.pc == 5: bdos()
                else: m.step_over_breakpoint()
            if m.halted or k % 25000 == 24999: m.on_handle_active_int()
            if win[3] == 63:
                if last is not None and mem[0xC000] != last: break
                last = mem[0xC000]
        print('pwatch', last, mem[0xC000], 'step', k, ' '.join(hist), 'win', win)
    elif c == 'pcall':          # pcall ADDR [A]: run to ADDR (with A, if given), then count PCs until it returns
        a = int(t[1], 16); wa = int(t[2], 16) if len(t) > 2 else None
        for k in range(50000000):
            if m.pc == a and (wa is None or m.a == wa) and (not os.environ.get('PCW') or mem[int(os.environ['PCW'], 16)]): break
            m.ticks_to_stop = 1; ev = m.run()
            if ev & m._BREAKPOINT_HIT:
                if m.pc == 5: bdos()
                else: m.step_over_breakpoint()
            if m.halted or k % 25000 == 24999: m.on_handle_active_int()
        sp0 = m.sp; H = {}; n = 0; t0 = m.frame_tick
        while True:
            H[m.pc] = H.get(m.pc, 0) + 1; n += 1
            m.ticks_to_stop = 1; ev = m.run()
            if ev & m._BREAKPOINT_HIT: m.step_over_breakpoint()
            if m.sp > sp0 or n > 2000000: break
        open(os.path.join(outdir, 'pcall.txt'), 'w').write('\n'.join('%04X %d' % kv for kv in sorted(H.items())))
        print('pcall %04X: %d instructions, ticks %d' % (a, n, m.frame_tick - t0))
    elif c == 'span':           # span START END: run to START (PCW: and that byte non-zero), then count PCs until END
        a, e = int(t[1], 16), int(t[2], 16)
        for k in range(50000000):
            if m.pc == a and (not os.environ.get('PCW') or mem[int(os.environ['PCW'], 16)]): break
            m.ticks_to_stop = 1; ev = m.run()
            if ev & m._BREAKPOINT_HIT:
                if m.pc == 5: bdos()
                else: m.step_over_breakpoint()
            if m.halted or k % 25000 == 24999: m.on_handle_active_int()
        H = {}; n = 0; T = 0; print('span start frame', frames)
        while m.pc != e and n < 5000000:
            H[m.pc] = H.get(m.pc, 0) + 1; n += 1
            t0 = m.frame_tick; m.ticks_to_stop = 1; ev = m.run(); dt = (m.frame_tick - t0) % TPF; T += dt
            if ev & m._BREAKPOINT_HIT: m.step_over_breakpoint()
        open(os.path.join(outdir, 'pcall.txt'), 'w').write('\n'.join('%04X %d' % kv for kv in sorted(H.items())))
        print('span %04X-%04X: %d instructions, ticks %d, end frame %d' % (a, e, n, T, frames))
    elif c == 'at':             # at X Y: our mouse cursor (scx, scy from the layer's symbols ATSYM) to X, Y
        if 'scx' not in ATS:
            for l in open(os.environ.get('ATSYM', os.path.join(os.path.dirname(os.path.abspath(__file__)), '../build/out/zxl_sym.txt'))):
                f = l.split(':')
                if f[0] in ('scx', 'scy'): ATS[f[0]] = int(l.split('0x')[1], 16)
        wait_ctx(); x, y = int(t[1]), int(t[2])
        setb(ATS['scx'], [x & 255, x >> 8]); setb(ATS['scy'], [y])
    elif c == 'gcall':          # gcall ADDR: (fights, interrupts off) at the game's code, call ADDR and run until it returns
        a = int(t[1], 16)
        for k in range(20000000):
            if 0x4000 <= m.pc < 0xC000 and win[1] == 13 and not m.iff1: break
            m.ticks_to_stop = 1; ev = m.run()
            if ev & m._BREAKPOINT_HIT:
                if m.pc == 5: bdos()
                else: m.step_over_breakpoint()
        ret, sp0 = m.pc, m.sp; m.sp = (m.sp - 2) & 0xFFFF; setb(m.sp, [ret & 255, ret >> 8]); m.pc = a
        if len(t) > 2: m.a = int(t[2], 16)          # gcall ADDR A
        T = 0; GH.clear(); GST[0] = 0
        for k in range(50000000):
            if m.pc == ret and m.sp == sp0: break
            pc0 = m.pc; t0 = m.frame_tick; m.ticks_to_stop = 1; ev = m.run(); dt = (m.frame_tick - t0) % TPF; T += dt
            if GSP and GSP[0] <= pc0 < GSP[1]: GST[0] += dt; GH[pc0] = GH.get(pc0, 0) + dt
            if ev & m._BREAKPOINT_HIT:
                if m.pc == 5: bdos()
                else: m.step_over_breakpoint()
        print('gcall %04X from %04X steps %d ticks %d win %s' % (a, ret, k, T, win), 'gspan', GST[0])
        if GSP: open(os.path.join(outdir, 'ghist.txt'), 'w').write('\n'.join('%04X %d' % kv for kv in sorted(GH.items())))
    elif c == 'until':          # until LO HI: step until PC in [LO, HI), show the last PCs
        lo, hi = int(t[1], 16), int(t[2], 16); hist = collections.deque(maxlen=int(os.environ.get('UHIST', '60'))); prevpc = 0; JMPS = os.environ.get('JMPS')
        upg = int(t[3]) if len(t) > 3 else None          # until LO HI PAGE: only with W3 = PAGE
        USP = int(os.environ.get('USP', '10000'), 16); USPL = int(os.environ.get('USPL', '0'), 16)     # USP=hex: only with SP below it (USPL: not below that)
        for k in range(20000000):
            if lo <= m.pc < hi and (upg is None or win[3] == upg) and USPL <= m.sp < USP: break
            if not JMPS or not (0 < m.pc - prevpc <= 4): hist.append('%04X>%04X/%04X' % (prevpc, m.pc, m.sp) if JMPS else '%04X' % m.pc)
            prevpc = m.pc
            m.ticks_to_stop = 1; ev = m.run()
            if ev & m._BREAKPOINT_HIT:
                if lo <= m.pc < hi and (upg is None or win[3] == upg) and USPL <= m.sp < USP: break
                if m.pc == 5: bdos()
                else: m.step_over_breakpoint()
            if m.halted or k % 25000 == 24999: m.on_handle_active_int()
        print('until: step', k, ' '.join(hist), 'win', win)
    elif c == 'pdump' and len(t) == 2:          # pdump FILE: all 64 RAM pages (as now) into FILE
        open(t[1], 'wb').write(b''.join(bytes(readpage(k)) for k in range(64)))
    elif c == 'mem':            # mem ADDR LEN: memory as mapped now, no waiting
        a = int(t[1], 16); print('mem %04X' % a, bytes(mem[a:a + int(t[2])]).hex(), 'win', win, 'pc %04X sp %04X' % (m.pc, m.sp))
    elif c == 'pokeh':          # pokeh ADDR HEXBYTES: memory as mapped now
        setb(int(t[1], 16), bytes.fromhex(t[2]))
    elif c == 'pokef':          # pokef ADDR LEN BYTE: memory as mapped now, no waiting
        a = int(t[1], 16); setb(a, [int(t[3], 16)] * int(t[2], 16))
    elif c == 'ppoke':          # ppoke PAGE OFF BYTE (hex): a page's byte, wherever it's mapped
        p_, o_, v_ = int(t[1]), int(t[2], 16), int(t[3], 16)
        for w in range(4):
            if win[w] == p_: setb(w * 0x4000 + o_, [v_])
        pages[p_][o_] = v_
    elif c == 'fill':           # fill ADDR LEN BYTE (game memory, at a HALT)
        wait_ctx()
        a = int(t[1], 16); setb(a, [int(t[3], 16)] * int(t[2], 16))
    elif c == 'pc': print('hl %04X de %04X bc %04X a %02X' % (m.hl, m.de, m.bc, m.a)); print('pc %04X sp %04X iff1 %d halted %d i %02X win %s frame %d' % (m.pc, m.sp, m.iff1, m.halted, m.i, win, frames))
    elif c == 'jump': m.pc = int(t[1], 16)
    elif c == 'gdump':          # gdump FILE: game memory #4000-#BFFF from its pages (13 = bank 5, 10 = bank 2)
        open(os.path.join(outdir, t[1]), 'wb').write(readpage(13) + readpage(10))
    elif c == 'pdump':          # pdump PAGE FILE
        open(os.path.join(outdir, t[2]), 'wb').write(readpage(int(t[1])))
    elif c == 'dump':           # dump ADDR LEN FILE (memory as the game sees it)
        wait_ctx()
        a = int(t[1], 16); open(os.path.join(outdir, t[3]), 'wb').write(bytes(mem[a:a + int(t[2], 16)]))
    elif c == 'call':           # call ADDR at a HALT of the game (or of our stub); returns into a stub EI:HALT:JR
        wait_ctx()
        print('call from %04X sp %04X bank %d' % (m.pc, m.sp, win[3] - 8))
        setb(0x3D80, [0xFB, 0x76, 0x18, 0xFC])
        m.halted = 0
        for r, v in pend: setattr(m, r, v)
        pend.clear()
        sp = (m.sp - 2) & 0xFFFF; mem[sp] = 0x80; mem[sp + 1] = 0x3D; m.sp = sp; m.pc = int(t[1], 16)
    elif c == 'shot': shot(t[1]); (open(os.path.join(outdir, 'pl_%s.bin' % t[1]), 'wb').write(bytes(readpage(28) + readpage(29))) if os.environ.get('PLSHOT') else None); print('shot', t[1], 'mode', mode[0], 'pc %04X' % m.pc, 'win', win)
    elif c == 'peek':
        wait_ctx()
        a = int(t[1], 16); print(t[1], bytes(mem[a:a + int(t[2])]).hex(' '), 'pc %04X' % m.pc, win, bytes(pages[13][a-0x4000:a-0x4000+4]).hex())
    elif c == 'log':
        print('frames', frames, 'console', bytes(console)); console.clear(); print(' '.join(plog[-10:]))
[print('bp %04X' % a, frames, sorted(['%04X:%d' % (k[1], v) for k, v in d.items()])) for a, d in BPC.items()]
print('time', len(BPT_L), 'sum', sum(BPT_L), 'avg', sum(BPT_L[-200:]) // max(1, len(BPT_L[-200:])), 'max', max(BPT_L[-200:] or [0]), BPT_L[-int(os.environ.get('BPTALL', '0')):] if os.environ.get('BPTALL') else '') if BPT else None
(open(os.environ['DIDUMP'],'w').write(repr(DIL)) if os.environ.get('DIDUMP') and DIL is not None else None); (print('di at int', len(DIL), 'after', sum(1 for f, p, w in DIL if f > int(os.environ.get('DIFROM', '0'))), [(f, '%04X' % p, w) for f, p, w in DIL if f > int(os.environ.get('DIFROM', '0'))][:60]) if DIL is not None else None); (open(os.environ['AYDUMP'], 'w').write(repr(AYA)) if os.environ.get('AYDUMP') else None); print('ay amplA writes', len(AYA), 'frames', len(set(f for f, v in AYA)), 'first', AYA[:3], 'last', AYA[-3:], 'nonzero', sum(1 for f, v in AYA if v & 15)); print('flips', len(FL), FL if os.environ.get('FLALL') else FL[-12:])
(open(os.path.join(outdir, 'cov.txt'), 'w').write('\n'.join('%04X' % a for a in sorted(COVS))) if COV else None)
(print('stack low %04X' % STKM[0]) if os.environ.get('STKW') else None)
print('palette', [i for i in range(16) if EP[i] != ZXP[i]], [EP[i] for i in range(16) if EP[i] != ZXP[i]]); print('console tail', bytes(console[-80:])); print('disk at end', len(dlog), dlog[:3], dlog[-3:]); print('prof', sorted(PROFC.items(), key=lambda x: -x[1])[:int(os.environ.get('PTOP', '12'))]) if PROFC else None; (print('txstat all/some/none', TXC) if TXS else None); print('done, frames', frames, 'pc %04X' % m.pc, 'win', win)
if os.environ.get('PGUSE'): print('pguse', ' '.join('%d:%d' % (k, 16384 - readpage(k).count(0)) for k in range(64)))
if os.environ.get('DUMPP'):
    [open(os.path.join(outdir, 'pg%d.bin' % k), 'wb').write(readpage(k)) for k in (1, 3, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 26, 27, 28, 29, 30, 31, 53, 55, 58, 59, 61, 62, 63)]
    open(os.path.join(outdir, 'p1.bin'), 'wb').write(readpage(3 if scr2[0] else 1)); open(os.path.join(outdir, 'p5.bin'), 'wb').write(readpage(7 if scr2[0] else 5))
    open(os.path.join(outdir, 'p15.bin'), 'wb').write(readpage(15)); open(os.path.join(outdir, 'w0.bin'), 'wb').write(bytes(mem[0:0x4000]))
if WCN: open(os.path.join(outdir, 'wcount.txt'), 'w').write('\n'.join('%d %04X %d %d %02X' % (n, k[0], k[1], k[2], k[3]) for k, n in sorted(WCN.items(), key=lambda x: -x[1])))
if os.environ.get('RWATCH'): open(os.path.join(outdir, 'rwatch.txt'), 'w').write('\n'.join('%d %d %04X' % (n, k[1], k[0]) for k, n in sorted(RWC.items(), key=lambda x: -x[1])))
if DRL: print('di runs', sorted(DRL, reverse=True)[:25])
if PRF: open(os.path.join(outdir, 'prof2.txt'), 'w').write('\n'.join('%d %d %04X' % (n, k[0], k[1]) for k, n in sorted(PRF.items(), key=lambda x: -x[1])))
