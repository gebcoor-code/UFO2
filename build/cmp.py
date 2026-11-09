import sys, difflib, re
a=open(sys.argv[1],'rb').read(); b=open(sys.argv[2],'rb').read(); base=int(sys.argv[3],16)
sym={}
for l in open('out/sym.txt'):
    m=re.match(r'(\S+): (?:EQU )?0x([0-9A-F]+)',l)
    if m: sym[int(m.group(2),16)]=m.group(1)
addrs=sorted(sym)
import bisect
def near(x):
    k=bisect.bisect_right(addrs,x)-1
    return '%s+%d'%(sym[addrs[k]],x-addrs[k]) if k>=0 else '?'
sm=difflib.SequenceMatcher(None,a,b,autojunk=False)
for tag,i1,i2,j1,j2 in sm.get_opcodes():
    if tag!='equal' and (i2-i1>2 or j2-j1>2 or i1-j1!=0):
        print('%-7s ours %04X-%04X (%d) snap %04X-%04X (%d)  at %s'%(tag,base+i1,base+i2,i2-i1,base+j1,base+j2,j2-j1,near(base+i1)))
