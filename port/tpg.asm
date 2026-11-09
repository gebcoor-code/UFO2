;------------------------------------------------------------------ page TPG (code at #F400, W3): attribute tables
; slots 0..12: #C000 + s*#400: 4 tables (parts 0..3) of 256: the output byte for each pixel byte;
; #FC00: slot_of[attribute] = the slot's high byte (0: none), #FD00: slot_at[slot] = its attribute
tpg_img
        DISP #F400
; the column tables of row (cr): col_h[32] (high byte of the tables of each column's attribute), guni[4]
row_tabs
        call rt_h
        ; groups with one attribute
        ld hl,col_h : ld de,guni : ld c,4
3       ld a,(hl) : ld b,7 : push hl
4       inc hl : cp (hl) : jr nz,5F
        djnz 4B
        ld a,1 : jr 6F
5       xor a
6       ld (de),a : inc de
        pop hl : ld a,l : add a,8 : ld l,a : jr nc,7F : inc h
7       dec c : jr nz,3B
        ; col_hk[k][c] = col_h[c] + k, for the groups with more than one attribute
        ld hl,guni : ld c,0
8       ld a,(hl) : or a : jr nz,9F
        push hl : push bc
        ld b,0 : ld hl,col_h : add hl,bc : ld de,col_hk : ex de,hl : add hl,bc : ex de,hl   ; HL col_h+8g, DE col_hk+8g
        ld b,8
10      ld a,(hl) : push hl : push de : ex de,hl : ld de,32
        ld (hl),a : inc a : add hl,de : ld (hl),a : inc a : add hl,de : ld (hl),a : inc a : add hl,de : ld (hl),a
        pop de : pop hl : inc hl : inc de : djnz 10B
        pop bc : pop hl
9       inc hl : ld a,c : add a,8 : ld c,a : cp 32 : jr c,8B
        jp rt_sol
; (bc_t: col_h only - the wide fight's state B, tpg.asm bc_t1)
rt_h    ld hl,rt_st : inc (hl) : jr nz,0F : inc (hl)   ; this row's stamp (not 0)
0       ld hl,(rt_src) : ld de,col_h : ld b,32         ; the row's 32 attributes
        ld a,(hl) : cpl : ld c,a                        ; (C: the previous attribute - none)
1       ld a,(hl) : cp c : jr z,2F
        ld c,a : and #7F : call tslot : ld ixl,a        ; (FLASH ignored; #80 + : the fight's field)
2       ld a,ixl : ld (de),a : inc hl : inc e : djnz 1B
        ret
rt_st   db 0
; the group-lines of fmask on the current line, part by part, from the shadow (shd) into the back buffer (dst):
; SP = the end of the part's picture bytes, PUSH BC going down (byte 31 first); col_hk[k] = tables of the columns
line_out
        ld a,i : push af : di                   ; (SP fills: an interrupt's push would land in a group skipped; with
        ld (gsv),sp                             ; none skipped only past a part's start: lo_eic, lo_e)
        ; the type of each group: 0 skip, 1 one attribute, 2 mixed
        ld a,(fmask) : ld c,a : ld hl,guni : ld de,gtyp : ld b,4
1       xor a : rrc c : jr nc,2F
        ld a,(hl) : xor 1 : inc a                ; guni 1 -> 1, 0 -> 2, 3 -> 3 (solid)
2       ld (de),a : inc hl : inc de : djnz 1B
        call lo_eic
        xor a : ld (lo_k),a
.part   ld a,(lo_k) : ld hl,lo_ofs : add a,l : ld l,a : jr nc,3F : inc h
3       ld b,(hl)
        ld hl,(dst) : ld a,h : add a,b : ld h,a : ld a,l : add a,32 : ld l,a : jr nc,4F : inc h
4       ld sp,hl
.lo_e   nop                                     ; (lo_eic: EI - the music's ticks go on)
        ld hl,(shd) : ld a,l : or 31 : ld e,a : ld d,h
        ld a,(lo_k) : add a,a : add a,a : add a,a : add a,a : add a,a : ld c,a : ld b,0
        ld ix,col_hk : add ix,bc
        ld a,(gtyp+3) : or a : jp z,.s3 : cp 2 : jp z,.m3 : ld c,a   ; (C: 1 - one attribute, 3 - solid)
        ld a,(lo_k) : ld h,a : ld a,(col_h+24) : add a,h : ld h,a
        dec c : jp nz,.f3
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        jp .d3
.m3
        ld a,(de) : ld l,a : ld h,(ix+31) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+30) : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld h,(ix+29) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+28) : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld h,(ix+27) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+26) : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld h,(ix+25) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+24) : ld c,(hl) : dec e
        push bc
        jp .d3
.s3    ld hl,-8 : add hl,sp : ld sp,hl : ld a,e : sub 8 : ld e,a
.d3
        ld a,(gtyp+2) : or a : jp z,.s2 : cp 2 : jp z,.m2 : ld c,a   ; (C: 1 - one attribute, 3 - solid)
        ld a,(lo_k) : ld h,a : ld a,(col_h+16) : add a,h : ld h,a
        dec c : jp nz,.f2
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        jp .d2
.m2
        ld a,(de) : ld l,a : ld h,(ix+23) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+22) : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld h,(ix+21) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+20) : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld h,(ix+19) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+18) : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld h,(ix+17) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+16) : ld c,(hl) : dec e
        push bc
        jp .d2
