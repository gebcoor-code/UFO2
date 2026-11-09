// node run.js url script.txt : steps "wait ms" | "key K" | "type text" | "shot name" | "eval js"
const { chromium } = require('playwright'); const fs = require('fs');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1400, height: 1000 } });
  p.on('console', m => { const t = m.text(); if (!/^\[vite\]/.test(t)) console.log('console:', t.slice(0, 300)); });
  p.on('pageerror', e => console.log('pageerror:', e.message));
  await p.goto(process.argv[2]);
  for (const ln of fs.readFileSync(process.argv[3], 'utf8').split('\n')) {
    const [c, ...r] = ln.trim().split(' '); const a = r.join(' ');
    if (!c || c[0] === '#') continue;
    if (c === 'wait') await p.waitForTimeout(+a);
    else if (c === 'key') { await p.keyboard.down(a); await p.waitForTimeout(120); await p.keyboard.up(a); await p.waitForTimeout(150); }
    else if (c === 'combo') { const ks = a.split('+'); for (const k of ks) { await p.keyboard.down(k); await p.waitForTimeout(60); } await p.waitForTimeout(200); for (const k of ks.reverse()) { await p.keyboard.up(k); await p.waitForTimeout(60); } await p.waitForTimeout(150); }
    else if (c === 'type') { for (let ch of a) { if (ch === ' ') ch = 'Space'; await p.keyboard.down(ch); await p.waitForTimeout(160); await p.keyboard.up(ch); await p.waitForTimeout(260); } }
    else if (c === 'shot') await p.screenshot({ path: 'shots/' + a + '.png' });
    else if (c === 'click') { const [x, y] = a.split(' ').map(Number); await p.mouse.click(x, y); }
    else if (c === 'sample') await p.evaluate(() => { window.__s = []; const f = () => { const E = UnrealDebug.E; const r = new Uint32Array(E.memory.buffer, E.web_dga_regs(), 20); const h = (x) => x.toString(16).padStart(4, '0'); window.__s.push(h(r[11]) + '/' + h(r[10]) + '/' + [0, 1, 2, 3].map((b) => E.web_bank_page(b).toString(16)).join('.')); if (window.__s.length < 3000) requestAnimationFrame(f); }; f(); });
    else if (c === 'dump') { const s = await p.evaluate(() => window.__s); let last = '', n = 0; const out = []; for (const x of s) { if (x === last) n++; else { if (last) out.push(last + (n > 1 ? 'x' + n : '')); last = x; n = 1; } } out.push(last + 'x' + n); console.log('samples:', out.slice(0, +a || 400).join(' ')); }
    else if (c === 'peek') { const [pg, off, n] = a.split(' ').map((x) => parseInt(x, 16)); console.log('peek', a, ':', await p.evaluate(([pg, off, n]) => { const E = UnrealDebug.E; const m = new Uint8Array(E.memory.buffer, E.web_mem_ptr() + pg * 16384 + off, n); return Array.from(m).map((x) => x.toString(16).padStart(2, '0')).join(' '); }, [pg, off, n])); }
    else if (c === 'bp') console.log('bp', a, await p.evaluate((x) => { const E = UnrealDebug.E; const b = new TextEncoder().encode(x); const m = new Uint8Array(E.memory.buffer, E.web_txt(), 256); m.set(b); m[b.length] = 0; return E.web_bp_add_cond(); }, a));
    else if (c === 'regs') console.log('regs', await p.evaluate(() => { const E = UnrealDebug.E; const r = new Uint32Array(E.memory.buffer, E.web_dga_regs(), 20); const n = ['AF', 'BC', 'DE', 'HL', "AF'", "BC'", "DE'", "HL'", 'IX', 'IY', 'SP', 'PC', 'IR']; let s = n.map((k, i) => k + '=' + r[i].toString(16)).join(' ') + ' win=' + [0, 1, 2, 3].map((b) => E.web_bank_page(b).toString(16)).join('.'); const sp = r[10]; s += ' stk:'; for (let i = -8; i < 16; i++) { const a = (sp + 2 * i) & 0xffff; s += (i === 0 ? ' |' : ' ') + (E.web_peek(a) | E.web_peek((a + 1) & 0xffff) << 8).toString(16); } return s; }));
    else if (c === 'save') { const [pg0, n, f] = a.split(' '); const b64 = await p.evaluate(([pg0, n]) => { const E = UnrealDebug.E; const m = new Uint8Array(E.memory.buffer, E.web_mem_ptr() + pg0 * 16384, n * 16384); let s = ''; for (let i = 0; i < m.length; i += 8192) s += String.fromCharCode.apply(null, m.subarray(i, i + 8192)); return btoa(s); }, [parseInt(pg0, 16), +n]); fs.writeFileSync(f, Buffer.from(b64, 'base64')); console.log('saved', f); }
    else if (c === 'mmove') { const [dx, dy] = a.split(' ').map(Number); const n = Math.max(1, Math.ceil(Math.max(Math.abs(dx), Math.abs(dy)) / 16)); for (let i = 0; i < n; i++) { await p.evaluate(([x, y]) => { const E = UnrealDebug.E; E.web_mouse_lock(1); E.web_mouse(x, y, 0, 0); }, [Math.round(dx / n), Math.round(dy / n)]); await p.waitForTimeout(40); } }
    else if (c === 'mclick') { const b = +(a || 1); await p.evaluate((b) => { const E = UnrealDebug.E; E.web_mouse_lock(1); E.web_mouse(0, 0, 0, b); }, b); await p.waitForTimeout(150); await p.evaluate(() => UnrealDebug.E.web_mouse(0, 0, 0, 0)); await p.waitForTimeout(150); }
    else if (c === 'goto') { const [tx, ty, ax, ay] = a.split(' ').map((v) => parseInt(v, 16) >= 0 && /^[0-9a-f]+$/i.test(v) && v.length === 4 ? parseInt(v, 16) : +v); for (let k = 0; k < 12; k++) { const [x, y] = await p.evaluate(([ax, ay]) => { const E = UnrealDebug.E; return [E.web_peek(ax) | E.web_peek(ax + 1) << 8, E.web_peek(ay)]; }, [ax, ay]); const dx = tx - x, dy = ty - y; if (!dx && !dy) break; await p.evaluate(([x, y]) => { const E = UnrealDebug.E; E.web_mouse_lock(1); E.web_mouse(x, y, 0, 0); }, [Math.max(-30, Math.min(30, dx)), Math.max(-30, Math.min(30, dy))]); await p.waitForTimeout(80); } }
    else if (c === 'ayr') console.log('ayr', a, await p.evaluate(() => { const E = UnrealDebug.E; let o = []; for (let c = 0; c < 2; c++) o.push(Array.from(new Uint8Array(E.memory.buffer, E.web_dga_ay(c), 18)).map((x) => x.toString(16).padStart(2, '0')).join(' ')); return o.join(' | '); }));
    else if (c === 'ay') { const r = []; for (let i = 0; i < 12; i++) { r.push(await p.evaluate(() => { const E = UnrealDebug.E; return Array.from(new Uint8Array(E.memory.buffer, E.web_chan_levels(), 8)).join('.'); })); await p.waitForTimeout(150); } console.log('ay', a, r.join(' ')); }
    else if (c === 'eval') console.log('eval:', JSON.stringify(await p.evaluate(a)));
  }
  await b.close();
})();
