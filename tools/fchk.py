# fchk.py DUMPDIR [bot side]: the shown EGA field vs BDSC converted (outside the panels shown, the cursor)
import sys
d=sys.argv[1]; bot=int(sys.argv[2]) if len(sys.argv)>2 else 1; side=int(sys.argv[3]) if len(sys.argv)>3 else 1
pg={k:open(d+'/pg%d.bin'%k,'rb').read() for k in (1,3,5,7)}
shown=open(d+'/p1.bin','rb').read()
fr=(1,5) if shown==pg[1] else (3,7)
w0=open(d+'/w0.bin','rb').read(); p15=open(d+'/p15.bin','rb').read()
at=p15[0x1800+8*32+14]
br=8 if at&64 else 0
ink=(at&7)|8; pap=(at>>3)&7       # (the fight: ink bright, paper dim)
BDSC=0x0F40; BW=44
rects=[(10,20,0,8)]
rects+= [(7,26,160,40),(18,4,149,10)] if bot else [(18,4,190,10)]
rects+= [(37,3,18,163),(35,2,86,26)] if side else [(38,2,86,26)]
def inr(c,y): return any(x<=c<x+n and yy<=y<yy+h for x,n,yy,h in rects)
bad=[]
for y in range(200):
    for c in range(40):
        if inr(c,y): continue
        b=w0[BDSC+(y+32)*BW+c+2]
        for k in range(4):
            p=pg[fr[0]] if k in (0,2) else pg[fr[1]]; v=p[(0x2000 if k>=2 else 0)+y*40+c]
            l=(v&7)|((v>>6)&1)<<3; r=((v>>3)&7)|((v>>7)&1)<<3
            bl=(b>>(7-2*k))&1; brr=(b>>(6-2*k))&1
            el=ink if bl else pap; er=ink if brr else pap
            if l!=el or r!=er: bad.append((c,y)); break
print('bad bytes',len(bad))
if bad:
    rows={}
    for c,y in bad: rows.setdefault(y//8,set()).add(c)
    for r in sorted(rows): print(' row',r,'cols',sorted(rows[r])[:20])
