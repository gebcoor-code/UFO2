import sys
d=sys.argv[1]
p1=open(d+'/p1.bin','rb').read(); p5=open(d+'/p5.bin','rb').read(); z=open(d+'/p15.bin','rb').read()
def ega(x,y):
    yy=y+4; pair=x>>1; part=pair&3; b=pair>>2
    pg=p1 if part in (0,2) else p5; off=(0x2000 if part>=2 else 0)+yy*40+b
    v=pg[off]
    if x&1==0: return (v&7)|((v>>6)&1)<<3
    return ((v>>3)&7)|((v>>7)&1)<<3
bad={}
for y in range(192):
    for x in range(256):
        a=z[0x1800+(y>>3)*32+(x>>3)]
        pa=((y&0xC0)<<5)|((y&7)<<8)|((y&0x38)<<2)|(x>>3)
        bit=(z[pa]>>(7-(x&7)))&1
        c=(a&7) if bit else ((a>>3)&7)
        c|=((a>>6)&1)<<3
        e=ega(x,y)
        if e!=c and not (c&7==0 and e&7==0): bad[(y>>3,x>>3)]=bad.get((y>>3,x>>3),0)+1; ex=(x,y,c,e,a)
for r in range(24):
    print('%2d '%r+''.join('#' if bad.get((r,c)) else '.' for c in range(32)))
print(len(bad), ex if bad else '')