.s2    ld hl,-8 : add hl,sp : ld sp,hl : ld a,e : sub 8 : ld e,a
.d2
        ld a,(gtyp+1) : or a : jp z,.s1 : cp 2 : jp z,.m1 : ld c,a   ; (C: 1 - one attribute, 3 - solid)
        ld a,(lo_k) : ld h,a : ld a,(col_h+8) : add a,h : ld h,a
        dec c : jp nz,.f1
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        jp .d1
.m1
        ld a,(de) : ld l,a : ld h,(ix+15) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+14) : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld h,(ix+13) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+12) : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld h,(ix+11) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+10) : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld h,(ix+9) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+8) : ld c,(hl) : dec e
        push bc
        jp .d1
.s1    ld hl,-8 : add hl,sp : ld sp,hl : ld a,e : sub 8 : ld e,a
.d1
        ld a,(gtyp+0) : or a : jp z,.s0 : cp 2 : jp z,.m0 : ld c,a   ; (C: 1 - one attribute, 3 - solid)
        ld a,(lo_k) : ld h,a : ld a,(col_h+0) : add a,h : ld h,a
        dec c : jp nz,.f0
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld c,(hl) : dec e
        jp .lp0
.m0
        ld a,(de) : ld l,a : ld h,(ix+7) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+6) : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld h,(ix+5) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+4) : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld h,(ix+3) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+2) : ld c,(hl) : dec e
        push bc
        ld a,(de) : ld l,a : ld h,(ix+1) : ld b,(hl) : dec e
        ld a,(de) : ld l,a : ld h,(ix+0) : ld c,(hl) : dec e
        jp .lp0
.lp0    di : push bc                            ; the part's start reached: an interrupt's push now would land below
        ld sp,(gsv)                             ; it, not ours - our stack again first
.lo_e2  nop                                     ; (lo_eic: EI)
        jr .d0
.s0    ld hl,-8 : add hl,sp : ld sp,hl : ld a,e : sub 8 : ld e,a
.d0
        ld hl,lo_k : inc (hl) : ld a,(hl) : cp 4 : jp c,.part
        ld sp,(gsv)
        pop af : ret po : ei : ret
