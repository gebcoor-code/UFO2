# LPC packer for UFO-2's DELPC (release variant). Stream: 4 bytes = the last 4 bytes of the data, then tokens:
#   #80|n (n 1..63): n literal bytes, stored rotated left (the unpacker does RRCA);  #80: end (the 4 bytes go out)
#   0LLLlllo xx  (b < #80): copy len = lll+3 (3..10) from DE - (o*256 + xx); then LLL literals follow
#   11nnnnnn hL xx: copy len = n+4 (4..67) from DE - (L*256 + xx) (offset < 4096); then h literals follow
# The packed block is preceded by 2 bytes (the game's table points at block+2): its length.
import sys

def rl(b): return ((b << 1) | (b >> 7)) & 255
def rr(b): return ((b >> 1) | (b << 7)) & 255

def pack(data):
    body, tail = data[:-4], data[-4:]
    out = bytearray(tail); i = 0; lit = bytearray()
    def flush():
        nonlocal lit
        while lit:
            n = min(63, len(lit)); out.append(0x80 | n); out.extend(rl(b) for b in lit[:n]); lit = lit[n:]
    n = len(body)
    # hash of 3-byte prefixes -> positions
    heads = {}
    while i < n:
        best = (0, 0)
        if i + 3 <= n:
            for p in reversed(heads.get(bytes(body[i:i + 3]), [])[-64:]):
                off = i - p
                if off >= 4096: continue
                L = 0
                while i + L < n and L < 67 and body[p + L] == body[i + L]: L += 1   # overlapping copy is fine (LDIR)
                if L > best[0] or (L == best[0] and off < best[1]): best = (L, off)
        L, off = best
        if L >= 3 and not (L == 3 and off >= 512):
            flush()
            if L <= 10 and off < 512:
                out.append(((L - 3) << 1) | (off >> 8)); out.append(off & 255)
            else:
                out.append(0xC0 | (L - 4)); out.append(off >> 8); out.append(off & 255)
            for k in range(i, i + L):
                if k + 3 <= n: heads.setdefault(bytes(body[k:k + 3]), []).append(k)
            i += L
        else:
            lit.append(body[i])
            if i + 3 <= n: heads.setdefault(bytes(body[i:i + 3]), []).append(i)
            i += 1
    flush(); out.append(0x80)
    return bytes(out)

def pack_opt(data):
    body, tail = bytes(data[:-4]), bytes(data[-4:])
    n = len(body)
    heads = {}
    cand = [None] * n
    for i in range(n):
        lst = []
        if i + 3 <= n:
            ch = heads.get(body[i:i + 3], [])
            bestlen = {}
            for p in reversed(ch[-200:]):
                off = i - p
                if off >= 4096: break
                L = 0
                while i + L < n and L < 67 and body[p + L] == body[i + L]: L += 1
                if L >= 3:
                    for l in range(3, L + 1):
                        if l not in bestlen: bestlen[l] = off      # nearest offset for each length
            lst = sorted(bestlen.items())
            ch.append(i); heads[body[i:i + 3]] = ch
        cand[i] = lst
    INF = 1 << 30
    dp = [INF] * (n + 1); ch_ = [None] * (n + 1); dp[n] = 0
    for i in range(n - 1, -1, -1):
        best = INF; choice = None
        for L in range(1, min(63, n - i) + 1):
            c = 1 + L + dp[i + L]
            if c < best: best, choice = c, ('lit', L)
        for l, off in cand[i]:
            short = l <= 10 and off < 512
            if not short and l < 4: continue
            mc = 2 if short else 3
            tmax = 7 if short else 15
            for t in range(0, min(tmax, n - i - l) + 1):
                c = mc + t + dp[i + l + t]
                if c < best: best, choice = c, ('m', l, off, t, short)
        dp[i] = best; ch_[i] = choice
    out = bytearray(tail); i = 0
    while i < n:
        c = ch_[i]
        if c[0] == 'lit':
            L = c[1]; out.append(0x80 | L); out.extend(rl(b) for b in body[i:i + L]); i += L
        else:
            _, l, off, t, short = c
            if short: out.append((t << 4) | ((l - 3) << 1) | (off >> 8)); out.append(off & 255)
            else: out.append(0xC0 | (l - 4)); out.append((t << 4) | (off >> 8)); out.append(off & 255)
            i += l
            out.extend(rl(b) for b in body[i:i + t]); i += t
    out.append(0x80)
    return bytes(out)

def unpack(src):
    tail = src[:4]; i = 4; out = bytearray()
    while True:
        a = src[i]
        if a < 0x80:
            L = ((a & 0x0E) >> 1) + 3; off = ((a & 1) << 8) | src[i + 1]; i += 2
            for k in range(L): out.append(out[len(out) - off])
            cnt = (a >> 4) & 15
            for k in range(cnt): out.append(rr(src[i])); i += 1
        elif a < 0xC0:
            i += 1; c = a & 0x3F
            if c == 0: break
            for k in range(c): out.append(rr(src[i])); i += 1
        else:
            L = (a & 0x3F) + 4; x = src[i + 1]; off = ((x & 15) << 8) | src[i + 2]; i += 3
            for k in range(L): out.append(out[len(out) - off])
            cnt = x >> 4
            for k in range(cnt): out.append(rr(src[i])); i += 1
    return bytes(out + tail)

if __name__ == '__main__':
    d = open(sys.argv[1], 'rb').read()
    p = pack(d); assert unpack(p) == d
    open(sys.argv[2], 'wb').write(p); print(len(d), '->', len(p))
