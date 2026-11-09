; ------------------------------------------------------------------ xtil.asm's image (TLPG, TLPG2 #4000: img_out -> xt_hdr)
xtil_img
        DISP #4000
; ob_spr's sprite (W1 = TLPG, W3 = MPG: os_*; W2 = the game's bank 2): a tile's or A4P's figure's (its cell's tile,
; G_HIX + 7) lines into the plane where the game draws them. W2 back to bank 2, W3 to MPG (W3V) after.
PL_SPR  ld a,(pl_use) : or a : ret z
        ld (PL_SP),sp : ld sp,PL_SP                             ; (our stack: the game's may be in W2 / W3 - remapped
        call 0F                                                 ; here, the plane's writes over it)
pl_ret  ld sp,(PL_SP) : ret
pl_w1t  ld bc,P_W1 : ld a,#7F-TLPG : out (c),a : ret              ; (xpnt's replays: pl_do's end - any tile page)
0       ld a,(pl_exp) : or a : call nz,pl_xp                    ; (the fight's first: its tiles into TLPG, TLPG2)
        ld l,(ix+6) : ld h,(ix+7)
        push hl : ld de,-G_DATR : add hl,de : jr nc,3F
        ld a,h : or a : jr nz,3F : ld a,l : cp 128 : jr nc,3F
        rrca : rrca : and #1F : ld e,a                          ; A4P's DATR: its line; the tile under him
        ld hl,(G_HIX) : ld a,h : or l : jr z,3F
        ld bc,7 : add hl,bc : ld a,(hl) : and #7F : ld c,a
        pop hl : jr 4F
3       pop hl : ld de,-#B000 : add hl,de : ret nc
        ld a,h : cp #30 : ret nc
        ld a,l : rrca : rrca : and #1F : ld e,a                 ; the line
        add hl,hl : ld c,h                                      ; the code (rel >> 7)
4       ld a,c : cp TLN : ret nc
        ; all of it through the stack (TLPG2's variables are its own)
        call pf_get : push hl                                   ; (his frame: xs_pnt)
        ld b,c : ld c,e : push bc                               ; the code, its first line
        ld a,(os_n) : ld b,a : ld a,(os_cm) : ld c,a : push bc  ; lines, columns
        ld a,(os_r) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl
        ld a,(os_l) : ld e,a : ld d,0 : add hl,de : ld de,-32 : add hl,de : push hl   ; the plane's line (signed)
        ld a,(pl_mm) : cp #AE : ld a,0 : jr z,5F : ld a,#80     ; the game's tiles drawn as their masks only (the
5       ld c,a : ld a,(os_c) : sub 2 : ld b,a : push bc         ; unseen: black silhouettes): ours black
pl_sqd  call pl_fl                                              ; (0.66.9: a ship's tile on the 1st floor: the floor first)
        call pl_sq : jp z,pl_ret                                ; (drawn the same as the last time: nothing; the words dropped)
pl_do   call pl_mk                                              ; (its place marked: xpnt's)
        ld hl,7 : add hl,sp : ld a,(hl) : cp TL1 : jr c,6F
        cp TL2 : ld a,#7F-TLPG2 : jr c,5F : ld a,#7F-TLPG3
5       ld bc,P_W1 : out (c),a                                 ; (the same code there)
6       pop bc : ld a,b : ld (pl_x),a : ld a,c : ld (pl_md),a
        pop hl : ld (pl_y),hl
        pop bc : ld a,b : ld (pl_n),a : ld a,c : ld (pl_cm),a
        pop bc : ld a,b : ld (pl_cd),a : ld a,c : ld (pl_l0),a
        pop hl : ld (pl_pf),hl
        ; the lines on the plane (0..199) and in the tile (0..31)
        cp 32 : ret nc
        ld a,(pl_n) : or a : ret z
        ld hl,(pl_y) : bit 7,h : jr z,7F
        ld a,h : inc a : ret nz                                 ; above: skip -y
        ld a,l : neg : ld b,a : ld a,(pl_n) : sub b : ret c : ret z : ld (pl_n),a
        ld a,(pl_l0) : add a,b : cp 32 : ret nc : ld (pl_l0),a
        ld hl,0
7       ld a,h : or a : ret nz : ld a,l : cp 200 : ret nc
        ld a,200 : sub l : ld b,a : ld a,(pl_n) : cp b : jr c,71F : ld a,b
71      ld b,a : ld a,(pl_l0) : neg : add a,32 : cp b : jr nc,72F : ld b,a
72      ld a,b : ld (pl_n),a
        ld e,l : ld d,0 : ld h,d : add hl,hl : add hl,hl : add hl,de : add hl,hl : add hl,hl : add hl,hl  ; y * 40
        set 7,h : ld (pl_o),hl                                  ; (#8000 + y * 40)
        ld a,(pl_cd) : cp TL1 : jr c,8F : sub TL1 : cp TL2-TL1 : jr c,8F : sub TL2-TL1
8       ld b,a : add a,a : add a,a : ld (pl_tr),a               ; (tl_rng's)
        ld a,b : add a,high TLR : ld (pl_th),a                  ; the tile's page
        ld a,(W3V) : ld (pl_w3),a
        ld bc,P_W3 : ld a,#7F-PLB : ld (W3V),a : out (c),a     ; W3 = PLB (parts 1, 3), W2 = PLA (parts 0, 2)
        ld b,H_W2 : ld a,#7F-PLA : out (c),a
        push ix                                                 ; (pl_cl: IXL its count; ob_spr's IX)
        ld a,(pl_cm) : rrca : jr nc,9F
        ld a,(pl_x) : ld c,0 : call pl_cl                       ; the left column
        ld a,(pl_cm) : cp 3 : jr nz,91F
        ld a,(pl_x) : inc a : ld c,1 : call pl_cl : jr 91F      ; and the right one
9       ld a,(pl_cm) : and 2 : jr z,91F
        ld a,(pl_x) : ld c,1 : call pl_cl                       ; the right one only (at os_c)
91      pop ix
        call xs_pnt                                             ; (his figure over it)
        ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a            ; (W2: the game's bank 2 again)
        ld b,H_W3 : ld a,(pl_w3) : ld (W3V),a : out (c),a        ; (W3: MPG)
        ret
; xexp.asm tl_exp (W3 = MPG; W1 = TLPG again after it): the game draws its tiles - they are there now
pl_xp   xor a : ld (pl_exp),a
        ld a,(W3V) : push af
        ld bc,P_W3 : ld a,#7F-MPG : ld (W3V),a : out (c),a
        ld a,TLPG : call lp_set : call xm_put   ; (the location's palette - textr.asm; the frames' tables for it)
        ld a,TLPG : ld (te_w1),a : call tl_exp
        pop af : ld (W3V),a : ld bc,P_W3 : out (c),a : ret
; a column: A = its plane byte (0..39 else none), C = 0 left / 1 right: its lines with pixels (tl_rng) drawn; those
; of its opaque band (tl_opq: no none pixels) copied, the others through tl_nm (((plane ^ t) & nm) ^ t)
pl_cl   cp 40 : ret nc
        ld (pl_cx),a
        ld a,(pl_tr) : add a,c : add a,c : ld l,a : ld h,high tl_rng
        ld a,(pl_l0) : ld b,a : ld a,(hl) : cp b : jr nc,1F : ld a,b
1       ld d,a                                                  ; D = the first line (the tile's)
        inc l : ld a,(pl_n) : add a,b : ld b,a
        ld a,(hl) : cp b : jr c,2F : ld a,b
2       sub d : ret z : ret c : ld ixl,a                        ; IXL = the lines
        ld h,high tl_opq : ld b,(hl) : dec l : ld a,(hl)        ; the band: A its first, B its end
        sub d : jr nc,21F : xor a
21      cp ixl : jr c,22F : ld a,ixl
22      ld ixh,a : add a,d : ld e,a : ld a,b : sub e : jr nc,23F : xor a    ; IXH = the lines before it
23      ld e,a : ld a,ixl : sub ixh : cp e : jr c,24F : ld a,e
24      ld (pc_n2),a                                            ; in it (the rest after it)
        ld a,c : rrca : ld e,a : ld a,d : add a,a : add a,a : add a,e : ld e,a
        ld a,(pl_th) : push af : push de                        ; the tile's bytes: column * 128 + line * 4
        ld a,(pl_l0) : neg : add a,d : add a,low t40 : ld l,a : ld h,high t40   ; (the plane's line: * 40)
        ld e,(hl) : set 5,l : ld d,(hl)
        ld hl,(pl_o) : add hl,de : ld a,(pl_cx) : add a,l : ld c,a : ld a,h : adc a,0 : ld b,a   ; BC = the plane
        pop de : pop af : ld d,a
        ld h,high tl_nm
        ld a,(pl_md) : or a : jp nz,5F
        ld a,ixl : sub ixh : ld l,a : ld a,(pc_n2) : ld (pc_n3+1),a : neg : add a,l : ld (pc_n3),a
        ld a,ixh : or a : jr z,6F : ld ixl,a : call 3F
6       ld a,(pc_n3+1) : or a : jr z,7F : ld ixl,a : call 4F
7       ld a,(pc_n3) : or a : ret z : ld ixl,a
        ; parts 0, 2, 1, 3 at #8000, #A000, #C000, #E000 + o (B: #8x, #Ax, #Cx, #Ex)
3       ld a,(de) : ld l,a : ld a,(bc) : xor l : and (hl) : xor l : ld (bc),a : inc e
        set 5,b
        ld a,(de) : ld l,a : ld a,(bc) : xor l : and (hl) : xor l : ld (bc),a : inc e
        res 5,b : set 6,b
        ld a,(de) : ld l,a : ld a,(bc) : xor l : and (hl) : xor l : ld (bc),a : inc e
        set 5,b
        ld a,(de) : ld l,a : ld a,(bc) : xor l : and (hl) : xor l : ld (bc),a
        inc e
        ld a,c : add a,40 : ld c,a : ld a,b : adc a,#A0 : ld b,a        ; (#Ex + #A0: #8x the next line)
        dec ixl : jp nz,3B
        ret
4       ld a,(de) : ld (bc),a : inc e                           ; (the band: as they are)
        set 5,b
        ld a,(de) : ld (bc),a : inc e
        res 5,b : set 6,b
        ld a,(de) : ld (bc),a : inc e
        set 5,b
        ld a,(de) : ld (bc),a
        inc e
        ld a,c : add a,40 : ld c,a : ld a,b : adc a,#A0 : ld b,a
        dec ixl : jp nz,4B
        ret
5       ld a,(de) : ld l,a : ld a,(bc) : and (hl) : ld (bc),a : inc e  ; masks only: black
        set 5,b
        ld a,(de) : ld l,a : ld a,(bc) : and (hl) : ld (bc),a : inc e
        res 5,b : set 6,b
        ld a,(de) : ld l,a : ld a,(bc) : and (hl) : ld (bc),a : inc e
        set 5,b
        ld a,(de) : ld l,a : ld a,(bc) : and (hl) : ld (bc),a
        inc e
        ld a,c : add a,40 : ld c,a : ld a,b : adc a,#A0 : ld b,a
        dec ixl : jp nz,5B
        ret
pc_n2   db 0
pc_n3   dw 0
; ---- the draws' sequence (W1 = TLPG): between two OUTDSCs (iv_c) the game often draws the same tiles at the same
; places in the same order (around a fighter, each frame). The plane then gets nothing new - drawing a sequence again
; over its own result leaves it as it is (each pixel: the last draw covering it) - so while this interval repeats the
; last one draw by draw, nothing is drawn; at the first difference the skipped ones are drawn after all (sq_rp), and
; a scroll (pl_shf) ends the repeating too. A draw: its 4 words as PL_SPR pushed them (pl_do's input; 8 bytes); one
; list: the last interval's while this one repeats it, this one's from the first difference on
SQN     equ 12
SQE     equ 10                                  ; a draw's words: 5
SQ_B    equ sq_lst                       ; (xpnt's: TLPG only - read with it)
pl_sq   ld a,(as_on) : dec a : jp z,as_a1 : dec a : jp z,as_rec                     ; (a whole redraw: its list - as_*)
        ld hl,2 : add hl,sp : call rp_nt                                ; (a figure's place changed: xrep.asm)
        ld a,(iv_c) : ld hl,sq_iv : cp (hl) : call nz,sq_end
        ld a,(sq_m) : or a : jr z,5F
        ld a,(sq_i) : ld hl,sq_pn : cp (hl) : jr nc,4F
        call sq_ad : ex de,hl : ld hl,2 : add hl,sp : ld b,SQE           ; (SP: our return)
3       ld a,(de) : cp (hl) : jr nz,4F : inc hl : inc de : djnz 3B
        ld hl,2 : add hl,sp : call hb_key : jr c,4F                     ; (a moving figure there since: drawn)
        ld hl,sq_i : inc (hl) : xor a : ret                             ; Z: the same - not drawn
4       xor a : ld (sq_m),a : ld a,(sq_i) : or a : jr z,5F : ld b,a : call sq_rp
5       ld a,(sq_i) : cp SQN : jr nc,6F
        call sq_ad : ex de,hl : ld hl,2 : add hl,sp : ld bc,SQE : ldir
6       ld hl,sq_i : ld a,(hl) : inc a : jr z,7F : ld (hl),a
7       or 1 : ret                                                      ; NZ: drawn
; HL = the list's entry sq_i
sq_ad   ld a,(sq_i) : ld l,a : add a,a : add a,a : add a,l : add a,a : ld l,a : ld h,0 : ld de,SQ_B : add hl,de : ret
; an interval ended (A = iv_c): a shorter one's skipped part drawn now; the list is the last interval's
sq_end  ld (sq_iv),a : call hb_roll
        ld a,(sq_m) : or a : jr z,1F
        ld a,(sq_i) : ld hl,sq_pn : cp (hl) : jr z,3F                   ; (all of it again)
        or a : jr z,1F : ld b,a : call sq_rp
1       ld a,(sq_i) : cp SQN+1 : jr c,2F : xor a                        ; (more than SQN: none)
2       ld (sq_pn),a
3       xor a : ld (sq_i),a : ld a,(sq_pn) : or a : jr z,4F : ld a,1
4       ld (sq_m),a : ret
; a scroll: the skipped ones drawn first, nothing repeats across it
sq_cut  ld a,(sq_m) : or a : jr z,sq_inv
        ld a,(sq_i) : or a : jr z,sq_inv : ld b,a : call sq_rp
sq_inv  xor a : ld (sq_m),a : ld (sq_pn),a : dec a : ld (sq_i),a : jp hb_clr
; the list's first B draws (pl_do with their words; W1 = TLPG after each)
sq_rp   ld hl,SQ_B
1       push bc : push hl : call sq_r2
        ld bc,P_W1 : ld a,#7F-TLPG : out (c),a
        pop hl : ld bc,SQE : add hl,bc : pop bc : djnz 1B
        ret
; (as_*) HL = a draw's words (W1 = TLPG): drawn (pl_do), W1 = TLPG after it
as_dr   call sq_r2 : jp pl_w1t
sq_r2   ex de,hl : ld hl,-SQE : add hl,sp : ld sp,hl : ex de,hl : ld bc,SQE : ldir : jp pl_do
sq_i    db #FF                                  ; this interval's draws (#FF: more than counted)
sq_pn   db 0                                    ; the last interval's (0: none to repeat)
sq_m    db 0                                    ; 1: repeating it so far
sq_iv   db 0                                    ; iv_c of this interval
pl_ok   db 0                                    ; UFO2.TIL read
pl_use  db 0                                    ; the plane in use (TLPG's)
pl_exp  db 0                                    ; the tiles still to be made (the first PL_SPR: tl_exp)
pl_dir  db 0
pl_md   db 0                                    ; #80: masks only
pl_cd   db 0                                    ; the code (0..95)
pl_l0   db 0                                    ; the first line in the tile
pl_n    db 0                                    ; lines
pl_y    dw 0                                    ; the first line on the plane
pl_x    db 0                                    ; the plane byte of the first column (os_c - 2)
pl_cm   db 0
pl_o    dw 0                                    ; #8000 + the first line * 40
pl_th   db 0                                    ; the tile's high byte (its page's)
pl_w3   db 0                                    ; W3V at the start
pl_tr   db 0                                    ; the tile (this page's) * 4: tl_rng's
pl_cx   db 0
; A = a byte (signed) -> pp_p0 = its first pair
pp_x4   ld l,a : ld h,0 : rla : jr nc,1F : dec h
1       add hl,hl : add hl,hl : ld (pp_p0),hl : ret
; the lines (pq_y.., pp_n, pp_r0 the first's) on the plane's: pq_o its first's (part 0); Z: none
pp_clip ld hl,(pq_y) : bit 7,h : jr z,1F
        ld a,h : inc a : jr nz,9F                               ; above: skip -y lines
        ld a,l : neg : ld b,a : ld a,(pp_n) : sub b : jr c,9F : jr z,9F : ld (pp_n),a
        ld a,(pp_r0) : add a,b : ld (pp_r0),a : ld hl,0
1       ld a,h : or a : jr nz,9F : ld a,l : cp 200 : jr nc,9F
        ld a,200 : sub l : ld b,a : ld a,(pp_n) : cp b : jr c,2F : ld a,b
2       ld (pp_n),a : or a : ret z
        ld e,l : ld d,0 : ld h,d : add hl,hl : add hl,hl : add hl,de : add hl,hl : add hl,hl : add hl,hl
        set 7,h : ld (pq_o),hl : or 1 : ret
9       xor a : ret
; (pp_put) a line's 8 pairs, all drawn, not masks only: HL = the frame's 8 bytes -> pp_lb (colour - pl_pt's, pixels -
; xs_om's): BC the table and the byte
pp_fl   push ix : ld a,(pl_pt) : ld (pp_ft+1),a : ld de,pp_lb : ld ixl,8
2       ld c,(hl) : inc hl
pp_ft   ld b,0 : ld a,(bc) : ld (de),a : inc de
        ld b,high xs_om+#40 : ld a,(bc) : ld (de),a : inc de
        dec ixl : jr nz,2B
        pop ix : ret
; (xpnt.asm's as_add, as_sw, as_end: here for room)
; (W2 = ASPG) the old one's entries taken since as_rs (as_rs .. as_ob) into the new one
as_fl   ld hl,(as_rs) : ld a,h : or a : ret z
        ld de,(as_ob) : ex de,hl : or a : sbc hl,de : ld b,h : ld c,l
        ex de,hl : ld de,(as_np) : ldir : ld (as_np),de
        ld hl,0 : ld (as_rs),hl : ret
xtil_dend
        ENT
xtil_img_end
        display "xtil end ",xtil_dend
        ASSERT xtil_dend <= tl_rng
        ASSERT TL1 <= TLM && TL2 - TL1 <= TLM && TLN - TL2 <= TLM && TLR + TLM * 256 <= tl_opq


; ---- the moving things into the plane (TLPG, TLPG2 at XPNT: xt_hdr; past their tiles)
; A4P's figure (DATR; a fighter / alien coloured: ob_hero's os_hx): PL_SPR draws the tile under him, then his frame
; (UFO2.SPR) over it on the same lines and columns - the game's order: what it draws later in front covers him.
; After each hook (obj.asm ob_ent -> ob_post): GBU's moving one (a fighter's frame; else - bullets, blasts - its ZX
; picture: as ZX paper and ink, white and black) over the place under him, kept (gb_buf); PBU puts it back. The 3D cursor (PNTR:
; its 64 x 2 bytes kept in the parts' tails - each part 8000 bytes of its 8 K - at its first picture; POFF: back),
; its pictures as ZX ones. The draws' sequence (pl_sq) skips a draw only if none of these touched its place since it
; was drawn last (hb_p, hb_c: the places touched in the last interval and in this one).
XPA     equ tl_opq+4*TLM                ; (TLPG only: the hooks' part; gb_buf after it)
XPB     equ #7D50                       ; (TLPG and TLPG2: the painting pl_do does too)
; (the hooks' part: xpnt.asm - UFO2.DAT's, ram_init.asm mx_load; its constants here)
ASPG    equ 60
AS_E    equ 10                                  ; an entry: pl_do's words (md, x, y (2), columns, lines, l0, code, frame (2))
AS_W    equ 12                                  ; the old list's entries looked at for one
ASCHK   equ 0
AS_MX   equ 300                                 ; differences: more - all drawn
DB_C    equ #F4C0                               ; (MPG) 40 x 25: dirty cells (OB_Z0: zeroed at a fight's start)
FB_C    equ #F8B0                               ; (MPG) the cells drawn into otherwise since the last whole redraw
AS_L    equ #8000                               ; (W2) the new list from here up; the old one ends at #C000
xpb_img
        DISP XPB
; (pl_do, the tile drawn: W2 = PLA, W3 = PLB, so again after) his frame's line pl_l0 - 4 + k (DATR's line 4 his top)
; on the k-th line, the left half at the left column's byte, the right half at the right one's
xs_pnt  ld a,(pl_pf) : cp XF : ret nc
        ld hl,(pl_y) : ld (pq_y),hl
        ld a,(pl_n) : ld (pp_n),a
        ld a,(pl_l0) : sub 4 : ld (pp_r0),a
        ld a,(pl_x) : ld l,a : ld a,(pl_cm) : ld c,a : cp 2 : jr nz,1F : dec l
1       ld a,l : call pp_x4                                     ; the first pair's place
        xor a : bit 0,c : jr z,3F : or #F0
3       bit 1,c : jr z,4F : or #0F
4       ld (pp_pm),a
; the frame pl_pf (table pl_pt; pl_md #80: black) lines pp_r0.. (none outside 0..23) on the plane's lines pq_y..
; (pp_n of them), its pairs at pp_p0.. (pp_pm: the ones drawn, bit 7 the first). W2: its page, PLA after
pp_put  call pp_clip : ret z
        ld a,8 : ld (pp_np),a : call pp_pair : ret z
        ld a,(pl_pf) : ld c,SPG : cp XF1 : jr c,1F : sub XF1 : ld c,SPG2
1       ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld d,h : ld e,l : add hl,hl : add hl,de                 ; * 192
        ld de,XFR+#4000 : add hl,de : ld (pp_src),hl            ; (W2)
        ld a,#7F : sub c : ld (pp_pg),a
        ld a,(pp_n) : ld b,a : ld a,(pp_r0) : ld c,a
2       push bc
        ld a,c : cp 24 : jr nc,8F
        add a,a : add a,a : add a,a : ld l,a : ld h,0 : ld de,(pp_src) : add hl,de
        ld a,(pp_pg) : ld bc,P_W2 : out (c),a
        ld a,(pp_pm) : inc a : jr nz,31F : ld a,(pl_md) : or a : jr nz,31F
        call pp_fl : jr 6F                                      ; (all its pairs, in colour: xtil area's)
31      ld de,pp_lb : ld a,(pp_pm) : ld c,a : ld b,8
3       ld a,(hl) : inc hl : push hl
        ld l,a : ld h,high xs_om+#40
        rlc c : ld a,0 : jr nc,4F : ld a,(hl)                   ; its pixels (none in a column not drawn)
4       ld (pp_t),a
        ld a,(pl_md) : or a : ld a,0 : jr nz,5F                 ; (masks only: black)
        ld a,(pl_pt) : ld h,a : ld a,(hl)
5       ld (de),a : inc de : ld a,(pp_t) : ld (de),a : inc de
        pop hl : djnz 3B
6       ld bc,P_W2 : ld a,#7F-PLA : out (c),a
        call pp_ln
8       ld hl,(pq_o) : ld de,40 : add hl,de : ld (pq_o),hl
        pop bc : inc c : djnz 2B
        ret
; a line's pairs (pp_np from pp_p0) on the plane's: the first one there (pp_lbj its pp_lb's, pp_a its byte + part's
; offset, pp_ph its part), pp_c of them; Z: none
pp_pair ld hl,(pp_p0) : ld c,0
        bit 7,h : jr z,1F
        ld a,h : inc a : jr nz,9F
        ld a,l : neg : ld c,a : ld hl,0 : ld a,(pp_np) : cp c : jr z,9F : jr c,9F
1       ld a,h : or a : jr nz,9F : ld a,l : cp 160 : jr nc,9F
        ld a,160 : sub l : ld b,a
        ld a,(pp_np) : sub c : cp b : jr c,2F : ld a,b
2       ld (pp_c),a
        ld a,l : and 3 : ld (pp_ph),a : ld b,a
        ld a,l : rrca : rrca : and #3F : ld l,a : ld h,0
        ld a,b : or a : jr z,3F : ld h,#40 : dec a : jr z,3F : ld h,#20 : dec a : jr z,3F : ld h,#60
3       ld (pp_a),hl
        ld a,c : add a,a : add a,low pp_lb : ld l,a : ld a,high pp_lb : adc a,0 : ld h,a : ld (pp_lbj),hl
        or 1 : ret
9       xor a : ret
; (W2 = PLA, W3 = PLB) pp_lb's pairs (EGA byte, its pixels) onto the line pq_o: parts 0, 1, 2, 3 at #8x, #Cx, #Ax, #Ex
pp_ln ld hl,(pq_o) : ld de,(pp_a) : add hl,de
        ld de,(pp_lbj) : ld a,(pp_c) : ld b,a : ld a,(pp_ph) : ld c,a
1       inc de : ld a,(de) : dec de : or a : jr z,2F
        push bc : ld b,a : ld a,(de) : ld c,a : ld a,(hl) : xor c : and b : xor (hl) : ld (hl),a : pop bc
2       inc de : inc de
        ld a,c : inc c : or a : jr z,30F : dec a : jr z,31F : dec a : jr z,32F
        res 6,h : res 5,h : inc hl : ld c,0 : jr 4F
30      set 6,h : jr 4F
31      res 6,h : set 5,h : jr 4F
32      set 6,h
4       djnz 1B
        ret
pl_pf   db #FF                                  ; the draw's frame (#FF: none)
pl_pt   db 0                                    ; its table (W2)
po_k    db 0
pp_r0   db 0
pp_n    db 0
pp_pm   db 0
pp_np   db 0
pp_c    db 0
pp_ph   db 0
pp_t    db 0
pp_pg   db 0
pq_y    dw 0
pq_o    dw 0
pp_p0   dw 0
pp_a    dw 0
pp_lbj  dw 0
pp_src  dw 0
pp_lb   ds 24
; ---- the first PL_SPR of a fight (pl_xp; W3 = MPG): the frames' tables (xspr.asm xs_mkt's, in SPG and SPG2) for
; the location (xs_lm, xs_lf) - xp_fight makes them only when the field is first shown, the field is drawn before
xm_put  ld bc,P_W2 : ld a,#7F-SPG : out (c),a                ; W2 = SPG, W3 = SPG2 a while (their xs_lm, xs_lf:
        ld a,(W3V) : ld (gb_w3),a : ld b,H_W3 : ld a,#7F-SPG2 : ld (W3V),a : out (c),a     ; wideu.asm lp_set's)
        ld hl,xs_lm+#4000 : ld (xm_mp),hl : ld hl,xs_tab+#4000 : call 6F
        ld hl,xs_lf+#4000 : ld (xm_mp),hl : ld hl,xs_tf+#4000 : call 6F
        ld hl,xs_om+#4000 : ld c,0
7       ld a,c : and #F0 : cp #80 : ld a,0 : jr z,71F : ld a,#47
71      ld b,a : ld a,c : and #0F : cp 8 : ld a,b : jr z,72F : or #B8
72      ld (hl),a : inc l : inc c : jr nz,7B
        ld hl,xs_tab+#4000 : ld de,xs_tab+#8000 : ld bc,768 : ldir
        jp gb_unm
6       ld c,0
4       ld a,c : rrca : rrca : rrca : rrca : call 5F : ld b,a
        and 7 : ld e,a : ld a,b : and 8 : rlca : rlca : rlca : or e : ld e,a
        ld a,c : call 5F : ld b,a
        and 7 : rlca : rlca : rlca : or e : ld e,a : ld a,b : and 8 : rlca : rlca : rlca : rlca : or e
        ld (hl),a : inc l : inc c : jr nz,4B
        ret
5       and 15 : push hl : ld hl,(xm_mp) : add a,l : ld l,a : jr nc,51F : inc h
51      ld a,(hl) : pop hl : ret
xm_mp   dw 0
mp_xl   db #47                                  ; (mp_put) the ink's colour: the left pixel's bits, the right one's
mp_xr   db #B8                                  ; (white)
mp_ct   dw #B847, #B046, #9042, #1002, #1002    ; (gb_put) xBOOM / xBUM by their page: white, yellow, red, dark red
xpb_end
        ENT
xpb_img_end
        display "xpa end ",xpnt_end," buf end ",gb_buf+288," xpb end ",xpb_end
        ASSERT gb_buf + 288 <= XPB && xpb_end <= #8000
