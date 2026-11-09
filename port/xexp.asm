; ---- the location's tiles in colour (MPG, mx.asm's part - W3; a fight's first sprite: xtil_i.asm pl_xp, W1 = TLPG back
; after it): each of the game's 96 tiles (bank 2's #3000.. for 0..31, bank 6's #0000.. for 32..95; 32 lines x (mask,
; ink) x 2) found in UFO2.TIL (build/mktil.py; its index in TIPG #2000 - at W1 here: N, the hashes, per 8 ids where
; their colours are) by its hash (H rotated left 3 + each byte, S the bytes' sum), its pixels' colours (the changes)
; drawn into TLPG / TLPG2 / TLPG3 as EGA bytes (none: slot 9); one not found: light grey ink on black; its columns'
; tl_rng, tl_opq. DI; W1, W2: the game's after.
; a column's line: (IX + OX) = its mask, ink -> its 4 EGA bytes at IY + OY (the pairs 0, 2, 1, 3). The colours the same
; for all its pixels (B' not below their number): by te_tt; else pixel by pixel (.pr)
        MACRO COL ox, oy
        ld d,(ix+ox) : ld e,(ix+ox+1)
        ld a,d : or a : jr z,81F                                ; (no pixels)
        and #0F : or low te_pc : ld l,a : ld h,high te_pc : ld c,(hl)
        ld a,d : rrca : rrca : rrca : rrca : and #0F : or low te_pc : ld l,a : ld a,(hl) : add a,c : ld c,a
        exx : ld a,b : exx : sub c : jr c,82F
        exx : ld b,a : exx
        ld a,(te_tv) : or a : call z,tl_exp.mkt
        ld a,low te_tt >> 4 : sla d : rla : sla d : rla : sla e : rla : sla e : rla : ld l,a : ld a,(hl) : ld (iy+oy),a
        ld a,low te_tt >> 4 : sla d : rla : sla d : rla : sla e : rla : sla e : rla : ld l,a : ld a,(hl) : ld (iy+oy+2),a
        ld a,low te_tt >> 4 : sla d : rla : sla d : rla : sla e : rla : sla e : rla : ld l,a : ld a,(hl) : ld (iy+oy+1),a
        ld a,low te_tt >> 4 : sla d : rla : sla d : rla : sla e : rla : sla e : rla : ld l,a : ld a,(hl) : ld (iy+oy+3),a
        jr 83F
81      ld a,#C9 : ld (iy+oy),a : ld (iy+oy+1),a : ld (iy+oy+2),a : ld (iy+oy+3),a : jr 83F
82      call tl_exp.pr : ld (iy+oy),a : call tl_exp.pr : ld (iy+oy+2),a
        call tl_exp.pr : ld (iy+oy+1),a : call tl_exp.pr : ld (iy+oy+3),a
83
        ENDM
TEW     equ #6000                       ; (TIPG at W1: its #2000.. - mktil.py's addresses #E000.. as XPG's were)
tl_exp  ld a,(PL_USE) : or a : ret z
        ld a,i : push af : di
        ld a,0 : jp po,1F : inc a
1       ld (te_ie),a                            ; (on: on again but for the hash - its POPs - the music goes on)
        ld (te_sp),sp : ld sp,#3F60             ; (W1 remapped: the game's stack may be there)
        push ix : push iy
        ld a,#C9 : ld (te_tt),a : ld (te_tt+1),a : ld (te_tt+2),a : ld (te_tt+3),a     ; (both none: these stay)
        xor a : ld (te_k),a
.tile   xor a : ld (te_nn),a
        ld a,(te_k) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        cp 32 : jr nc,1F
        ld de,#3000+#4000 : add hl,de : ld a,PG_ZX+2 : jr 2F
1       ld de,#4000-32*128 : add hl,de : ld a,PG_ZX+6
2       ld bc,P_W1 : neg : add a,#7F : out (c),a
        ld de,te_t : ld bc,128 : ldir
        ; the hash (its words: H rotated left 1 + the word; S the bytes' sum): HL = H, C = S
        di : ld (te_sp2),sp : ld sp,te_t : ld hl,0 : ld bc,64*256
3       add hl,hl : jr nc,$+3 : inc l : pop de : add hl,de
        ld a,c : add a,e : add a,d : ld c,a : djnz 3B
        ld sp,(te_sp2)
        ld a,(te_ie) : or a : jr z,$+3 : ei
        ld (te_h),hl : ld a,c : ld (te_s),a
        WIN P_W1, TIPG
        ; binary search: N at TEW, the entries (H high, H low, S) from TEW + 2
        ld hl,0 : ld (te_lo),hl : ld hl,(TEW) : dec hl : ld (te_hi),hl
4       ld hl,(te_hi) : bit 7,h : jp nz,.none : ld de,(te_lo) : or a : sbc hl,de : jp c,.none
        ld hl,(te_hi) : add hl,de : srl h : rr l : ld (te_md),hl            ; mid
        ld d,h : ld e,l : add hl,hl : add hl,de : ld de,TEW+2 : add hl,de   ; its entry
        ld a,(te_h+1) : cp (hl) : jr nz,5F : inc hl
        ld a,(te_h) : cp (hl) : jr nz,5F : inc hl
        ld a,(te_s) : cp (hl) : jr z,.found
5       ld hl,(te_md) : jr c,6F
        inc hl : ld (te_lo),hl : jr 4B                          ; (the key above)
6       dec hl : ld (te_hi),hl : jr 4B
        ; its 8 ids' part: after the hashes, (page - 0: XPG -, the address) per 8
.found  WIN P_W2, SC_P0 : call te_pt                           ; (its shape's edits - enl.asm: 0.57.0)
        ld hl,(TEW) : ld d,h : ld e,l : add hl,hl : add hl,de : ld de,TEW+2 : add hl,de : ex de,hl
        ld hl,(te_md) : srl h : rr l : srl h : rr l : srl h : rr l : ld b,h : ld c,l : add hl,hl : add hl,bc : add hl,de
        ld a,(hl) : inc hl : ld e,(hl) : inc hl : ld d,(hl) : or a : jr nz,71F
        ld a,d : sub #80 : ld d,a : jr 7F                       ; (TIPG's: at W1)
71      neg : add a,#7F : ld bc,P_W1 : out (c),a               ; (W1)
7       ld a,(te_md) : and 7 : jr z,9F : ld b,a : ex de,hl : ld a,9
8       cp (hl) : inc hl : jr nz,8B : djnz 8B                   ; (its id's: past the ones before - each ends with 9)
        ex de,hl
9       ld bc,15 : jr .exp
.none   ld de,te_end : ld bc,7                                  ; (light grey ink)
        ; the EGA tile -> its TLPG (W2): column c, line y's 4 bytes at c * 128 + y * 4 (parts 0, 2, 1, 3: the pixel pairs
        ; 0, 2, 1, 3); IY at column 0's + 64
.exp    ex de,hl : ld d,0 : ld e,c : call te_rd : exx            ; (HL' the changes, B' the pixels to skip, C' then the colour,
        xor a : ld (te_tv),a                                    ;  D' paper, E' ink now)
        ld a,(te_k) : cp TL1 : ld c,TLPG : jr c,12F : sub TL1 : ld c,TLPG2 : cp TL2-TL1 : jr c,12F
        sub TL2-TL1 : ld c,TLPG3
12      ld (te_j),a : add a,high (TLR-#4000+#8000) : ld h,a : ld l,64 : push hl : pop iy
        ld a,#7F : sub c : ld bc,P_W2 : out (c),a
        ld ix,te_t : ld b,32
10      push bc
        COL 0, -64
        COL 2, 64
        ld bc,4 : add ix,bc : add iy,bc : pop bc : dec b : jp nz,10B
        ; its columns' tl_rng, tl_opq
        ld a,(te_j) : add a,a : add a,a : ld e,a : ld d,high (tl_rng-#4000+#8000)
        ld hl,te_t : call te_rc : ld hl,te_t+2 : call te_rc
        ld a,(te_k) : inc a : ld (te_k),a : cp TLN : jp c,.tile
        WIN P_W2, SC_P0 : call te_flr                          ; (the floor under the ship: enl.asm, 0.58.0)
        ld a,(te_w1) : neg : add a,#7F : ld bc,P_W1 : out (c),a       ; (W1: the caller's)
        WIN P_W2, PG_ZX+2
        pop iy : pop ix
        ld sp,(te_sp)
        pop af : ret po : ei : ret
.pr     call te_px : add a,low te_el : ld l,a : ld h,high te_el : ld c,(hl)
        call te_px : add a,low te_er : ld l,a : ld a,(hl) : or c : ret
; te_tt: the 16 EGA bytes of a pair (its mask's 2 bits, its ink's 2: left first) with D' (paper), E' (ink) now (the first
; 4 - both none - stay). H = its high
.mkt    exx : push hl : push bc : push de
        ld h,high te_el
        ld a,d : or low te_el : ld l,a : ld b,(hl) : ld a,e : or low te_el : ld l,a : ld c,(hl)        ; (B, C: left paper, ink)
        ld a,d : or low te_er : ld l,a : ld d,(hl) : ld a,e : or low te_er : ld l,a : ld e,(hl)        ; (D, E: right)
        ld l,low te_tt+4
        ld a,d : or #41 : ld (hl),a : inc l : ld a,e : or #41 : ld (hl),a : inc l      ; (left none)
        ld a,d : or #41 : ld (hl),a : inc l : ld a,e : or #41 : ld (hl),a : inc l
        ld a,b : or #88 : ld (hl),a : inc l : ld (hl),a : inc l                        ; (right none)
        ld a,c : or #88 : ld (hl),a : inc l : ld (hl),a : inc l
        ld a,b : or d : ld (hl),a : inc l : ld a,b : or e : ld (hl),a : inc l
        ld a,c : or d : ld (hl),a : inc l : ld a,c : or e : ld (hl),a
        ld a,1 : ld (te_tv),a
        pop de : pop bc : pop hl : exx : ld h,high te_tt : ret
; the next pixel (D, E's top bits: mask, ink; shifted) -> A = its slot (9: none). The changes (mktil.py): HL' at the
; next one, B' its pixels to skip, C' its colour (9: G > 0 skip only, G = 0 the end), D' paper's colour now, E' ink's
te_px   sla d : jr c,1F : sla e : ld a,9 : ret
1       sla e : exx : jr c,.ink
.pap    ld a,b : or a : jr z,2F : dec b : ld a,d : exx : ret
2       ld a,c : cp 9 : jr nz,3F : call te_rd : jr .pap
3       and 15 : ld d,a : cp 9 : call z,te_nf : xor a : ld (te_tv),a : call te_rd : ld a,d : exx : ret
.ink    ld a,b : or a : jr z,2F : dec b : ld a,e : exx : ret
2       ld a,c : cp 9 : jr nz,3F : call te_rd : jr .ink
3       and 15 : ld e,a : cp 9 : call z,te_nf : xor a : ld (te_tv),a : call te_rd : ld a,e : exx : ret
te_nf   ld a,1 : ld (te_nn),a : ret                    ; (a colour "none": the tile has no opaque band - te_rc)
; HL's change -> B, C (the end - 9 - stays: B = 255 each time); skips only (#F9: 15) joined with the next ones: B up to
; 254; #G9 (G 1..14 - 0.56.0, mktil.py): skip G - 1, then the class's colour "none" (9: not drawn - the plane under it
; stays) - C = #19. (No byte but the end is 9: tl_exp finds a tile's colours by counting the ends.)
te_rd   ld b,0
1       ld a,(hl) : cp 9 : jr z,2F : inc hl
        cp #F9 : jr z,4F
        ld c,a : and 15 : cp 9 : jr z,3F
        ld a,c : rrca : rrca : rrca : rrca : and 15 : add a,b : ld b,a
        ld a,c : and 15 : ld c,a : ret
4       ld a,15 : add a,b : ld b,a : ld c,9 : cp 240 : jr c,1B : ret
3       ld a,c : rrca : rrca : rrca : rrca : and 15 : dec a : add a,b : ld b,a : ld c,#19 : ret
2       ld bc,#FF09 : ret
te_end  db 9
; a column of te_t (HL: its line 0's mask, 4 a line) -> DE's tl_rng: the first line with pixels, the last + 1 (none:
; #FF, 0); tl_opq (the same place): the longest run of lines without none pixels - its first, its end (none: 0, 0;
; several: the first). DE + 2
te_rc   push de : push hl
        ld bc,32*256 : ld de,4                                  ; (the first: from the top)
1       ld a,(hl) : or a : jr nz,2F : add hl,de : inc c : djnz 1B
        ld bc,#FF00 : jr 4F                                     ; (none)
2       pop hl : push hl : ld de,31*4 : add hl,de : ld de,-4 : ld b,32   ; (the last: from the bottom)
3       ld a,(hl) : or a : jr nz,31F : add hl,de : djnz 3B
31      ld a,b : ld b,c : ld c,a                                ; (B, C: the first, the last + 1)
4       ld (te_fl),bc
        ld a,(te_nn) : or a : jr z,41F
        pop hl : ld bc,0 : ld (te_ob),bc : jr 7F                ; (colours "none" in it: no opaque band)
41      pop hl : ld bc,0 : ld (te_ob),bc : ld (te_ol),bc        ; (B: the run's start, C: the line)
        ld de,4
5       ld a,(hl) : inc a : jr z,6F
        ld a,c : sub b : jr z,52F
        push hl : ld hl,te_ol : cp (hl) : jr c,51F : jr z,51F
        ld (hl),a : ld a,b : ld (te_ob),a : ld a,c : ld (te_ob+1),a
51      pop hl
52      ld b,c : inc b                                          ; (the run starts again past this line)
6       add hl,de : inc c : bit 5,c : jr z,5B
        ld a,c : sub b : ld hl,te_ol : cp (hl) : jr c,7F : jr z,7F
        ld a,b : ld (te_ob),a : ld a,c : ld (te_ob+1),a
7       pop hl : push hl : ld bc,(te_fl) : ld (hl),b : inc l : ld (hl),c
        ld a,h : add a,high (tl_opq-tl_rng) : ld h,a
        dec l : ld bc,(te_ob) : ld (hl),c : inc l : ld (hl),b
        pop de : inc e : inc e : ret
te_fl   dw 0
        ASSERT low tl_rng + (TLN-TL2)*4 <= 256 && low tl_opq == low tl_rng
te_nn   db 0                                            ; 1: the tile has pixels of colour "none" (te_nf)
te_ie   db 0                                            ; 1: interrupts were on (the music: int_f - W3 back from W3V)
te_ol   db 0
te_ob   dw 0
te_k    db 0
te_sp   dw 0
te_sp2  dw 0
te_j    db 0
te_w1   db TLPG
te_h    dw 0
te_s    db 0
te_lo   dw 0
te_hi   dw 0
te_md   dw 0
te_tv   db 0                                            ; te_tt made for the colours now
        ALIGN 64                                        ; (te_el, te_er: 16-aligned too)
te_tt   ds 16                                           ; .col's EGA bytes of a pair
te_pc   db 0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4              ; a nibble's bits
te_el   db #00,#01,#02,#03,#04,#05,#06,#07,#40,#41,#42,#43,#44,#45,#46,#47     ; the EGA bits of a slot: the left pixel
te_er   db #00,#08,#10,#18,#20,#28,#30,#38,#80,#88,#90,#98,#A0,#A8,#B0,#B8     ; (bits 0-2, 6), the right one (3-5, 7)
        ASSERT high te_tt == high (te_er+15)
