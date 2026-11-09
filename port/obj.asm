; ------------------------------------------------------------------ the fight's objects: page MPG (W3, DISP #C000)
; The field (BDSC) is one colour pair: the fighters and the aliens are told from the ground here, by two planes
; kept beside it while the game draws (the same offsets as BDSC):
;   M (page MPG, at #C000 | field address): its bits = the pixels the objects cover (a sprite's mask);
;   C (page CPG, same offsets): the object's index + 1 (its MAN entry: 1..10 ours, 11.. the aliens) for M's bytes.
; Hooks (all through fmark, W0; told apart by their return addresses):
;   MS2 / LS2 / RS2 (a sprite, its left / right half): the ground clears M under its mask (only where M may have
;     bits: ob_fl); a fighter put into DATR by A4P (l_HIX, alive) sets M with his own mask, C his index;
;   GBU (HERO: a fighter moving, shifted): M, C under him saved, his mask ORed in; PBU: M, C restored;
;   the scrolls (lay_fall -> ob_sh): M, C moved as the game moves BDSC (the rows with objects only).
; ob_fl: per 8 lines of the field, bit k: bytes 8k-6 .. 8k+1 (EGA group k-1) may have M's bits (cleared slowly
; by ob_cln). The conversion (fc_t2: ob_row, ob_g) converts such groups through M and C: the ground's ink dim,
; the fighter in focus bright, the other ones dim, the aliens bright (tpg.asm).
; Here also the field marks (m_fmu, m_fmw: the old fmark_u / fmark_w).
MPG     equ 61                       ; (the screen cache keeps 55..60)
CPG     equ 62
; (defined before they are used: an equ's chain of later ones is not resolved in sjasmplus's passes)
ob_sm   equ #FCA0                       ; GBU's M (24 x 3)
ob_sc   equ #FCA0+72                    ; and C
hb      equ #FCA0+144                   ; the fighter's mask (DATR's lines 4..27: 24 x 2)
ob_mk   equ #FCA0+192                   ; HERO's mask, shifted (24 x 3)
FGS     equ 52                          ; (an entry)
fg_t    equ #FCA0+264                   ; (FGN x FGS) the coloured figures drawn whole (A4P, DATR): address (2), os_l0, hb
FGN     equ 3
OB_V    equ fg_t+FGN*FGS                ; (past the buffers; zeroed at each fight's start: OB_Z0..OB_Z1)
ob_fl   equ OB_V                        ; 33 rows
ob_her  equ OB_V+33                     ; (2) HER_AD as last seen
ob_cur  equ OB_V+35                     ; the fighter in focus: index + 1; then (fc_t2 copies these four)
ob_a1m  equ OB_V+36                     ; the coloured objects' attributes (#80: tslot's ink bright, paper dim):
ob_a2m  equ OB_V+37                     ; the one in focus (the paper bright), ob_a3m: the aliens (red bright)
ob_a3m  equ OB_V+38
ob_fa   equ OB_V+39                     ; the field's attribute + 1 they are for
ob_hp   equ OB_V+40                     ; (2) the fighter's picture in hb (0: none)
ob_sv   equ OB_V+42                     ; (2) GBU's place (0: none)
ob_tk   equ OB_V+44
ob_cr   equ OB_V+45                     ; the clean-up's row, group
ob_cg   equ OB_V+46
ob_ff   equ OB_V+47                     ; 33 rows: groups whose M changed (the conversion: those bytes out again)
ob_mc   equ OB_V+80                     ; 33 rows: groups whose M / C a hook changed (ob_pend: really?)
mk_ad   equ OB_V+113                    ; (2) the 3D cursor drawn here (its M saved), 0: none
mk_ver  equ OB_V+115                    ; its bits' version (ob_row copies them when it changed)
mk_n    equ OB_V+116                    ; its lines
mk_pd   equ OB_V+117                    ; POFF came: its M taken back only if PNTR does not draw it again the same
mk_pc   equ OB_V+119                    ; (2) its picture
ob_cp   equ OB_V+121                    ; ob_cur + 1 at the last ob_post
OB_Z0   equ DB_C                        ; (DB_C, FB_C, the buffers, OB_V: below it MX - mx.asm - since M is gone)
OB_Z1   equ OB_V+122
mk_sv   equ OB_Z1                       ; (64) the bits it set in M, 32 lines x 2 (not zeroed)
        ASSERT (mk_sv & 255) + 63 <= 255

