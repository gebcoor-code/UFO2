; ---- the encyclopedia's pictures in EGA (XPG; its start: enc_u.asm in UPG). build/mkenc.py's UFO2.ENC: read from the
; disk when a picture is opened (enl.asm en_get: page SC_P0's tail, W2; the game's own pictures are not loaded:
; mods.py, the encyclopedia's JR). The game shows picture n (its encyclopedia module, bank 2: ABB7 draws bank 6's
; #C000 + (n % 3) * #1500 - whatever is there now - onto screen 7, then PUTATR rows 3 / 7.. with B = 28, C = 21:
; mk_atr -> ep_chk): ours decoded into PLA, PLB (free outside fights: parts 0, 1 / 2, 3, 5376 bytes each), then both
; buffers' x 0..223, lines 4..195; the shadow = screen 7 there (the conversion finds nothing changed: ours stays).
; A picture's data: the plane (LZ), the colours (LZ). No UFO2.ENC: en_get's message picture instead.
; (from ep_chk: DI, the game's windows) -> A = 0: not the module's picture; else its colours decoded into PLA, PLB
ep_prep ld hl,(#ABA9) : ld de,#0E61 : or a : sbc hl,de : ld a,0 : ret nz        ; (the module: ABA9 LD H,C : LD C,21)
        ld a,(#AB25) : or a : ld a,0 : ret nz
        ld a,(#AB24) : cp 60 : ld a,0 : ret nc : ld a,(#AB24) : ld (ep_n),a
        ld hl,(#3D3E) : ld (ep_iv),hl : ld hl,int_f : ld (#3D3E),hl : ei    ; (the music on till ep_fin's end: int_f
                                                                            ; keeps W1 / W2)
        ld a,SC_P0 : call ep_w2 : ld a,(ep_n) : call en_get                 ; -> A = its data's page, HL = where
        call ep_w2 : ld a,PLB : call ep_w1
        ld de,#4000+#2A00 : call ep_lz                                      ; its plane -> PLB #2A00
        ld a,PLA : call ep_w1 : ld de,#4000+#2A00 : call ep_lz              ; its colours -> PLA #2A00
        ld a,PLB : call ep_w2
        call ep_dec
        WIN P_W1, PG_ZX+5
        WIN P_W2, PG_ZX+2
        ld a,1 : ld (ov_bu),a : ret                     ; (PLB: the buttons there gone - ico.asm ov_dbt)
; both buffers from PLA, PLB; the shadow = screen 7 (rows 0..23, columns 0..27)
ep_fin  ld a,PS1 : call ep_cp : ld a,PS3 : call ep_cp
        ld a,PG_ZX+7 : call ep_w1
        ld c,0
4       ld b,8 : ld a,c : and #18 : or #40 : ld h,a : ld a,c : rrca : rrca : rrca : and #E0 : ld l,a
        ld a,c : add a,high SHP : ld d,a : ld e,0
5       push bc : push hl : push de : ld bc,28 : ldir : pop de : pop hl : pop bc
        inc h : ld a,e : add a,32 : ld e,a : djnz 5B
        ld a,c : rrca : rrca : rrca : ld l,a : and 3 : or #58 : ld h,a : ld a,l : and #E0 : ld l,a
        push hl : ld de,SHA-#5800 : add hl,de : ex de,hl : pop hl : push bc : ld bc,28 : ldir : pop bc
        inc c : ld a,c : cp 24 : jr c,4B
        ld hl,drow : ld b,48                    ; (the marks - groups, lines - of all 24 rows: nothing to convert)
6       ld (hl),0 : inc hl : djnz 6B
        ld hl,sc_rowf : ld b,24                 ; (and none of them looked for in the screen cache: its rows equal
7       ld (hl),0 : inc hl : djnz 7B            ;  screen 7's - the game's picture is always the same - would put a
                                                ;  previous screen's picture over ours - sc.asm sc_row1)
        di : ld hl,(ep_iv) : ld (#3D3E),hl
        WIN P_W1, PG_ZX+5
        WIN P_W2, PG_ZX+2
        ret
ep_w1   push af : push bc : ld b,a : ld a,#7F : sub b : ld bc,P_W1 : out (c),a : pop bc : pop af : ret
ep_w2   push af : push bc : ld b,a : ld a,#7F : sub b : ld bc,P_W2 : out (c),a : pop bc : pop af : ret
; A = the buffer's first page (1 / 3; the second + 4): the parts from PLA, PLB (#4000 + 5376 k) -> lines 4.., x 0..223
ep_cp   ld (ep_bp),a
        ld a,PLA : ld hl,0 : ld de,0 : call 1F                  ; part 0 -> page 1 +0 (as mkimg.py)
        ld a,PLA : ld hl,5376 : ld de,#2000 : call 1F           ; part 1 -> page 1 +#2000
        ld a,PLB : ld hl,0 : ld de,4 : call 1F                  ; part 2 -> page 5 +0
        ld a,PLB : ld hl,5376 : ld de,#2004                     ; part 3 -> page 5 +#2000
1       call ep_w1 : ld a,(ep_bp) : add a,e : call ep_w2
        ld e,0 : ld bc,#4000 : add hl,bc : ex de,hl : ld bc,#8000+4*40 : add hl,bc : ex de,hl
        ld a,192
2       ld bc,28 : ldir : ex de,hl : ld bc,12 : add hl,bc : ex de,hl : dec a : jr nz,2B
        ret
; the colours (PLA #2A00) over the pixels (PLB #2A00): W1 = PLA, W2 = PLB -> parts 0, 1 at #4000, #4000 + 5376,
; 2, 3 at #8000, #8000 + 5376 (28 a line). Alternate registers: HL' the colours, BC' pixels to skip, D' paper's
; colour now, E' ink's; ep_pc the next change's (#FF: none - read on)
ep_dec  ld ix,#8000+#2A00 : ld de,0
        ld a,#FF : ld (ep_pc),a : ld (ep_dt),a
        exx : ld hl,#4000+#2A00 : ld bc,0 : ld de,#0F00 : exx
1       ld c,(ix+0) : inc ix
        exx : ld a,b : or a : jr nz,5F : ld a,c : cp 8 : jr c,6F        ; 8 pixels or more to skip: as they are
5       ld a,c : sub 8 : ld c,a : jr nc,51F : dec b
51      exx
        ld a,(ep_dt) : or a : call nz,ep_mkq
        ld h,high ep_q
        ld a,c : rlca : rlca : and 3 : add a,low ep_q : ld l,a : ld a,(hl) : ld (ep_b),a
        ld a,c : rrca : rrca : rrca : rrca : and 3 : add a,low ep_q : ld l,a : ld a,(hl) : ld (ep_b+2),a
        ld a,c : rrca : rrca : and 3 : add a,low ep_q : ld l,a : ld a,(hl) : ld (ep_b+1),a
        ld a,c : and 3 : add a,low ep_q : ld l,a : ld a,(hl) : ld (ep_b+3),a
        jr 7F
6       exx
        call ep_pr : ld (ep_b),a
        call ep_pr : ld (ep_b+2),a
        call ep_pr : ld (ep_b+1),a
        call ep_pr : ld (ep_b+3),a
7       ld hl,#4000 : add hl,de : ld a,(ep_b) : ld (hl),a
        ld hl,#4000+5376 : add hl,de : ld a,(ep_b+1) : ld (hl),a
        ld hl,#8000 : add hl,de : ld a,(ep_b+2) : ld (hl),a
        ld hl,#8000+5376 : add hl,de : ld a,(ep_b+3) : ld (hl),a
        inc de : ld a,d : cp high 5376 : jp nz,1B : ld a,e : cp low 5376 : jp nz,1B
        ret
; ep_q: a pixel pair's EGA byte for its two class bits (high: the left; 1 ink, 0 paper) with the colours now
ep_mkq  xor a : ld (ep_dt),a
        exx : ld a,d : ld (ep_c0),a : ld a,e : ld (ep_c1),a : exx
        push bc : push de
        ld a,(ep_c0) : call 2F : ld d,b : ld e,c                ; D, E: paper's left, right bits
        ld a,(ep_c1) : call 2F                                  ; B, C: ink's
        ld a,d : or e : ld (ep_q),a
        ld a,d : or c : ld (ep_q+1),a
        ld a,b : or e : ld (ep_q+2),a
        ld a,b : or c : ld (ep_q+3),a
        pop de : pop bc : ret
2       ld h,high ep_el : add a,low ep_el : ld l,a : ld b,(hl) : add a,16 : ld l,a : ld c,(hl) : ret
ep_pr   call ep_px : add a,low ep_el : ld l,a : ld h,high ep_el : ld b,(hl)
        call ep_px : add a,low ep_er : ld l,a : ld h,high ep_er : ld a,(hl) : or b : ret
ep_px   rlc c : exx : jr c,.ink
.pap    ld a,b : or c : jr z,2F : dec bc : ld a,d : exx : ret
2       ld a,(ep_pc) : inc a : jr nz,3F : call ep_rd : jr .pap
3       dec a : ld d,a : ld a,1 : ld (ep_dt),a : call ep_rd : ld a,d : exx : ret
.ink    ld a,b : or c : jr z,2F : dec bc : ld a,e : exx : ret
2       ld a,(ep_pc) : inc a : jr nz,3F : call ep_rd : jr .ink
3       dec a : ld e,a : ld a,1 : ld (ep_dt),a : call ep_rd : ld a,e : exx : ret
ep_rd   ld a,(hl) : inc hl : cp #F0 : jr nc,1F
        ld c,a : and 15 : ld (ep_pc),a : ld a,c : rrca : rrca : rrca : rrca : and 15 : ld c,a : ld b,0 : ret
1       inc a : jr z,2F
        dec a : and 15 : ld b,a : ld c,(hl) : inc hl : jr 3F
2       ld c,(hl) : inc hl : ld b,(hl) : inc hl
3       ld a,#FF : ld (ep_pc),a : ret
; HL = the LZ stream (mkenc.py lz) -> DE: its data; HL after it
ep_lz   ld a,#80 : ld (ep_bb),a : ld bc,1 : ld (ep_of),bc
1       call 8F : jr c,3F                       ; after a match / at the start: 0 literals, 1 a new offset
        call 7F : ldir                          ; literals
        call 8F : jr c,3F                       ; after literals: 0 the last offset, 1 a new one
        call 7F : inc bc : jr 4F
3       call 7F : ld a,b : or a : ret nz        ; (256: the end)
        dec c : ld b,c : ld c,(hl) : inc hl : inc bc : ld (ep_of),bc
        call 7F : inc bc
4       push hl : ld h,d : ld l,e : push bc : ld bc,(ep_of) : or a : sbc hl,bc : pop bc : ldir : pop hl
        jr 1B
7       ld bc,1                                 ; a number: 1, then per "0, bit" a bit more, up to a 1
71      call 8F : ret c
        call 8F : rl c : rl b : jr 71B
8       ld a,(ep_bb) : add a,a : jr nz,81F      ; a bit -> CY
        ld a,(hl) : inc hl : rla
81      ld (ep_bb),a : ret
ep_bb   db 0
ep_iv   dw 0
ep_of   dw 0
ep_bp   db 0
ep_n    db 0
ep_pc   db 0
ep_b    ds 4
ep_dt   db 0
ep_c0   db 0
ep_c1   db 0
        ALIGN 32                                ; (ep_el, ep_er: within one 256 - LD H,high / ADD A,low)
ep_el   db #00,#01,#02,#03,#04,#05,#06,#07,#40,#41,#42,#43,#44,#45,#46,#47     ; the EGA bits of a slot: the left pixel
ep_er   db #00,#08,#10,#18,#20,#28,#30,#38,#80,#88,#90,#98,#A0,#A8,#B0,#B8     ; (bits 0-2, 6), the right one (3-5, 7)
        ALIGN 4
ep_q    ds 4
        ASSERT high ep_el == high (ep_er+15) && high ep_q == high (ep_q+3)
