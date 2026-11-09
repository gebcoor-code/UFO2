import sys,collections,re
sys.argv=['x','x']
exec(open(__import__('os').path.join(__import__('os').path.dirname(__import__('os').path.abspath(__file__)),'inv_an.py')).read().split("d=sys.argv[1]")[0])
CAT=[('idle',r'^game:(EIDI|DLDI|DELAY|E_I)'),('music',r'^our:(MUS_|m_|pt3|int_f|int_x|MSTK|ld_|f_jp)|^pg2[45]'),
 ('cursor',r'^our:(cs_|cur_|bcur|swaprec|ui_mouse|x_kb|sk_pol|scale|m_clmp|cadd)'),
 ('overlay',r'^our:(ov_|ep_)'),
 ('convert',r'^our:(conv|sync|line_out|c_cnt|cpg|bd_|sc_|ou_|od_|fc_|bc_|pp_|pl_|row_|tslot|lo_|crw|B_FAST|fd_|sh_|pn2|pn_|map_|bk_pg|do_flip|psync|pan2|sy_|pscan|fs_)'),
 ('game',r'^game:'),('our-other',r'^our:')]
def cat(k):
    for c,r in CAT:
        if re.search(r,k): return c
    return 'other'
rows=[]
for d in sys.stdin.read().split():
    P=collections.Counter(); tot=0
    for l in open(d+'/prof2.txt'):
        n,pg,pc=l.split(); n=int(n); P[cat(name(int(pc,16),int(pg)))]+=n; tot+=n
    busy=tot-P['idle']
    print('%-6s busy %5.1f%%  '%(d,100*busy/tot)+'  '.join('%s %4.1f%%'%(c,100*P[c]/busy) for c,_ in CAT[1:]+[('other','')] if P[c]))
