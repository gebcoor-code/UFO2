; ---- the text recognized in pixels (MX - MPG; far_m): the game's font's glyphs (GF), as they are, inverted or a tall
; letter's halves, found by a hash (epg.asm TX_RB: build/mktxr.py)
; (bd_y: the band's first line, B lines) its rows' text map: the DSCR's (CM_D, TA_D) -> screen 7's (CM_S, TA_S); a cell
; the DSCR's map has nothing for recognized in its pixels (tx_rcg: the game's font as it is, inverted, a tall letter's
; halves) - what the game put there without PRINT, or from its own copies (the geoscape's bottom display: LODMON)
; (TXPG at W1 meanwhile: CM_S #6000, CM_D #6400, TA_S #5000, TA_D #5400, the rows' flags #6300)
bd_tx   ld a,(bd_y) : ld c,a : add a,b : dec a : rrca : rrca : rrca : and 31 : ld b,a
        ld a,c : rrca : rrca : rrca : and 31 : ld c,a : ld a,b : sub c : ret c : inc a : ld b,a     ; C: the first row, B: rows
        push bc : WIN P_W1, TXPG : pop bc
1       push bc
        ld a,c : rrca : rrca : rrca : ld l,a : and 3 : ld (bt_q),a : ld a,l : and #E0 : ld l,a     ; (the row's cells: L)
        ld a,c : and #18 : or #90 : ld (bt_dh),a                            ; (the DSCR's: #9000 + row's third)
2       ld a,(bt_q) : or #64 : ld h,a : ld a,(hl) : or a : jr z,3F          ; (CM_D's)
        ld e,a : ld a,h : sub #10 : ld h,a : ld c,(hl) : jr 4F              ; (and TA_D's)
3       push hl : ld a,(bt_dh) : ld h,a : call tx_rcg : pop hl : ld e,a     ; (the DSCR's cell: W2; E: the character
4       ld a,(bt_q) : or #60 : ld h,a : ld (hl),e : ld a,h : sub #10 : ld h,a : ld (hl),c   ; + 1, C: its TA) -> CM_S, TA_S
        inc l : ld a,l : and 31 : jr nz,2B
        pop bc : ld hl,#6300 : ld a,c : add a,l : ld l,a : ld (hl),1
        inc c : djnz 1B
        ret
bt_q    db 0
bt_dh   db 0
; HL = a cell's line 0 (lines 256 apart; TXPG at W1: GF #6800, TX_RB #7C00) -> A = the character + 1 (0: none), C =
; its TA (0, 1 / 2: a tall letter's upper / lower half). A blank cell (all #00 / all #FF - most of them): its answer
; found once, then kept (rc_z0, rc_zf)
tx_rcg  ld a,(hl) : inc a : cp 2 : jr nc,0F                             ; (#00, #FF only)
        push hl : ld c,(hl) : ld b,7
01      inc h : ld a,(hl) : cp c : jr nz,02F : djnz 01B
        pop hl : ld a,c : or a : ld de,rc_z0 : jr z,03F : ld de,rc_zf
03      ld a,(de) : or a : jr z,04F
        inc de : ld a,(de) : inc de : ex de,hl : ld c,(hl) : ret
04      push de : call 0F : pop de
        ex de,hl : ld (hl),1 : inc hl : ld (hl),a : inc hl : ld (hl),c : ret
02      pop hl
0       ld de,rc_b : ld b,8 : xor a
1       rlca : xor (hl) : ld c,a : ld a,(hl) : ld (de),a : ld a,c : inc de : inc h : djnz 1B
        call 3F : ret nz                                                    ; (as it is)
        ld hl,rc_b : ld b,8 : xor a                                         ; (inverted: a menu's marked line)
2       ld c,a : ld a,(hl) : cpl : ld (hl),a : ld a,c : rlca : xor (hl) : inc hl : djnz 2B
        call 3F : ret nz
        xor a : ld c,a : ret
rc_z0   db 0, 0, 0                              ; (known; the character + 1, TA) for a cell all #00
rc_zf   db 0, 0, 0                              ;   all #FF
3       ld e,a                                                              ; (epg.asm tx_rp's way: the tag, then
        ld hl,rc_b : ld b,8 : xor a                                         ;  from the hash's entry on to a free one)
0       add a,(hl) : inc hl : djnz 0B
        and #FC : ld (rc_t),a
        rrca : rrca : and 7 : ld l,a : ld h,high rc_bm : ld a,(hl)          ; (tx_flt: a pattern of this hash and
        ld l,e : ld h,high tx_flt : and (hl) : ret z                        ;  tag's bits is in the table? - Z: none)
        ld l,e : ld h,0 : add hl,hl : add hl,hl : ld de,#7C00 : add hl,de
1       ld a,(hl) : or a : ret z
        inc hl : ld a,(hl) : inc hl : ld c,a : and #FC
        push hl : ld hl,rc_t : cp (hl) : pop hl : jr nz,4F
        ld a,c : and 3 : ld c,a : dec hl : dec hl : ld a,(hl) : inc hl : inc hl
        push hl : push af : call 5F : jr nz,41F
        pop af : pop hl : or a : ret                                        ; (NZ: found)
41      pop af : pop hl
4       ld a,h : cp #80 : jr c,1B : ld h,#7C : jr 1B                        ; (past the table's end: its start)
rc_t    db 0
5       dec a : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld de,#6800 : add hl,de   ; its glyph (GF)
        ld a,c : or a : jr z,6F : dec a : jr z,6F : inc hl : inc hl : inc hl : inc hl            ; (TA 2: lines 4..7)
6       ld de,rc_b : ld b,8
7       ld a,(de) : cp (hl) : ret nz
        ld a,c : or a : jr z,8F : ld a,b : and 1 : jr z,9F                  ; (tall: each line twice)
8       inc hl
9       inc de : djnz 7B
        xor a : ret
rc_b    ds 8
; xtil.asm tx_init's copy of epg.asm TX_RB (build/mktxr.py)
tx_rbi  incbin "txrb.bin"
; ---- (wideu.asm bat_off_u, before xp_std) the location's palette still on: both EGA buffers' pixels in its changed
; slots into the standard palette's nearest (rb_n: per slot that one - wideu.asm lp_set puts the location's there,
; build/mktil.py; the paper's slot kept) - else the field (green ground: slot 11) flashed magenta until the game's exit
; wipe covered it. A byte through rb_t (made here: 256)
bo_rmp  inc a : ret z                                           ; (A: wideu.asm xp_p - #FF: no location palette)
3       ld hl,rb_t : ld c,0                                      ; C: the byte
4       ld a,c : and 7 : bit 6,c : jr z,5F : or 8
5       call 8F : and 7 : bit 3,e : jr z,6F : or #40
6       ld b,a
        ld a,c : rrca : rrca : rrca : and 7 : bit 7,c : jr z,7F : or 8
7       call 8F : ld a,e : and 7 : add a,a : add a,a : add a,a : bit 3,e : jr z,71F : or #80
71      or b : ld (hl),a : inc hl : inc c : jr nz,4B
        ld (rb_sp),sp : ld sp,#3F60                            ; (own stack: the game's may be in W1, W2; DI)
        ld a,#7F-PS1 : ld e,#7F-PS5 : call 9F
        ld a,#7F-PS3 : ld e,#7F-PS7 : call 9F
        WIN P_W1, PG_ZX+5 : WIN P_W2, PG_ZX+2
        ld sp,(rb_sp) : ret
8       push hl : ld hl,rb_n : add a,l : ld l,a : jr nc,81F : inc h
81      ld e,(hl) : ld a,e : pop hl : ret                       ; (A: the slot -> E, A: its standard one)
; a buffer (W1: its pages A, W2: E): the 4 parts' 8000 bytes through rb_t
9       ld bc,P_W1 : out (c),a : ld a,e : ld b,H_W2 : out (c),a
        ld hl,#4000 : call 91F : ld hl,#6000 : call 91F : ld hl,#8000 : call 91F : ld hl,#A000
91      ld bc,8000 : ld d,high rb_t
92      ld e,(hl) : ld a,(de) : ld (hl),a : inc hl : dec bc : ld a,b : or c : jr nz,92B
        ret
; (as before 0.66.0 - an old UFO2.TIL: brown -> dim yellow, green, grey-green -> green, maroon -> red, pink -> bright red)
rb_n    db 0, 1, 2, 2, 4, 10, 6, 7, 6, 9, 10, 4, 12, 13, 14, 15
rb_sp   dw 0
        ALIGN 256
rb_t    ds 256
; (tx_rcg) a bit per pattern's hash (the byte) and its tag's bits 2..4 (the bit): build/mktxr.py's
tx_flt  incbin "txbf.bin"
rc_bm   db 1, 2, 4, 8, 16, 32, 64, 128