obj_img
        DISP #C000
; from fmark (W0): HL, DE, B = lines, C = bytes as fmark got them; above: fmark's return, HL, DE, BC, AF, the
; lay_* return, its BC, the game's return
ob_ent  ld a,(bwide) : or a : jr nz,0F
        call m_fmu : jp ob_ex                   ; (not the fight's field: the marks only; fmark keeps HL, DE, BC)
0
        ld a,(PL_USE) : or a : jr nz,1F
        push hl : push de : push bc : call m_fmw : pop bc : pop de : pop hl : jr 2F     ; the marks
1       xor a : ld (ob_ok),a                    ; (the colour plane: m_fmw's line, byte only - ob_ok, fm_l, ob_cl)
        ld de,BDSC : or a : sbc hl,de : jr c,2F
        ld de,BLINES*BW : sbc hl,de : add hl,de : jr nc,2F
        ld a,h : cp #2C : ld a,3 : jr c,11F : dec a                     ; (3: os_r, os_l, os_c made here)
11      ld (ob_ok),a
        ld a,h : add a,a : add a,low m_lt : ld e,a : ld a,high m_lt : adc a,0 : ld d,a
        ld a,(de) : ld c,a : inc de : ld a,(de) : add a,l : ld e,a : ld a,high m_q : adc a,0 : ld d,a
        ld a,(de) : add a,c : ld (fm_l),a : ld b,a : and 7 : ld (os_l),a
        ld a,b : rrca : rrca : rrca : and #1F : ld (os_r),a
        inc d : inc d : ld a,(de) : ld (ob_cl),a : ld (os_c),a
2       call ob_hc
        ; a field tile (the most of them): straight to xtil_i.asm's pl_sq / pl_do (ob_fp); else the ways below (ob_sl).
        ; SP+0: fmark's return, +2 HL, +4 DE, +6 BC, +8 AF, +10 lay_*'s return, +12 its BC, +14 the game's return
        ld a,(ob_ok) : cp 3 : jp nz,ob_sl                       ; (its line, byte known; not past row 28: no clip)
        ld a,(ob_cur) : inc a : ld hl,ob_cp : cp (hl) : jp nz,ob_sl     ; (the one in focus changed: ob_post)
        ld hl,11 : add hl,sp : ld a,(hl) : cp high lfd2_r : jp nz,ob_sl : dec hl
        ld a,(hl) : ld c,3 : cp low lfd2_r : jr z,1F                    ; MS2: both columns
        cp low lfd1_r : jp nz,ob_sl
        ld hl,14 : add hl,sp : ld a,(hl) : inc hl : ld h,(hl) : ld l,a
        ld de,G_LS2+3 : or a : sbc hl,de : ld c,1 : jr z,1F : inc c    ; LS2 / RS2
        ASSERT high lfd1_r == high lfd2_r
1       ld hl,4 : add hl,sp : ld e,(hl) : inc hl : ld d,(hl) : inc hl : inc hl : ld a,(hl) : or a : jp z,ob_sl
        ld b,a                                                  ; B = lines, DE = the picture
        ld hl,-G_xMARKE : add hl,de : jr nc,11F : ld a,h : cp 2 : jp c,ob_sl      ; (the 3D cursor's pictures)
11      ld hl,-#B000 : add hl,de : jp nc,ob_sl : ld a,h : cp #30 : jp nc,ob_sl    ; (a tile's: codes 0..95)
        ld a,c : ld (os_cm),a : ld a,b : ld (os_n),a : xor a : ld (os_hx),a
        ld a,l : rrca : rrca : and #1F : ld e,a : add hl,hl : ld d,h            ; D = the code, E = its line
        ld a,(G_MS20+3) : ld (pl_mm),a                          ; (the game's bank 5: before W1 = TLPG)
        ld a,(G_FLR) : ld (pf_fl),a                             ; (the floor drawn: xpnt.asm pl_fl)
        push bc : ld bc,P_W1 : ld a,#7F-TLPG : out (c),a : pop bc
        ld a,(pl_exp) : or a : jr nz,12F                        ; (the fight's first: its tiles first - PL_SPR)
        ld hl,ptab : ld (ptab_p),hl
        call ob_fp
        ld bc,P_W1 : ld a,#7F-(PG_ZX+5) : out (c),a
        ld hl,13 : add hl,sp : ld a,(hl) : add a,a : add a,a : ld c,a : ld b,0  ; (ob_nd's: past the picture, MSiRET)
        ld hl,4 : add hl,sp : ld e,(hl) : inc hl : ld d,(hl) : ex de,hl : add hl,bc : ex de,hl
        ld (hl),d : dec hl : ld (hl),e
        ld hl,14 : add hl,sp : ld (hl),low G_MSIRET : inc hl : ld (hl),high G_MSIRET
        jp ob_ex
12      ld bc,P_W1 : ld a,#7F-(PG_ZX+5) : out (c),a
ob_sl   push ix : ld ix,0 : add ix,sp           ; IX+0: the game's IX, +4 HL, +6 DE, +8 BC, +12 lay_*, +16 the game
        ld l,(ix+12) : ld h,(ix+13)            ; (HL - each one's: less than the next's)
        ld de,lfd2_r : or a : sbc hl,de : jr z,.ms
        ld de,lfd1_r-lfd2_r : or a : sbc hl,de : jr z,.h1
        ld de,lfdc_r-lfd1_r : or a : sbc hl,de : jr nz,.x
        ld hl,(G_X0) : ld (ob_fk),hl : ld a,(G_SH) : ld (ob_fk+2),a : ld a,(G_FLR) : ld (ob_fk+3),a   ; (xtil_i.asm as_beg)
        ld l,(ix+16) : ld h,(ix+17)
        ld de,G_GBUH : or a : sbc hl,de : call z,ob_gbu
        jr .x
.h1     ld l,(ix+16) : ld h,(ix+17) : ld de,G_LS2+3 : or a : sbc hl,de
        ld a,1 : jr z,1F : inc a                ; 1: LS2 (the left column), 2: RS2 (the right one)
1       call ob_spr : jr .y
.ms     ld a,3 : call ob_spr
.y      ld a,(ob_cur) : inc a : ld hl,ob_cp : cp (hl) : jr nz,.w                 ; (a sprite: ob_post only for the
        ld l,(ix+6) : ld h,(ix+7) : ld de,-G_xMARKE : add hl,de : jr nc,.z      ; one in focus changed since, the
        ld a,h : cp 2 : jr nc,.z : ld a,l : and 127 : jr z,.w                   ; 3D cursor's pictures)
.z      call ob_nd : pop ix : jr ob_ex             ; (W1: the game's - ob_spr's ways all end so)
.w      call 1F : call ob_nd : pop ix : jr ob_ex        ; (ob_nd after ob_post: it changes the frame's DE)
.x      call 1F : pop ix
; fmark's W3 back (fm_w3: W3V as it was) - through page zero's map_w3p's end, back to fmark
ob_ex   ld a,(fm_w3) : push bc : jp w3_v
1       ld a,(ob_cur) : inc a : ld (ob_cp),a
        ld hl,ob_post : jp pl_go                ; (xtil_i.asm: all of the colour plane's work)
; (ob_ent: W1 = TLPG) a field tile: D = its code, E = its first line, B = lines, C = columns -> pl_do's words on
; PL_SPR's stack (as its prologue makes them), into pl_sq (xtil_i.asm pl_sqd); pl_ret / pl_do's end back here
ob_fp   ld (PL_SP),sp : ld sp,PL_SP
        call 1F
        ld sp,(PL_SP) : ret
1       ld hl,#FFFF : push hl                                   ; the frame: none (pf_get's)
        push de : push bc
        ld a,(fm_l) : sub 32 : ld l,a : sbc a,a : ld h,a : push hl              ; the plane's line (signed)
        ld a,(pl_mm) : cp #AE : ld a,0 : jr z,2F : ld a,#80     ; (masks only: black)
2       ld c,a : ld a,(os_c) : sub 2 : ld b,a : push bc
        jp pl_sqd
; (the M / C planes are gone: the field's colour plane has the objects too - xtil_i.asm)
; (a sprite into BDSC, the colour plane in use) the game's drawing skipped: the plane is all of the field's picture,
; BDSC is read only by the drawing itself, GBU / PBU, the scrolls, the copy to screen 7 (not shown in the EGA view).
; Back into its MS2 / LS2 / RS2's end (MSiRET: POP HL, POP BC, RET - theirs the same) with DE (the picture) as after it
ob_nd   ld a,(PL_USE) : or a : ret z
        ld a,(ob_ok) : or a : ret z                     ; (m_fmw: not in BDSC)
        ld a,(ix+15) : add a,a : add a,a : ld c,a : ld b,0                ; (4 bytes a line)
        ld l,(ix+6) : ld h,(ix+7) : add hl,bc : ld (ix+6),l : ld (ix+7),h
        ld (ix+16),low G_MSIRET : ld (ix+17),high G_MSIRET : ret
ob_pend ret                                     ; (lay_outw)
ob_sh   ret                                     ; (the scrolls: field.asm)
; row C, groups A: forced (ob_ff), the visible rows' marks (fdrow, fdlin)
ob_frc  push bc : push af
        ld a,c : ld e,a : ld d,0 : ld hl,ob_ff : add hl,de : pop af : push af : or (hl) : ld (hl),a
        pop af : rrca : and #1F : jr z,9F : ld b,a
        ld a,c : sub 4 : jr c,9F : cp FDN : jr nc,9F
        ld e,a : ld hl,fdrow : add hl,de : ld a,b : or (hl) : ld (hl),a
        ld a,l : add a,FDN : ld l,a : jr nc,1F : inc h
1       ld (hl),#FF
9       pop bc : ret
; (xtil_i.asm; W1 = TLPG) HL = a place (bytes c0, c1, rows r0, r1): its rows' groups forced - the plane's colours
; there changed, the field's bytes need not have (a frame's pixels are not the game's sprite's)
ob_f4   ld a,(hl) : ld c,a : call ob_gb : ld e,a : ld a,c : inc a : call ob_gb : or e : ld e,a
        inc hl : ld a,(hl) : call ob_gb : or e : ld (os_t),a
        inc hl : ld c,(hl) : inc hl : ld b,(hl)
1       ld a,c : cp 33 : ret nc : ld a,(os_t) : call ob_frc
        ld a,c : inc c : cp b : jr c,1B : ret
os_t    db 0
; (xtil_i.asm pf_get) the sprite's rows (os_*), its columns and the one each side: forced
ob_fs   ld hl,ob_f4b : ld a,(os_c) : dec a : ld (hl),a : add a,2 : inc hl : ld (hl),a
        ld a,(os_r) : inc hl : ld (hl),a : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl
        ld a,(os_l) : ld e,a : ld a,(os_n) : add a,e : dec a : ld e,a : ld d,0 : add hl,de
        add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : ld a,h : ld (ob_f4b+3),a
        ld hl,ob_f4b : jr ob_f4
ob_f4b  ds 4
; HL = a MAN entry -> A = 1 alive, 0 not (as HERLIV)
ob_liv  ld de,8 : add hl,de : ld a,(hl) : or a : ret z
        ld de,5 : add hl,de : ld a,(hl) : or a : ret z
        ld de,13 : add hl,de : cp (hl) : ld a,0 : ret c
        inc a : ret
; A = index + 1 -> NZ: coloured (all are: their frames, xspr.asm)
ob_cls  or a : ret
; W1 = page A; W1 = the game's (bank 5)
ob_w1   push bc : cpl : add a,#80 : ld bc,P_W1 : out (c),a : pop bc : ret     ; (#7F - A)
ob_w13  push bc : ld a,#7F-(PG_ZX+5) : ld bc,P_W1 : out (c),a : pop bc : ret

; HL = field address -> CY: outside BDSC; else A = row (8 lines), B = its line, C = byte
ob_lc   ld de,-BDSC : add hl,de : ccf : ret c
        push hl : ld de,-(BLINES*BW) : add hl,de : pop hl : ret c
        push hl : ld a,h : srl a : ld c,a : srl a : srl a : add a,c : ld c,a      ; C <= the row (h * 11 / 16 <= h * 256 / 352)
        ld a,h : rrca : rrca : rrca : rrca : and 15 : add a,c : ld c,a
        ld l,c : ld h,0 : add hl,hl : ld de,t352 : add hl,de : ld e,(hl) : inc hl : ld d,(hl)
        pop hl : or a : sbc hl,de
1       ld de,-352 : add hl,de : jr nc,2F : inc c : jr 1B
2       ld de,352 : add hl,de : ld b,0
3       ld de,-BW : add hl,de : jr nc,4F : inc b : jr 3B
4       ld de,BW : add hl,de : ld a,c : ld c,l
        ld (os_r),a : ld a,b : ld (os_l),a : ld a,c : ld (os_c),a : ld a,(os_r) : or a : ret      ; (os_r, os_l, os_c too)
; A = byte (0..43) -> A = its group's bit (ob_ff)
ob_gb   add a,6 : rrca : rrca : rrca : and 7 : jp gbit
; os_n kept within the field (BLINES)
ob_clip ld a,(os_r) : cp 29 : ret c
        ld c,a : ld a,33 : sub c : add a,a : add a,a : add a,a : ld c,a : ld a,(os_l) : neg : add a,c   ; lines left
        ld c,a : ld a,(os_n) : cp c : ret c : ld a,c : ld (os_n),a : ret

os_r    db 0                                    ; row, line in it, byte, lines
os_l    db 0
os_c    db 0
os_n    db 0
os_cm   db 0                                    ; columns: 1 left, 2 right, 3 both
os_hx   db 0                                    ; a fighter: index + 1
os_lv   db 0
os_l0   db 0                                    ; the first line's line in the sprite (signed)
os_do   db 0
ob_ok   db 0                                    ; m_fmw: its line (fm_l) and byte (ob_cl) good (1; 3: os_r, os_l,
                                                ; os_c too - ob_ent; 2: in BDSC past them; 0: not in BDSC)
ob_cl   db 0
ob_fk    ds 4                                    ; (CURHER's hooks) the field's X0, SH, FLR

; ---- a sprite (MS2 / LS2 / RS2): A = columns. The tile's (or A4P's figure's) lines into the colour plane (xtil_i.asm
; PL_SPR), the figure's record (xspr.asm xs_hset: its frame - his colours when the one in focus changes)
ob_spr  ld (os_cm),a
        ld hl,ptab : ld (ptab_p),hl             ; (debug LOC GO's patch table done: xpg.asm dbg_bat)
        ld l,(ix+6) : ld h,(ix+7) : ld de,-G_xMARKE : add hl,de : jr nc,ob_sp0    ; the 3D cursor's pictures (its first
        ld a,h : cp 2 : jr nc,ob_sp0 : ld a,l : and 127 : ret z                 ; lines; ASP's #B000 + n * 128 share
ob_sp0  ld a,(ob_ok) : cp 3 : jr z,1F : dec a : jr nz,0F                                           ; xMARKE's bytes): xtil_i.asm ob_post
        ld a,(ob_cl) : ld (os_c),a : ld a,(fm_l) : ld b,a : and 7 : ld (os_l),a     ; (m_fmw's)
        ld a,b : rrca : rrca : rrca : and #1F : ld (os_r),a : jr 1F
0       call ob_h4 : call ob_lc : ret c
1       ld a,(ix+9) : or a : ret z : ld (os_n),a
        call ob_clip
        xor a : ld (os_hx),a
        ld e,(ix+6) : ld d,(ix+7)
        ld hl,-(G_DATR-64) : add hl,de : jr nc,2F               ; (DATR - 64 .. DATR + 127: a fighter's sprite)
        ld a,h : or a : jr nz,2F : ld a,l : cp 192 : jr nc,2F
        call ob_hero
        ld hl,xs_hset : call xs_go
2       ld a,(G_MS20+3) : ld (pl_mm),a          ; (Ainv1: #AE, 0 = masks only)
        ld a,(G_FLR) : ld (pf_fl),a             ; (the floor drawn: xpnt.asm pl_fl)
        ld bc,P_W1 : ld a,#7F-TLPG : out (c),a : call PL_SPR   ; (as pl_go)
        ld bc,P_W1 : ld a,#7F-(PG_ZX+5) : out (c),a : ret
; DATR's figure (l_HIX: A4P's, alive or dead): os_hx, os_lv, os_l0
ob_hero ld hl,(G_HIX) : ld a,h : or a : ret z
        call ob_liv : ld (os_lv),a
        ld hl,(G_HIX) : ld de,-G_MAN : add hl,de : add hl,hl : add hl,hl : add hl,hl : ld a,h : inc a
        call ob_cls : ret z
        ld (os_hx),a
        ld l,(ix+6) : ld h,(ix+7) : ld de,-(G_DATR-64) : add hl,de : srl l : srl l : ld a,l : sub 16 : ld (os_l0),a
        ret
; ---- GBU (HERO draws a thing moving: 24 lines x 3 bytes, shifted by HE1's DSP): its place (ob_sv: 0 none), os_*,
; who (os_hx: a MAN entry's IX - a fighter, an alien; the bullet's, the blasts' are the shooter's), the shift (os_do),
; a fighter's frame record (xs_gset)
ob_gbu  ld hl,0 : ld (ob_sv),hl
        call ob_h4 : call ob_lc : ret c
        ld a,c : cp BW-2 : ret nc
        ld a,(os_r) : cp 29 : ret nc                            ; (the bottom margin: never mind)
        call ob_h4 : ld (ob_sv),hl
        ld a,(G_HE1+1) : ld c,0 : cp low G_DSP0 : jr z,1F       ; the shift (HE1's DSPn: all at #7Dxx)
        ld c,2 : cp low G_DSP2 : jr z,1F : ld c,4 : cp low G_DSP4 : jr z,1F : ld c,6
1       ld a,c : ld (os_do),a
        ASSERT high G_DSP0 == high G_DSP2 && high G_DSP0 == high G_DSP4 && high G_DSP0 == high G_DSP6
        xor a : ld (os_hx),a
        ld l,(ix+0) : ld h,(ix+1) : ld de,-G_MAN : add hl,de : ret nc
        ld a,h : cp 4 : ret nc
        add hl,hl : add hl,hl : add hl,hl : ld a,h : inc a
        ld c,a : ld a,1 : ld (os_lv),a : ld a,c : call ob_cls : ret z
        ld (os_hx),a
        ld a,(ix+7) : cp #C0 : ret c                            ; (his picture: W3's bank)
        ld hl,xs_gset : jp xs_go
; ---- the coloured frames' records: HL = xspr.asm's routine (A kept), run with W1 = SPG
pl_mm   db 0                                    ; the game's Ainv1 at the sprite (xtil.asm)
xs_go   push af : ld a,SPG : jr 2F
pl_go   push af : ld a,TLPG                     ; (xtil.asm's: W1 = TLPG; W2 the game's bank 2 again after)
2       call ob_w1 : pop af : call 1F : jp ob_w13
1       jp (hl)
ob_h4   ld l,(ix+4) : ld h,(ix+5) : ret

; ---- the fighter in focus (HER_AD) changed: ob_cur (xtil_i.asm ob_post: his colours, the last one's); only ours
; (the aliens' turn: HER_AD is the alien's - our last one stays red, e.g. under the alien's grenade)
ob_hc   ld hl,(G_HERAD) : ld de,(ob_her) : or a : sbc hl,de : ret z
        add hl,de : ld (ob_her),hl
        ld de,-G_MAN : add hl,de : add hl,hl : add hl,hl : add hl,hl : ld a,h : inc a : cp 11 : ret nc
        ld (ob_cur),a : ret

; ---- the field marks (were fmark_u / fmark_w in UPG): HL = DSCR / the wide field's address, B = lines, C = bytes
m_fmu   ld a,(bwide) : or a : jp nz,m_fmw
        ld a,b : ld (fm_n),a
        ld de,-#9000 : add hl,de : ld a,h : cp #18 : jr nc,.r          ; not in DSCR
        ld a,l : and 31 : ld e,a                ; E = x
        add hl,hl : add hl,hl : add hl,hl : ld a,h : sub 32 : ld (fm_l),a   ; field line (may be "negative")
        ld a,e : dec a : jp m,.r0
        jr .c0
.r0     xor a
.c0     cp 1 : jr nc,1F : ld a,1
1       ld d,a
        ld a,e : add a,c : sub 2 : cp 28 : jr c,2F : ld a,28
2       cp d : jr c,.r
        ld c,a : ld a,d : call m_gmask : ld (fm_g),a
        ld a,(fm_n) : ld b,a
3       ld a,(fm_l) : cp 128 : jr nc,4F
        add a,8 : ld c,a
        rrca : rrca : rrca : and #1F : ld hl,fdrow : add a,l : ld l,a : jr nc,5F : inc h
5       ld a,(fm_g) : or (hl) : ld (hl),a
        ld de,FDN : add hl,de : ld a,c : and 7 : call gbit : or (hl) : ld (hl),a
4       ld hl,fm_l : inc (hl)
        djnz 3B
.r      ret
m_gmask push bc
        rrca : rrca : rrca : and 3 : ld b,a
        ld a,c : rrca : rrca : rrca : and 3 : ld c,a
        ld a,b : call gbit : push af : ld a,c : inc a : call gbit : dec a : ld c,a
        pop af : dec a : cpl : and c
        pop bc : ret
m_fmw   ld a,b : ld (fm_n),a : ld a,c : ld (fm_c),a
        xor a : ld (ob_ok),a
        ld de,BDSC : or a : sbc hl,de : ret c
        ld de,BLINES*BW : sbc hl,de : add hl,de : ret nc
        ld a,h : cp #2C : ld a,1 : jr c,01F : inc a             ; (1: below line 256 - its line, byte for ob_spr; 2: past it)
01      ld (ob_ok),a                                    ; (ob_nd: 0 - not in BDSC)
        ld a,h : add a,a : ld e,a : ld d,0 : push hl : ld hl,m_lt : add hl,de : ld c,(hl) : inc hl : ld b,(hl) : pop hl
        ld a,l : add a,b : ld e,a : ld a,high m_q : adc a,0 : ld d,a               ; C = line (of H * 256), DE: the rest's
        ld a,(de) : add a,c : ld (fm_l),a : inc d : inc d : ld a,(de) : ld l,a       ; (/ 44, % 44: m_q, m_r)
0       ld a,l : ld (ob_cl),a
        ld a,(PL_USE) : or a : ret nz                   ; (the colour plane: the field's marks are its own - xtil_i.asm pl_mk)
        ld a,l : sub 2 : ld d,a
        ld a,(fm_c) : dec a : add a,d : ld e,a
        bit 7,e : ret nz
        bit 7,d : jr z,1F : ld d,0
1       ld a,d : cp 40 : ret nc
        ld a,e : cp 40 : jr c,2F : ld e,39
2       ld a,e : rrca : rrca : rrca : and 7 : inc a : call gbit : dec a : ld e,a
        ld a,d : rrca : rrca : rrca : and 7 : call gbit : dec a : cpl : and e : ld (fm_g),a
        ld a,(fm_n) : ld e,a : ld a,(fm_l) : ld d,a : add a,e : jr nc,0F : ld a,255
0       ld e,a
        ld a,d : cp 32 : jr nc,1F : ld d,32
1       ld a,e : cp 232 : jr c,2F : ld e,232
2       ld a,d : cp e : ret nc
        ld a,e : sub d : ld e,a
        ld a,d : sub 32 : ld d,a
3       ld a,d : and 7 : ld c,a
        ld a,8 : sub c : cp e : jr c,4F : ld a,e
4       ld b,a
        ld hl,fm_lm : add a,l : ld l,a : jr nc,5F : inc h
5       ld a,(hl) : inc c : jr 7F
6       add a,a
7       dec c : jr nz,6B
        ld c,a
        ld a,d : rrca : rrca : rrca : and #1F
        ld hl,fdrow : add a,l : ld l,a : jr nc,8F : inc h
8       ld a,(fm_g) : or (hl) : ld (hl),a
        ld a,l : add a,FDN : ld l,a : jr nc,9F : inc h
9       ld a,c : or (hl) : ld (hl),a
        ld a,d : add a,b : ld d,a
        ld a,e : sub b : ld e,a : jr nz,3B
        ret
fm_c    db 0
; (0.66.0; xtil_i.asm pl_xp - the fight's first sprite -, or wideu.asm xp_fight: once a fight - lp_ok, bat_on's 0)
; the location's palette: UFO2.TIL's "PL" block (TIPG at W1: LP_A - build/mktil.py): per XL map file #20..#53 (the
; game's L_MOD) its tile set; per set 80 bytes - the sprites' logical colour -> slot (xspr.asm xs_lm, xs_lf: SPG, SPG2),
; slot -> the standard palette's nearest (textr.asm rb_n: bo_rmp), the slots' values and the ZX colour -> slot (textc.asm xr_pal,
; xr_zx: TXPG) - copied there (W2 a while). No block (an old UFO2.TIL): theirs stay (the fight's palette as before).
; A = W1's page after (TIPG there a while).
LP_A    equ #7540
lp_set  ld (lp_w1),a
        ld a,(lp_ok) : or a : ret nz : inc a : ld (lp_ok),a
        ld a,i : push af : di
        WIN P_W2, PG_ZX+5
        ld a,(G_LMOD+#4000) : sub 20 : cp 34 : jr nc,9F
        push af
        WIN P_W1, TIPG
        pop bc : ld c,b : ld b,0
        ld hl,(LP_A) : ld de,"LP" : or a : sbc hl,de : jr nz,9F
        ld hl,LP_A+2 : add hl,bc : ld a,(hl) : cp 21 : jr nc,9F
        ld l,a : ld h,b : add hl,hl : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        ld de,LP_A+#30 : add hl,de
        push hl : ld a,SPG : call 1F : pop hl
        ld a,SPG2 : call 1F
        ld de,rb_n : ld bc,16 : ldir
        ld de,xr_pal-#4000 : ld c,32 : ld a,TXPG : call 2F
        ld a,#FF : ld (xr_md-#4000),a
9       WIN P_W2, PG_ZX+2
        ld a,(lp_w1) : ld b,a : ld a,#7F : sub b : ld bc,P_W1 : out (c),a
        pop af : ret po : ei : ret
1       ld de,xs_lm+#4000 : ld bc,32
2       push bc : ld b,a : ld a,#7F : sub b : ld bc,P_W2 : out (c),a : pop bc : ldir : ret
lp_ok   db 0
pf_fl   db 0                                    ; (0.66.9) the game's FLR at the draw: 1 - the 1st floor
pf_flo  db #FF                                  ; the floor under the ship's tiles (enl.asm te_flr; #FF: none)
lp_w1   db 0
m_q     equ #CA00                               ; (m_fmw) k = 0..298: k / 44; m_r (+512): k % 44 - made at the start
        ASSERT $ <= m_q                         ; (zxl.asm, after obj_img)
        display "obj end ",$
        ASSERT $ <= OB_Z0
        ENT
obj_img_end
