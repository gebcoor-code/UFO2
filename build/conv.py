# ASM80 (UFO-2 sources, cp866) -> sjasmplus.
#   python3 conv.py SRCDIR OUTDIR ROOT.A80
# ASM80 rules kept: labels have 6 significant characters (case-sensitive); expressions are evaluated left to right
# (no precedence: A-B/256 = (A-B)/256); '?' = remainder; macros 'NAME MAC' with parameters =0..=9;
# *F file (include), *B file (binary), *Pn (page n at #C000), DISP/ENDD, DEFR (random fill), DEFS n,b.
import sys, os, re

SRC, OUT, ROOT = sys.argv[1:4]
os.makedirs(OUT, exist_ok=True)
files = {f.upper(): f for f in os.listdir(SRC)}

def find(name):
    n = name.strip().upper()
    if not n.endswith('.A80'): n += '.A80'
    return files.get(os.path.basename(n))

def read(fn):
    return open(os.path.join(SRC, fn), 'rb').read().decode('cp866').replace('\r', '').split('\n')

def split_comment(s):
    q = None
    for i, ch in enumerate(s):
        if q:
            if ch == q: q = None
        elif ch in '"':
            q = ch
        elif ch == "'" and i + 2 < len(s) and s[i + 2] == "'":
            q = ch
        elif ch == ';':
            return s[:i], s[i:]
    return s, ''

LABRE = re.compile(r'^([A-Za-z_$?@][A-Za-z0-9_$?@.#]*)')
def key(name): return name[:6]
def sanit(name): return name.replace('$', '_S').replace('?', '_Q').replace('@', '_A').replace('.', '_P').replace('#', '_H')

# ---- pass 1: the include tree, labels, macros
order = []; labels = {}; macros = {}; mparams = {}; curmac = [None]
def scan(fn):
    if fn in order: return
    order.append(fn)
    for line in read(fn):
        code, _ = split_comment(line)
        if code.startswith('*'):
            m = re.match(r'\*F\s+(\S+)', code, re.I)
            if m:
                f = find(m.group(1))
                if f: scan(f)
                else: print('missing include', m.group(1), 'in', fn)
            continue
        if curmac[0]:
            for d in re.findall(r'=(\d)', code): mparams[curmac[0]] = max(mparams[curmac[0]], int(d) + 1)
            if code.split() and code.split()[0].upper() == 'ENDM': curmac[0] = None
        m = LABRE.match(code)
        if m:
            name = m.group(1); rest = code[len(name):].split()
            if rest and rest[0].upper() == 'MAC':
                macros[key(name)] = 'm_' + sanit(key(name)); curmac[0] = key(name); mparams[key(name)] = 0
            elif rest and rest[0].upper() == 'ENDM':
                curmac[0] = None
            else:
                labels[key(name)] = 'l_' + sanit(key(name))
scan(find(ROOT))

REGS = set('A B C D E H L I R AF BC DE HL SP IX IY IXH IXL IYH IYL NZ Z NC PO PE P M'.split())

TOK = re.compile(r'''\s*(?:("[^"]*"|'[^']*')|(#[0-9A-Fa-f]+|%[01]+|[0-9]+)|([A-Za-z_@][A-Za-z0-9_$@.#]*)|(\$)|(\S))''')
def tokens(s):
    out = []; i = 0
    while i < len(s):
        m = TOK.match(s, i)
        if not m: break
        i = m.end()
        if m.group(1) is not None: out.append(('s', m.group(1)))
        elif m.group(2) is not None: out.append(('n', m.group(2)))
        elif m.group(3) is not None: out.append(('i', m.group(3)))
        elif m.group(4) is not None: out.append(('n', '$'))
        elif m.group(5) is not None: out.append(('o', m.group(5)))
    return out

def ident(t, params):
    if t in params: return params[t]
    k = key(t)
    if k in labels and t.upper() not in REGS: return labels[k]
    return t

def expr(toks, params):
    # left-to-right: ((a op b) op c) ...; parentheses groups recurse; unary +/- allowed
    def operand(i):
        kind, v = toks[i]
        if kind == 'o' and v == '(':
            depth = 0; j = i
            while j < len(toks):
                if toks[j] == ('o', '('): depth += 1
                elif toks[j] == ('o', ')'):
                    depth -= 1
                    if depth == 0: break
                j += 1
            return '(' + expr(toks[i + 1:j], params) + ')', j + 1
        if kind == 'o' and v in '+-':
            s, j = operand(i + 1); return v + s, j
        if kind == 'i': return ident(v, params), i + 1
        return v, i + 1
    if not toks: return ''
    s, i = operand(0); n = 0
    while i < len(toks):
        kind, op = toks[i]
        if op == '?': op = ' mod '
        if i + 1 >= len(toks): s = s + op; i += 1; break
        r, i = operand(i + 1)
        s = s + op + r; n += 1
        if i < len(toks): s = '(' + s + ')'
    return s