.f3     ld l,0 : ld b,(hl) : ld c,b : push bc : push bc : push bc : push bc : ld a,e : sub 8 : ld e,a : jp .d3
.f2     ld l,0 : ld b,(hl) : ld c,b : push bc : push bc : push bc : push bc : ld a,e : sub 8 : ld e,a : jp .d2
lo_k    db 0
lo_ofs  db #00,#40,#20,#60
; A = attribute -> A = high byte of its tables (made now if needed); BC, DE, HL kept
; (round robin, but not a slot this row already uses: #FD80 + slot = the row's stamp)
tslot   push hl : push de : push bc
        ld l,a : ld h,#FC : ld a,(hl) : or a : jr z,0F
        push af : sub #C0 : rrca : rrca : ld l,a : ld h,#FD : set 7,l : ld a,(rt_st) : ld (hl),a : pop af
        jp 9F
0       ld c,l                                  ; the attribute
        ld a,(nslot) : ld e,a
11      ld a,(tnext) : ld b,a : inc a : push hl : ld hl,nslot : cp (hl) : pop hl : jr c,1F : xor a
1       ld (tnext),a
        ld l,b : ld h,#FD : set 7,l : ld a,(rt_st) : cp (hl) : jr nz,12F
        dec e : jr nz,11B                       ; (more than NSLOT attributes in a row: never mind)
12      ld (hl),a
        ld a,b : add a,a : add a,a : add a,#C0 : ld d,a         ; D = the slot's tables
        ld l,b : ld h,#FD : ld e,(hl) : ld (hl),c               ; slot_at: old attribute out, new in
        ld l,e : ld h,#FC : ld a,(hl) : cp d : jr nz,2F : ld (hl),0     ; the old one's tables gone
2       ld l,c : ld (hl),d
        ; part k: byte = LUT[pair k of the pixels][attribute]; pair k = bits 7-6, 5-4, 3-2, 1-0
        ld a,d : ld (tb_h),a
        ; the 4 output bytes of a pixel pair (00 01 10 11: left, right pixel ink?) for the attribute C (no LUT:
        ; window 0's LUT is the wide battlefield in a fight)
        ld a,c : and 7 : bit 6,c : jr z,5F : or 8
5       ld e,a                                  ; E = ink
        ld a,c : rrca : rrca : rrca : and 7 : bit 6,c : jr z,6F : or 8
6       ld d,a                                  ; D = paper
        bit 7,c : jr z,7F : set 3,e : res 3,d   ; (#80 + attribute: the fight's field: ink bright, paper dim)
7
        ld hl,tb_v
        ld a,d : call t_pl : ld b,a : ld a,d : call t_pr : or b : ld (hl),a : inc hl
        ld a,d : call t_pl : ld b,a : ld a,e : call t_pr : or b : ld (hl),a : inc hl
        ld a,e : call t_pl : ld b,a : ld a,d : call t_pr : or b : ld (hl),a : inc hl
        ld a,e : call t_pl : ld b,a : ld a,e : call t_pr : or b : ld (hl),a
        ; the 4 parts (runs of 64, 16, 4, 1 of v0..v3) with PUSH, from part 3's end down (an interrupt meanwhile
        ; pushes below SP: filled over afterwards)
        push ix : ld (tb_sp),sp
        ld a,(tb_h) : add a,4 : ld h,a : ld l,0 : ld sp,hl
        ld hl,(tb_v+2) : ld de,(tb_v)                           ; part 3: v0 v1 v2 v3 ... (HL = v3:v2, DE = v1:v0)
        ld b,64
3       push hl : push de : djnz 3B
        ld a,(tb_v+3) : ld h,a : ld l,a : ld a,(tb_v+2) : ld d,a : ld e,a
        ld a,(tb_v+1) : ld b,a : ld c,a : ld a,(tb_v) : ld ixh,a : ld ixl,a
        ld a,16                                                 ; part 2: runs of 4
4       push hl : push hl : push de : push de : push bc : push bc : push ix : push ix : dec a : jr nz,4B
        ld a,4                                                  ; part 1: runs of 16
5       push hl : push hl : push hl : push hl : push hl : push hl : push hl : push hl
        push de : push de : push de : push de : push de : push de : push de : push de
        push bc : push bc : push bc : push bc : push bc : push bc : push bc : push bc
        push ix : push ix : push ix : push ix : push ix : push ix : push ix : push ix
        dec a : jr nz,5B
        ld a,4                                                  ; part 0: runs of 64
6       push hl : push hl : push hl : push hl : push hl : push hl : push hl : push hl : dec a : jr nz,6B
        ld a,4
61      push de : push de : push de : push de : push de : push de : push de : push de : dec a : jr nz,61B
        ld a,4
62      push bc : push bc : push bc : push bc : push bc : push bc : push bc : push bc : dec a : jr nz,62B
        ld a,4
63      push ix : push ix : push ix : push ix : push ix : push ix : push ix : push ix : dec a : jr nz,63B
        ld sp,(tb_sp) : pop ix
        ld a,(tb_h)
9       pop bc : pop de : pop hl : ret
; colour A (0..15) -> the left / right pixel's bits of an output byte
; (the colour through t_rm first: in a location fight the slots the field took (wideu.asm xp_fight) are not the
; game's colours - those go to others)
t_pl    call t_map : push bc : ld b,a : and 7 : bit 3,b : pop bc : ret z : or #40 : ret
t_pr    call t_map : push bc : ld b,a : and 7 : rlca : rlca : rlca : bit 3,b : pop bc : ret z : or #80 : ret
t_map   push hl : ld hl,t_rm : add a,l : ld l,a : jr nc,1F : inc h
1       ld a,(hl) : pop hl : ret
t_rm    db 0, 1, 2, 3, 4, 5, 6, 7, 0, 9, 10, 11, 12, 13, 14, 15     ; (bright black: black - slot 8 is the fight's brown)
tb_h    db 0
tb_sp   dw 0
tb_v    ds 4

; ---- the wide fight (wide.asm): screen 7's row cw_r from window 0's buffers (AB_BUF, BL_BUF: lines of lmask)
; into the back buffer (W1, W2); its columns by the state and the row
cl_ex   equ #FEB0                       ; (32) column -> EGA byte, #FF: not now
        ASSERT high cl_ex == high col_h
bc_rt   call fs_chk                                     ; (bc_t's start: tpg6 is full)
        ld hl,AB_BUF : ld (rt_src),hl : jp rt_h
bc_cv                                                   ; (bc_t's end: tpg6 - its columns first)
        ld a,(BPOP) : or a : jr z,0F                    ; a popup (mx.asm wn_det): only its rows, not columns 0,
        ld a,(cw_r) : ld hl,WN_R0 : cp (hl) : ret c     ; 29..31 (state A's field, panel there)
        inc hl : cp (hl) : jr z,1F : ret nc
1       ld a,#FF : ld (cl_ex),a : ld (cl_ex+29),a : ld (cl_ex+30),a : ld (cl_ex+31),a
0       ld hl,cl_ex : ld c,0 : ld d,1                   ; the groups of all 8 columns converted (C): with all
1       ld b,8 : ld e,d                                 ; 8 lines their pending copy (scr.asm crw: not there)
2       ld a,(hl) : inc a : jr nz,3F : ld e,a           ; not needed
3       inc hl : djnz 2B
        ld a,c : or e : ld c,a : sla d : bit 4,d : jr z,1B
        ld a,(lmask) : inc a : jr nz,4F
        ld a,(cw_r) : ld hl,psync : add a,l : ld l,a : jr nc,5F : inc h
5       ld a,c : cpl : and (hl) : ld (hl),a
4       ld a,(cw_r) : call sync_row                     ; (W1, W2: the back buffer again)
bc_t1   ld d,0                                          ; (state B: wide.asm conv_rw)
        ; blank run (x 256..319 in B, x 232..295 in A's panel rows) and the groups for the other buffer
        xor a : ld (bc_zn),a
        ld a,(cmask) : ld e,a : and 8 : jr z,4F
        ld a,e : or #10 : ld e,a                        ; group 4 too
        ld a,d : cp 2 : jr z,4F
        ld a,8 : ld (bc_zn),a
        ld a,32 : dec d : jr nz,5F : ld a,29            ; (D was 1: A's panel row)
5       ld (bc_zf),a
4       ld a,d : cp 2 : ld a,e : jr nz,6F : and #10     ; (field row: only group 4)
6       ld (bc_g),a
        ld a,(BPOP) : dec a : jr nz,61F : ld (bc_zn),a          ; (a popup: x 256..319 state A's)
61
        ; column by column (its tables, its first line's place once), its marked lines down; a column of 8 equal
        ; bytes (blank: most of a window) - its 4 output bytes once
        ld a,(cw_r) : add a,a : add a,a : add a,a : add a,4 : ld (bc_y),a
        ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        ld de,#4000 : add hl,de : ld (bc_off),hl          ; part 0 of line 0's byte 0
        push ix : ld c,0 : ld ix,BL_BUF+128                                     ; (IX: the column's line 0 + 128)
8       ld a,c : add a,low cl_ex : ld l,a : ld h,high cl_ex : ld a,(hl) : cp #FF : jp z,9F
        ld de,(bc_off) : add a,e : ld e,a : jr nc,81F : inc d                   ; DE = line 0's part 0
81      ld a,l : sub low (cl_ex-col_h) : ld l,a : ld a,(hl) : ld (bc_tp),a      ; its tables
        push bc
        ld a,(lmask) : inc a : jr nz,80F                                        ; (not all 8 lines: one by one)
        ex de,hl : call bc_ck : jr nz,78F                                       ; (all 8 equal?)
        ld e,a : call bc_un : jr 89F                                            ; (blank: most of a window)
78      call bc_mx : jr 89F
80      push ix : call bc_pl : pop ix
89      pop bc
9       inc ix : inc c : bit 5,c : jp z,8B
        pop ix
        ; the blank run, the budget: line by line
        ld a,(lmask) : ld (bc_lm),a : ld hl,(bc_off) : ld (bc_src),hl
        ld b,8
7       push bc
        ld hl,bc_lm : rrc (hl) : jr nc,.nl
        ld a,(bc_zn) : or a : jr z,.nb
        ld hl,(bc_src) : ld a,(bc_zf) : add a,l : ld l,a : jr nc,10F : inc h   ; (bc_zn: 8 bytes)
10      ld de,#2000 : ld b,4 : xor a
11      push hl
        DUP 8
        ld (hl),a : inc hl
        EDUP
        pop hl : add hl,de : djnz 11B
.nb     ld hl,(budget) : ld de,4 : add hl,de : ld (budget),hl
.nl     ld hl,(bc_src) : ld de,40 : add hl,de : ld (bc_src),hl
        pop bc : djnz 7B
        ld a,(bc_g) : ld e,a : ld a,(lmask) : ld d,a
; the other buffer: row cw_r, groups E, lines D
bc_sy   ld a,e : or a : ret z
        ld a,(cw_r) : ld hl,bsync : add a,l : ld l,a : jr nc,1F : inc h
1       ld a,e : or (hl) : ld (hl),a : ld bc,SYN : add hl,bc : ld a,d : or (hl) : ld (hl),a
        ld a,1 : ld (bchg),a : ret
bc_y    db 0
bc_lm   db 0
bc_zn   db 0
bc_zf   db 0
bc_g    db 0
bc_src  dw 0
bc_off  dw 0
bc_tp   db 0
; (the field rows: fc_t2, tpg2.asm)
; the field's other buffer: row cw_r's lines D, groups E (state A's copy grid: the field's rows)
; (wide.asm conv_rw) the field row: the colour plane's marked groups, lines as they are (no conversion: the plane is
; all of the field's picture); without the plane: fc_t2
fc_t0   ld a,(PL_USE) : or a : jp z,fc_t2
        ld a,(fw_g) : ld (fc_cg),a : ld e,a
        ld a,(fw_l) : ld (fc_cl),a : ld d,a
fc_sy   ld a,e : or a : ret z
        ld a,(cw_r) : ld hl,bsync : add a,l : ld l,a : jr nc,1F : inc h
1       ld a,e : or (hl) : ld (hl),a : ld bc,SYN : add hl,bc : ld a,d : or (hl) : ld (hl),a
        ld a,1 : ld (bchg),a : ret
; the first time in a wide fight: slots 8..12 (the field's shadow now) out
fs_chk  ld a,(fs_new) : or a : ret z
        xor a : ld (fs_new),a
        ld b,FSLOT
1       ld a,b : ld l,a : ld h,#FD : ld e,(hl)          ; its attribute
        add a,a : add a,a : add a,#C0 : ld d,a
        ld l,e : ld h,#FC : ld a,(hl) : cp d : jr nz,2F : ld (hl),0
2       inc b : ld a,b : cp NSLOT : jr c,1B
        ld a,(tnext) : cp FSLOT : ret c : xor a : ld (tnext),a : ret
FSLOT   equ 4                           ; the wide fight: slots 4..11 are the field's shadow (8 of them)
FSH     equ #C000+FSLOT*#400            ; the field as shown: 40 x 200 (#D000..#EF3F)
        ASSERT FSH+8000 <= BL_BUF
; ---- the field's objects (obj.asm: planes M, C; ob_fl): row cw_r's groups with objects -> f2_ob; the
; colours' tables (the ground: fw_a, dim; ours dim, the one in focus bright, the aliens bright: on the field's paper)
ob_row  ld a,(bf) : xor 1 : add a,a : ld c,a : ld a,#7F-PS1 : sub c : ld (ob_p1),a : sub 4 : ld (ob_p2),a
        ld a,#7F-MPG : ld bc,P_W1 : out (c),a
        ld a,(cw_r) : add a,4 : ld e,a : ld d,0 : ld hl,ob_fl-#8000 : add hl,de
        ld a,(hl) : rrca : and #1F : ld (f2_ob),a
        ld de,ob_ff-ob_fl : add hl,de : ld a,(hl) : ld (hl),0 : rrca : and #1F : ld (f2_ff),a  ; (forced: out again)
        ld hl,f2_ob : or (hl) : ld (hl),a
        ld hl,ob_cur-#8000 : ld de,f2_cur : ldi
        ld a,(fw_a) : rrca : rrca : rrca : and 7 : ld b,a              ; the objects' attributes from the field's now (as
        add a,a : add a,a : add a,a : ld c,a : or b : or #80           ; ob_at: MPG's may be older - a window's
        ld (ob_a1),a : ld (ob_a2),a : ld a,c : or #82 : ld (ob_a3),a   ; attribute taken then: wrong hues)
        ld bc,P_W1 : ld a,(ob_p1) : out (c),a
        ld a,(f2_ob) : or a : ret z
        ld hl,rt_st : inc (hl) : jr nz,1F : inc (hl)            ; (these four slots kept in this row)
1       ld a,(ob_a2) : call tslot : ld (ob_t2),a
        ld a,(ob_a3) : call tslot : ld (ob_t3),a
        ld h,a : ld l,0 : ld a,(hl) : ld (ob_pb),a : ret        ; the paper (as in all of the four)
; a group with objects (BC = its first byte, DE = its field bytes, DE' = EGA); f2_mr: its bytes under a panel
ob_g0   ld hl,(f2_s) : add hl,bc
        xor a : ld (f2_mr),a
        ld a,(fc_f) : or a : call nz,f2_inv
ob_g1   ld hl,(f2_s) : add hl,bc
        ld a,(f2_gb) : push hl : ld hl,f2_ff : and (hl) : pop hl : call nz,f2_inv
        push hl : push de : ld b,8                              ; nothing different: nothing to do
0       ld a,(de) : cp (hl) : jr nz,0F : inc de : inc l : djnz 0B
        pop de : pop hl : jp f2_g5
0       pop de : pop hl
        ld b,8 : xor a : ld (ob_chg),a
1       ld a,(f2_mr) : rrca : ld (f2_mr),a : jp c,8F
        ld a,(de) : cp (hl) : jp z,9F           ; (forced groups: their shadow made different)
        ld (hl),a                               ; (as fc_t2: the objects are the colour plane's - xtil_i.asm; pl_post
        exx : ld l,a                            ; puts the plane over it)
        ld a,(hl) : ld (de),a : inc h : inc h : set 5,d
        ld a,(hl) : ld (de),a : dec h : ld a,d : xor #E0 : ld d,a
        ld a,(hl) : ld (de),a : inc h : inc h : set 5,d
        ld a,(hl) : ld (de),a : ld h,c : ld d,b
        exx : jr 7F
7       ld a,1 : ld (ob_chg),a : jr 9F
8       ld a,(de) : ld (hl),a                   ; under a panel: the shadow only
9       inc de : inc l : exx : inc e : exx
        dec b : jp nz,1B
        ld a,(ob_chg) : or a : jp z,f2_g5 : jp f2_g6
; (their variables: TPG #FF00.., past the image)
; #FF00..#FF0F: xspr.asm's (ob_fd, xs_*)
ob_o    equ #FF10                               ; (4)
f2_e    equ #FF14                               ; (2)
f2_s    equ #FF16                               ; (2)
f2_f    equ #FF18                               ; (2)
f2_gl   equ #FF1A                               ; (6)
f2_ob   equ #FF20                               ; the groups with objects in this row
f2_cur  equ #FF21
f2_gb   equ #FF22
ob_p1   equ #FF23                               ; the back buffer's ports (W1, W2)
ob_p2   equ #FF24
ob_a1   equ #FF26                               ; the objects' attributes (from obj.asm's ob_at; f2_cur, then these)
ob_a2   equ #FF27
ob_a3   equ #FF28
ob_t1   equ #FF29                               ; their tables
ob_t2   equ #FF2A
ob_t3   equ #FF2B
ob_pb   equ #FF2C
ob_x    equ #FF2D
ob_y    equ #FF2E
ob_cx   equ #FF2F
ob_k    equ #FF30
ob_chg  equ #FF31
f2_ff   equ #FF32                               ; the groups forced (M changed)
ob_mm   equ #FF33
ob_yr   equ #FF34
ob_yw   equ #FF35                               ; the marker's white pixels of the byte
ob_tw   equ #FF36                               ; its table
ob_mka  equ #FF37                               ; (2) mk_ad (obj.asm), 0: none
fc_sh   dw 0
fc_f    db 0
fc_la   db #FF
fc_th   db 0
fc_ln   db 0
fc_gm   db 0
fc_chg  db 0
fc_lc   db 0
fc_lb   db 0
fc_cg   db 0
fc_cl   db 0
        ENT
tpg_img_end
        display "tpg size ",tpg_img_end-tpg_img
        ASSERT tpg_img_end-tpg_img <= #800
; (and TPG #FED0..#FEFF, past cl_ex)
tpg5_img
        DISP #FED0
; line_out's interrupts: on while it fills (lo_e = EI) if no group of the line is skipped (an interrupt's push lands
; on bytes about to be written), int_f is the handler (its own stack; W3 back from W3V) and they were on before
lo_eic  ld a,(fmask) : and #0F : cp #0F : jr nz,1F
        ld hl,(#3D3E) : ld a,h : or a : jr nz,1F
        ld hl,2 : add hl,sp : bit 2,(hl) : jr z,1F                ; (line_out's pushed AF: P/V = IFF)
        ld a,#FB : ld (line_out.lo_e),a : ld (line_out.lo_e2),a : ei : ret
1       xor a : ld (line_out.lo_e),a : ld (line_out.lo_e2),a : ret
        ASSERT $ <= #FF00
        ENT
tpg5_img_end

; (TPG #FD10..#FD7F: past slot_at, below the stamps - init copies it after their clear)
tpg6_img
        DISP #FD10
bc_t    ld a,(LD_ON) : or a : ret nz           ; (a location loading: nothing - uipage.asm ld_beg)
        nop : nop : nop
        call bc_rt
        ld d,0 : ld a,(bst) : or a : jr nz,0F            ; D = 0: state B
        inc d : ld a,(cw_r) : dec a : cp 16 : jr nc,0F   ; 1: state A, rows 0, 17..23
        inc d                                           ; 2: state A, a field row
0       ld hl,cl_ex : ld c,0 : ld a,(cmask) : ld e,a
1       ld b,8 : rrc e : jr c,2F                        ; (a group: its 8 columns)
        ld a,#FF
11      ld (hl),a : inc hl : inc c : djnz 11B : jr 9F
2       ld a,d : or a : ld a,c : jr z,4F                 ; B: as is (but the fight's field's cells kept)
        cp 29 : jr c,21F
        add a,8 : jr 3F                                 ; A: columns 29..31 at x 296..319
21      bit 1,d : jr z,3F
        jr 5F                                           ; (A, field row: not 0..28)
4       ld a,(cw_r) : cp 17 : ld a,c : jr nc,3F                ; (the field's rows 1..16 only)
        push hl : ld l,c : ld h,high AB_BUF : ld a,(BC_CMP) : cp (hl) : ld a,c : pop hl : jr nz,3F
5       ld a,#FF                                        ; (B in a fight: the cells of the field's attribute - state
3       ld (hl),a : inc hl : inc c : djnz 2B            ;  A's colours stay under a popup; BC_CMP: mus.asm)
9       bit 5,c : jr z,1B
        jp bc_cv
        display "tpg6 end ",$
        ASSERT $ <= #FD80
        ENT
tpg6_img_end

; (TPG #FF40..#FFFF: past ob_mka - init copies it) bc_t1's full columns (all 8 lines) into the 4 parts: HL = line
; 0's part 0, (bc_tp) its tables; bc_un: E = its byte (all 8 the same), bc_mx: IX = BL_BUF + 128 + the column (its
; lines at ix-128 + 32 k). Part by part: its table, its 8 lines down (40 apart)
tpg7_img
        DISP #FF40
; not all 8 lines: one by one (DE = line 0's part 0, IX as bc_mx's)
bc_pl   ld a,(lmask) : ld (bc_lm),a : ld b,8
81      ld hl,bc_lm : rrc (hl) : jr nc,82F
        ld a,(bc_tp) : ld h,a : ld l,(ix-128) : push de
        ld a,(hl) : ld (de),a : ld a,d : add a,#20 : ld d,a : inc h : inc h     ; part 0; then 2
        ld a,(hl) : ld (de),a : ld a,d : add a,#20 : ld d,a : dec h             ; part 2; then 1
        ld a,(hl) : ld (de),a : ld a,d : add a,#20 : ld d,a : inc h : inc h     ; part 1; then 3
        ld a,(hl) : ld (de),a : pop de
82      ld hl,40 : add hl,de : ex de,hl
        ld a,ixl : add a,32 : ld ixl,a : jr nc,83F : inc ixh
83      djnz 81B
        ret
bc_un   ld bc,bc_u8 : jr 1F
bc_mx   ld bc,bc_m8
1       ld (bc_jp+1),bc
        ld a,(bc_tp) : ld d,a : ld bc,40
        push hl : call bc_jp : pop hl                                           ; part 0: table 0
        ld a,h : add a,#20 : ld h,a : inc d : inc d : push hl : call bc_jp : pop hl   ; part 1: table 2
        ld a,h : add a,#20 : ld h,a : dec d : push hl : call bc_jp : pop hl           ; part 2: table 1
        ld a,h : add a,#20 : ld h,a : inc d : inc d                                    ; part 3: table 3
bc_jp   jp 0
bc_u8   ld a,(de)
        DUP 7
        ld (hl),a : add hl,bc
        EDUP
        ld (hl),a : ret
bc_m8   ld e,(ix-128) : ld a,(de) : ld (hl),a : add hl,bc
        ld e,(ix-96) : ld a,(de) : ld (hl),a : add hl,bc
        ld e,(ix-64) : ld a,(de) : ld (hl),a : add hl,bc
        ld e,(ix-32) : ld a,(de) : ld (hl),a : add hl,bc
        ld e,(ix+0) : ld a,(de) : ld (hl),a : add hl,bc
        ld e,(ix+32) : ld a,(de) : ld (hl),a : add hl,bc
        ld e,(ix+64) : ld a,(de) : ld (hl),a : add hl,bc
        ld e,(ix+96) : ld a,(de) : ld (hl),a : ret
        display "tpg7 end ",$
        ASSERT $ <= #10000
        ENT
tpg7_img_end

; (TPG #FD8D..#FDFF: past the stamps, cleared at the start - init copies it after)
tpg8_img
        DISP #FD8D
; line_out's solid groups 1, 0 (tpg.asm: 3, 2 there)
line_out.f1 ld l,0 : ld b,(hl) : ld c,b : push bc : push bc : push bc : push bc : ld a,e : sub 8 : ld e,a : jp line_out.d1
line_out.f0 ld l,0 : ld b,(hl) : ld c,b : push bc : push bc : push bc : jp line_out.lp0
; (row_tabs' end) guni[g] 3: the group's one attribute has ink = paper (any pixels: one colour - line_out's gtyp 3)
rt_sol  ld hl,guni : ld bc,col_h
1       xor a : cp (hl) : jr z,2F
        ld a,(bc) : sub #C0 : rrca : rrca : push hl : ld l,a : ld h,#FD : ld a,(hl) : pop hl    ; (slot_at: its attribute)
        push bc : ld b,a : and 7 : ld c,a : ld a,b : rrca : rrca : rrca : and 7 : sub c : pop bc
        jr nz,2F : ld (hl),3
2       inc hl : ld a,c : add a,8 : ld c,a : cp low (col_h+32) : jr nz,1B
        ret
; IX = BL_BUF + 128 + a column: Z - its 8 lines the same byte (A)
bc_ck   ld a,(ix-128)
        cp (ix-96) : ret nz
        cp (ix-64) : ret nz
        cp (ix-32) : ret nz
        cp (ix+0) : ret nz
        cp (ix+32) : ret nz
        cp (ix+64) : ret nz
        cp (ix+96) : ret
        display "tpg8 end ",$
        ASSERT $ <= #FE00
        ENT
tpg8_img_end
