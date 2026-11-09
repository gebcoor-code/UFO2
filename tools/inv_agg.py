import sys,collections
sys.argv=['x','x']
exec(open(__import__('os').path.join(__import__('os').path.dirname(__import__('os').path.abspath(__file__)),'inv_an.py')).read().split("d=sys.argv[1]")[0])
A=collections.Counter(); S=collections.defaultdict(set)
for d in 'mt enc ufv crew3 sgx2 w1 sc1'.split():
    for l in open(d+'/wcount.txt'):
        n,pc,pp,tp,o=l.split(); k=(name(int(pc,16),int(pp)),'scr7' if tp=='15' else 'dscr')
        A[k]+=int(n); S[k].add(d)
for k,n in A.most_common(40): print('%9d %-5s %-18s %s'%(n,k[1],k[0],' '.join(sorted(S[k]))))