def operands(text, params, mnem):
    toks = tokens(text)
    # split by top-level commas
    parts = []; cur = []; depth = 0
    for t in toks:
        if t == ('o', '('): depth += 1
        if t == ('o', ')'): depth -= 1
        if t == ('o', ',') and depth == 0: parts.append(cur); cur = []
        else: cur.append(t)
    parts.append(cur)
    res = []
    for p in parts:
        if len(p) == 1 and p[0][0] == 's': res.append(p[0][1]); continue
        # a memory operand (expr): keep the outer parentheses
        if p and p[0] == ('o', '(') and p[-1] == ('o', ')'):
            inner = p[1:-1]; depth = 0; whole = True
            for k, t in enumerate(p):
                if t == ('o', '('): depth += 1
                if t == ('o', ')'):
                    depth -= 1
                    if depth == 0 and k != len(p) - 1: whole = False
            if whole:
                if inner and inner[0][0] == 'i' and inner[0][1].upper() in ('IX', 'IY') and len(inner) > 1:
                    res.append('(' + inner[0][1] + inner[1][1] + expr(inner[2:], params) + ')'); continue
                res.append('(' + expr(inner, params) + ')'); continue
        # register / condition / AF'
        if len(p) == 1 and p[0][0] == 'i' and p[0][1].upper() in REGS and key(p[0][1]) not in labels:
            res.append(p[0][1]); continue
        res.append(expr(p, params))
    if mnem == 'EX' and len(res) == 2 and res[0].upper() == 'AF' and res[1].upper() == 'AF': res[1] = "AF'"
    return ','.join(res)

# ---- pass 2: convert
def conv(fn):
    out = []; params = {}; inmac = False
    for line in read(fn):
        code, com = split_comment(line)
        com = com.replace('\t', ' ')
        if code.startswith('*'):
            m = re.match(r'\*([A-Za-z]\$?)\s*(\S*)', code)
            d = m.group(1).upper() if m else ''
            arg = m.group(2) if m else ''
            if d == 'F':
                out.append('\tINCLUDE "%s"' % (find(arg).lower().replace('.a80', '.asm')))
            elif d == 'B':
                out.append('\tINCBIN "data/%s"' % os.path.basename(arg.replace('\\', '/')).lower())
            elif d == 'P':
                out.append('\tSLOT 3\n\tPAGE %s' % arg[:1] if arg[:1].isdigit() else '')
            else:
                out.append(';' + code)
            continue
        m = LABRE.match(code)
        label = ''
        rest = code
        if m and code[0] not in ' \t':
            label = m.group(1); rest = code[len(label):]
        parts = rest.split(None, 1)
        mn = parts[0] if parts else ''
        ops = parts[1].strip() if len(parts) > 1 else ''
        MN = mn.upper()
        if MN == 'MAC':
            inmac = True; params = {'=%d' % k: 'p%d' % k for k in range(10)}
            np_ = mparams.get(key(label), 0)
            out.append('\tMACRO %s %s' % (macros[key(label)], ','.join('p%d' % k for k in range(np_))) + (' ' + com if com else ''))
            continue
        if MN == 'ENDM':
            inmac = False; params = {}; out.append('\tENDM'); continue
        lab = ident(label, {}) if label else ''
        if inmac:
            ops = re.sub(r'=(\d)', r'p\1', ops)
        if MN == '':
            out.append(lab + (('\t' + com) if com else '')); continue
        if key(mn) in macros and MN not in ('EQU',):
            o = operands(ops, {}, MN) if ops else ''
            out.append(lab + '\t' + macros[key(mn)] + (' ' + o if o else '') + ('\t' + com if com else '')); continue
        if MN == 'ENT':
            out.append(lab + '\t; ENT ' + ops); continue
        if MN == 'ENDD':
            out.append(lab + '\tENT'); continue
        if MN == 'DEFR':
            o = operands(ops, {}, MN).split(',')
            out.append(lab + '\tDS ' + o[0] + ',0' + '\t; DEFR' + ('\t' + com if com else '')); continue
        if MN == 'DEFS':
            out.append(lab + '\tDS ' + operands(ops, {}, MN) + ('\t' + com if com else '')); continue
        if MN == 'DEFM':
            out.append(lab + '\tDEFM ' + ops + ('\t' + com if com else '')); continue
        o = operands(ops, {}, MN) if ops else ''
        out.append(lab + '\t' + mn + (' ' + o if o else '') + ('\t' + com if com else ''))
    open(os.path.join(OUT, fn.lower().replace('.a80', '.asm')), 'wb').write('\n'.join(out).encode('cp866', 'replace'))

for fn in order: conv(fn)
print('files', len(order), 'labels', len(labels), 'macros', len(macros))
open(os.path.join(OUT, 'labels.txt'), 'w').write('\n'.join('%s %s' % kv for kv in sorted(labels.items())))
