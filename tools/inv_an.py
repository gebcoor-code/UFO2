import re, sys, os, bisect, collections
import os
R=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..')
PORT=os.path.join(R,'port')+'/'
zs={}
for l in open(__import__('os').environ.get('ZSYM','/tmp/claude-0/zs.txt')):
    m=re.match(r'([\w.]+): EQU 0x([0-9A-F]+)',l)
    if m: zs[m.group(1)]=int(m.group(2),16)
# label -> file
lf={}
for f in os.listdir(PORT):
    if not f.endswith('.asm'): continue
    for l in open(PORT+f,errors='replace'):
        m=re.match(r'([A-Za-z_][\w]*)\b',l)
        if m and not l.startswith((' ','\t',';')): lf.setdefault(m.group(1),f)
SEC={54:{'uipage.asm','sc.asm','uimouse.asm','wideu.asm','panel.asm','mku.asm','enc_u.asm','shift.asm','shift2.asm','keyed.asm'},
     63:{'xpg.asm','uidraw.asm','enc.asm','ico.asm'},53:{'tpg.asm','tpg2.asm'},61:{'obj.asm'},24:{'mus.asm'},25:{'mus.asm'},
     26:{'xspr.asm'},27:{'xspr.asm'},30:{'xtil_i.asm','xtil.asm'},31:{'xtil_i.asm','xtil.asm'},62:{'xtil_i.asm','xtil.asm'}}
W0F={'zxl.asm','scr.asm','field.asm','wide.asm','ui.asm','ram.asm','ovl.asm','mus.asm','title.asm','ram_init.asm','init_mv.asm','xtil.asm','xspr.asm'}
def table(files,lo,hi):
    t=sorted((a,n) for n,a in zs.items() if lf.get(n) in files and lo<=a<hi and '.' not in n)
    return [a for a,n in t],[n for a,n in t]
TB={pg:table(fs,0x4000 if pg in(26,27,30,31,62) else 0xC000,0x10000) for pg,fs in SEC.items()}
TB[0]=table(W0F,0,0x4000)
gs={}
for l in open(os.path.join(R,'build/out/sym.txt')):
    m=re.match(r'(l_\w+): EQU 0x([0-9A-F]+)',l)
    if m: gs.setdefault(int(m.group(2),16),m.group(1)[2:])
GA=sorted(gs); 
def name(pc,pg):
    if pc<0x4000 or pg in TB:
        a,n=TB[0] if pc<0x4000 else TB[pg]
        i=bisect.bisect_right(a,pc)-1
        return ('our:' + (n[i] if i>=0 else '?'))
    if 8<=pg<=15:
        i=bisect.bisect_right(GA,pc)-1
        return 'game:'+(gs[GA[i]] if i>=0 else '?')
    return 'pg%d:%04X'%(pg,pc&0xFF00)
d=sys.argv[1]
W=collections.Counter(); WT=collections.Counter()
for l in open(d+'/wcount.txt'):
    n,pc,pp,tp,o=l.split(); n=int(n); pc=int(pc,16); pp=int(pp); tp=int(tp); o=int(o,16)
    reg='scr7' if tp==15 else 'dscr'
    W[(name(pc,pp),reg)]+=n; WT[reg]+=n
print('== writes', dict(WT))
for (k,r),n in W.most_common(25): print('%8d %-5s %s'%(n,r,k))
P=collections.Counter(); tot=0
for l in open(d+'/prof2.txt'):
    n,pg,pc=l.split(); n=int(n); pg=int(pg); pc=int(pc,16); tot+=n
    P[name(pc,pg)]+=n
print('== time samples',tot)
G=collections.Counter()
for k,n in P.items(): G[k.split(':')[0]]+=n
print({k:'%.1f%%'%(100*v/tot) for k,v in G.items()})
for k,n in P.most_common(30): print('%6.1f%% %s'%(100*n/tot,k))
