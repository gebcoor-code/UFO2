; ---- the text layer's drawing: TXPG's code (this image -> TXPG #0000 by img_out; W3 = TXPG while it runs, its
; data at #E000..: text.asm). From ov_fl's end through text.asm tx_fl (tx_sw: the landing below).
; Every row with text the step changed in the back buffer (bsync groups, lines): each changed group's cells with a
; character in CM_S (not one ours draws as the game: tc_tv) - each changed line of the cell that is the conversion's
; picture of that glyph line in the cell's two colours (any palette: the fights' too) gets ours (OF); the colours from
; two of its pixels that are the same in both.
; A = 1: the back buffer's cursor off first (ov_fl3 calls again), else 0.
TX_CS   equ #E000                       ; CM_S (W3)
TX_RF   equ #E300                       ; its rows' flags
TX_TA   equ #D000                       ; TA_S: 1 / 2 the tall letter's upper / lower cell, 3 the clock's, else 0 (TA_D #D400)
TX_GF   equ #E800
TX_OF   equ #F000
tc_pt   equ #DE00                       ; the pairs' table (16: class left * 4 + right)
TC_TH   equ #F800                       ; (tc_dir) by a class byte (4 pixels): its left pair's output byte (OF ends at #F7FF)
TC_TL   equ #F900                       ;   its right pair's
nm_s    equ #DF00                       ; nm_cv's: the word's first cell
NM_B    equ #7C00                       ; (NMPG at W1: the word - panel.asm pn2_nconv)
TX_SP   equ #C800                       ; per TA (512 each), character: its two colour pixels + 1 (tc_cp; #FF none, 0 not yet)
XR_T    equ #D800                       ; xp_rmp: the bytes' map (256), the slots' (16, XR_M)
XR_M    equ #D900
TX_TV   equ #C780                           ; per character: ours = the game's (tc_tv)
txc_img
        DISP #C000
txf     xor a : ld (tc_lv),a : ld (tc_r),a                ; (tc_wd: kept over the cursor's call again)
        WIN P_W1, UPG : ld a,(xp_p-#8000) : inc a : ld (tc_fi),a         ; (0: the standard palette; else the fight field's)
        ld a,(bf) : or a : ld a,#7F-PS3 : jr z,0F : ld a,#7F-PS1                ; (W1: the back buffer again, as ov_fl leaves it)
0       ld bc,P_W1 : out (c),a
1       ld a,(tc_r) : ld e,a : ld d,0
        ld hl,TX_RF : add hl,de : ld a,(hl) : or a : jp z,8F
        ld hl,bsync : add hl,de : ld a,(hl) : and #0F : jp z,8F                 ; (bsync: what changed in the back buffer
        ld (tc_g),a                                                             ;  since the flip - all of it each step)
        ld hl,bsync+SYN : add hl,de : ld a,(bwide) : or a : ld a,(hl) : jr nz,09F       ; (not in the wide fight: all its
        ld a,#FF : ld (hl),a                                                    ;  lines - a cell skipped while
09      ld (tc_lm),a                            ; its shadow was converted in part kept the lines converted then - one
                                                ; colour - when the rest came in the next step; the flip copies them all;
                                                ; the wide fight: only those changed - its scroll moves the buffers' lines,
                                                ; the old ones copied again from the front left stripes)
        ld a,(tc_r) : rrca : rrca : rrca : ld l,a : and 3 : add a,high TX_CS : ld h,a : ld a,l : and #E0 : ld l,a
        ld (tc_rp),hl
        call tc_rw                                                              ; (the back buffer, its line 0)
        xor a : ld (tc_c),a : ld a,(tc_g) : ld (tc_gg),a
        ; the changed groups' 8 columns each
2       ld a,(tc_gg) : rrca : ld (tc_gg),a : jr c,3F
        ld a,(tc_c) : add a,8 : ld (tc_c),a : cp 32 : jr c,2B : jp 80F
3       ld hl,(tc_rp) : ld a,(tc_c) : add a,l : ld l,a
4       call tx_cv : or a : jr nz,5F                                            ; (epg.asm: the map's, recognized)
        inc l : ld a,(tc_c) : inc a : ld (tc_c),a : and 7 : jr nz,4B
        ld a,(tc_c) : cp 32 : jr c,2B : jp 80F
5       ld (tc_ch),a
        ld a,(BPOP) : or a : jr z,55F : ld a,(tc_c) : or a : jp z,7F : cp 29 : jp nc,7F    ; (a popup in the wide fight:
55                                                                              ;  columns 0, 29..31 state A's - tpg.asm bc_cv)
        ld a,h : sub #10 : ld h,a : ld a,(hl) : ld (tc_ta),a                                          ; (TA)
        ld a,(tc_ch) : call tc_tv : jp z,7F                                          ; (ours = the conversion's)
        ld a,(tc_ta) : or a : jr nz,51F                                         ; (a plain glyph: direct - not the wide
        ld a,(bwide) : or a : jr z,52F : ld a,(bst) : or a : jr z,51F           ;  fight's state A; its state B: from
        jr 53F                                                                  ;  screen 7 itself; else not the fight's
52      ld a,(tc_fi) : or a : jr nz,51F                                         ;  palette: from the shadow)
53      ld (tc_s7),a
        call tc_bb : ret nz                                                         ;  from GF / OF in place)
        ld a,(tc_ch) : dec a : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl
        ld de,TX_GF : add hl,de : ld (tc_dx),hl : add hl,hl                       ; (GF + 8 n -> OF + 16 n)
        ld de,(TX_OF-2*TX_GF)&#FFFF : add hl,de : ld (tc_do),hl
        call tc_dir : jp nc,7F
51      ld hl,tc_x : ld (tc_dx),hl : ld hl,tc_o : ld (tc_do),hl
        ; the glyph's lines (GF; tall: its half's lines twice) -> tc_x, ours (OF) -> tc_o
        ld a,(tc_ch) : dec a : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : push hl
        ld de,TX_GF : add hl,de : ld de,tc_x : ld c,1 : call tc_ln
        pop hl : add hl,hl : ld de,TX_OF : add hl,de : ld de,tc_o : ld c,2 : call tc_ln
        call tc_bb : ret nz
        ld a,(tc_ta) : or a : jr z,6F                                           ; (a tall one, the clock's: direct here -
        ld a,(bwide) : or a : jr z,54F : ld a,(bst) : or a : jr z,6F            ;  not in the wide fight's state A; its
54      ld (tc_s7),a                                                            ;  state B: from screen 7)
        call tc_dir : jp nc,7F
6       call tc_cp : jp c,7F                    ; (the cell's colours from the buffer: none - not this glyph there)
        call tc_col
        ; the lines the step changed: the conversion's glyph line there -> ours (ours already, or else: as it is)
        ld a,(tc_lm) : ld (tc_m),a
        ld hl,(tc_ad) : ld ix,tc_o : ld iy,tc_x : ld b,8
22      ld a,(tc_m) : rrca : ld (tc_m),a : call c,tc_lr
        ld a,l : add a,40 : ld l,a : jr nc,23F : inc h
23      inc ix : inc ix : inc iy : djnz 22B
7       ld a,(tc_c) : inc a : ld (tc_c),a : and 7 : jp nz,3B
        ld a,(tc_c) : cp 32 : jp c,2B
80
8       ld a,(tc_r) : inc a : ld (tc_r),a : cp 24 : jp c,1B
9       ld a,(tc_wd) : or a : jr z,91F : ld (bchg),a            ; (drawn: the back buffer changed - to be shown)
        xor a : ld (tc_wd),a
91      xor a : ret
; the back buffer into W1, W2; tc_ad: the cell's line 0 (y = 4 + 8r: byte y * 40 + c; W1: pixels 0, 1; W2: 2, 3;
; W1 + #2000: 4, 5; W2 + #2000: 6, 7). NZ (A = 1): the back's cursor is on - off first
tc_bb   ld a,(brec) : or a : jr z,0F                ; (the back's cursor: only if over this cell - 10 x 11 at brec+1, +3)
        ld a,(tc_c) : add a,a : add a,a : add a,a : ld e,a : ld d,0
        ld hl,(brec+1) : ld bc,10 : add hl,bc : or a : sbc hl,de : jr c,0F : jr z,0F
        ld hl,(brec+1) : ld a,e : add a,8 : ld e,a : jr nc,01F : inc d
01      or a : sbc hl,de : jr nc,0F
        ld a,(tc_r) : add a,a : add a,a : add a,a : add a,4 : ld e,a
        ld a,(brec+3) : add a,11 : cp e : jr c,0F : jr z,0F
        ld a,e : add a,8 : ld e,a : ld a,(brec+3) : cp e : jr nc,0F
        ld a,1 : or a : ret
0       ld hl,(tc_rb) : ld a,(tc_c) : add a,l : ld l,a : jr nc,1F : inc h      ; (the row's: txf - tc_rw)
1       ld (tc_ad),hl : xor a : ret
; (txf, a row) W1, W2: the back buffer; tc_rb: the row's line 0 (y = 4 + 8r: y * 40, W1)
tc_rw   ld a,(bf) : or a : ld a,#7F-PS3 : ld e,#7F-PS7 : jr z,1F : ld a,#7F-PS1 : ld e,#7F-PS5
1       ld bc,P_W1 : out (c),a : ld a,e : ld b,H_W2 : out (c),a
        ld a,(tc_r) : add a,a : add a,a : add a,a : add a,4 : ld l,a : ld h,0
        add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        ld de,#4000 : add hl,de : ld (tc_rb),hl : ret
tc_rb   dw 0
; character A (code: + 1): Z = ours is the game's glyph as it is (only the cell's and the letter's classes where its
; 1s / 0s are: nothing to draw); TV caches it (0 not yet, 1 so, 2 not)
tc_tv   dec a : ld e,a : ld d,0 : ld hl,TX_TV : add hl,de : ld a,(hl) : or a : jr nz,9F
        push hl
        ld l,e : ld h,0 : add hl,hl : add hl,hl : add hl,hl : push hl : ld bc,TX_GF : add hl,bc
        ex (sp),hl : add hl,hl : ld bc,TX_OF : add hl,bc : ex de,hl : pop hl          ; HL: GF, DE: OF
        ld b,8
1       ld c,(hl) : push bc : push hl
        ld b,8 : ld hl,0
2       add hl,hl : add hl,hl : rlc c : jr c,3F : inc l                                ; (0: the letter, 1)
3       djnz 2B
        ld a,(de) : cp h : jr nz,4F : inc de : ld a,(de) : cp l : jr nz,4F : inc de
        pop hl : pop bc : inc hl : djnz 1B
        ld a,1 : jr 5F
4       pop hl : pop bc : ld a,2
5       pop hl : ld (hl),a
9       cp 1 : ret
; the cell's colours from the back buffer (tc_ad: its line 0 in W1): a pixel of the glyph's 1s (ZX ink) that is
; the cell's class in ours -> tc_k, of its 0s that is the letter's class -> tc_p (the same in the conversion's picture
; and in ours); the two pixels found once per character and TA (TX_SP). C: none, or one colour only
tc_cp   ld a,(tc_ch) : dec a : ld l,a : ld a,(tc_ta) : ld h,a : add hl,hl : ld de,TX_SP : add hl,de     ; (TA * 512 / 2...)
        ld a,(hl) : or a : jr nz,2F
        push hl : call tc_sp : pop hl : ld a,#FF : jr c,3F
        ld a,(tc_pk) : inc a : ld (hl),a : inc hl : ld a,(tc_pp) : inc a : ld (hl),a : dec hl : ld a,(hl)
2       cp #FF : scf : ret z
        dec a : ld (tc_pk),a : inc hl : ld a,(hl) : dec a : ld (tc_pp),a : jr 4F
3       ld (hl),a : ret
4       ld a,(tc_pk) : call 5F : ld (tc_k),a
        ld a,(tc_pp) : call 5F : ld (tc_p),a
        ld hl,tc_k : cp (hl) : scf : ret z
        or a : ret
5       ld c,a : and 7 : ld d,a : ld a,c : rrca : rrca : rrca : and 7 : ld b,a          ; (line * 8 + pixel)
        ld hl,(tc_ad) : or a : jr z,7F : ld a,l
6       add a,40 : jr nc,61F : inc h
61      djnz 6B
        ld l,a
7       jp tc_px
; the two pixels (line * 8 + pixel) in tc_x / tc_o -> tc_pk (ink, the cell's class), tc_pp (paper, the letter's). C: not both
tc_sp   ld a,#FF : ld (tc_pk),a : ld (tc_pp),a
        ld ix,tc_x : ld iy,tc_o : ld b,0
1       ld c,(ix+0) : ld d,(iy+0) : ld e,(iy+1)
2       ld a,d : and #C0 : ld h,a
        rlc c : jr nc,3F
        ld a,h : or a : jr nz,4F : ld a,(tc_pk) : inc a : jr nz,4F : ld a,b : ld (tc_pk),a : jr 5F
3       ld a,h : cp #40 : jr z,31F : cp #80 : jr nz,4F             ; (the letter: its dim or its light class - a tall
31      ld a,(tc_pp) : inc a : jr nz,4F : ld a,b : ld (tc_pp),a     ;  letter's upper cell has the light one only)
5       ld a,(tc_pk) : inc a : jr z,4F : ld a,(tc_pp) : inc a : jr nz,6F      ; (both found: done)
4       sla e : rl d : sla e : rl d
        inc b : ld a,b : and 7 : jr nz,2B
        inc ix : inc iy : inc iy : ld a,b : cp 64 : jr c,1B
        ld a,(tc_pk) : inc a : scf : ret z
        ld a,(tc_pp) : inc a : scf : ret z
6       or a : ret
; pixel D (0..7) of line HL (W1) -> its colour (C, E used)
tc_px   push hl
        ld a,d : and 2 : jr z,1F : set 7,h : res 6,h
1       ld a,d : and 4 : jr z,2F : set 5,h
2       ld a,(hl) : pop hl : ld c,a
        bit 0,d : jr nz,3F
        and 7 : ld e,a : ld a,c : rrca : rrca : rrca : and 8 : or e : ret                   ; (left: bits 0-2, 6)
3       rrca : rrca : rrca : and 7 : ld e,a : ld a,c : rrca : rrca : rrca : rrca : and 8 : or e : ret   ; (right: 3-5, 7)
; the conversion's 4 pairs (index: left bit * 2 + right bit; 1 = ink) -> tc_e
tc_pe   ld a,(tc_p) : call tc_cl : ld c,a : ld a,(tc_k) : call tc_cl : ld b,a     ; C: paper left, B: ink left
        ld a,(tc_p) : call tc_cr : ld e,a : ld a,(tc_k) : call tc_cr : ld d,a     ; E: paper right, D: ink right
        ld a,c : or e : ld (tc_e),a
        ld a,c : or d : ld (tc_e+1),a
        ld a,b : or e : ld (tc_e+2),a
        ld a,b : or d : ld (tc_e+3),a
        ret
; a line (HL: W1; the parts W1, W2, W1 + #2000, W2 + #2000 - pixels 0-1, 2-3, 4-5, 6-7): ours (IX: its classes
; through tc_pt) there - nothing; the conversion's glyph line (IY through tc_e) there - ours written; else as it is.
; HL, B, IX, IY kept
tc_lr   push bc : ld d,high tc_pt
        ld a,(ix+0) : rrca : rrca : rrca : rrca : and 15 : ld e,a : ld a,(de) : ld (tc_s),a : ld c,a
        ld a,(ix+0) : and 15 : ld e,a : ld a,(de) : ld (tc_s+1),a
        ld a,(ix+1) : rrca : rrca : rrca : rrca : and 15 : ld e,a : ld a,(de) : ld (tc_s+2),a
        ld a,(ix+1) : and 15 : ld e,a : ld a,(de) : ld (tc_s+3),a
        ld a,c : cp (hl) : jr nz,1F
        set 7,h : res 6,h : ld a,(tc_s+1) : cp (hl) : jr nz,2F
        set 5,h : ld a,(tc_s+3) : cp (hl) : jr nz,2F
        res 7,h : set 6,h : ld a,(tc_s+2) : cp (hl) : jr nz,2F
        res 5,h : pop bc : ret                                          ; (ours already)
2       res 7,h : set 6,h : res 5,h
1       ld c,(iy+0) : ld de,tc_e
        ld a,c : rlca : rlca : and 3 : call 8F : cp (hl) : jr nz,9F
        set 7,h : res 6,h : ld a,c : rrca : rrca : rrca : rrca : and 3 : call 8F : cp (hl) : jr nz,6F
        set 5,h : ld a,c : and 3 : call 8F : cp (hl) : jr nz,6F
        res 7,h : set 6,h : ld a,c : rrca : rrca : and 3 : call 8F : cp (hl) : jr nz,6F
        res 5,h
5       ld a,1 : ld (tc_wd),a
        ld a,(tc_s) : ld (hl),a : set 7,h : res 6,h : ld a,(tc_s+1) : ld (hl),a
        set 5,h : ld a,(tc_s+3) : ld (hl),a : res 7,h : set 6,h : ld a,(tc_s+2) : ld (hl),a : res 5,h
        pop bc : ret
6       res 7,h : set 6,h : res 5,h
9       pop bc : ret                                                    ; (neither: as it is)
8       push de : add a,e : ld e,a : jr nc,81F : inc d
81      ld a,(de) : pop de : ret
; colour A -> its left pixel's bits / right pixel's bits in a pair's byte
tc_cl   call tc_map : push bc : ld c,a : and 7 : ld b,a : ld a,c : and 8 : add a,a : add a,a : add a,a : or b : pop bc : ret
tc_cr   call tc_map : push bc : ld c,a : and 7 : add a,a : add a,a : add a,a : ld b,a : ld a,c : and 8 : add a,a : add a,a : add a,a : add a,a : or b : pop bc : ret
; the 4 classes' colours -> tc_pt: the cell (c0 = tc_k), the letter (c1 = tc_p), its light (hi[c1]), its shadow
; (dk[c0]; on black dk[c1]); the tables: the standard palette or the fight field's (wideu.asm xp_p: #FF standard)
tc_col  ld a,(tc_lv) : or a : jr z,1F
        ld a,(tc_lk) : ld hl,tc_k : cp (hl) : jr nz,1F
        ld a,(tc_lp) : ld hl,tc_p : cp (hl) : ret z
1       call tc_pe
        ld a,1 : ld (tc_lv),a : ld a,(tc_k) : ld (tc_lk),a : ld a,(tc_p) : ld (tc_lp),a
        ; the letter in two tones of its colour: the upper part the bright one, the rest the dim one (white: white,
        ; grey); a tone that is the cell's colour -> the letter's own; both the same in this palette -> the light
        ; white (grey on white); the shadow: on a bright cell its dim tone, on a dark one black (on black none)
        ld a,(tc_k) : and 15 : cp 8 : jr nz,2F : xor a
2       ld (tc_c4),a : ld e,a                                   ; E: the cell (CP/M's 8: black)
        ld a,(tc_p) : and 15 : cp 8 : jr nz,3F : xor a
3       ld c,a                                                  ; C: the letter
        ld hl,tc_dm : call 9F : cp e : jr nz,4F : ld a,c
4       ld (tc_c4+1),a
        ld hl,tc_br : ld a,c : call 9F : cp e : jr nz,5F : ld a,c
5       ld (tc_c4+2),a
        ld a,e : ld hl,tc_lu : call 9F : ld b,a                 ; a letter darker than its cell (a menu's marked
        ld a,c : ld hl,tc_lu : call 9F : cp b : jr nc,51F       ;  line: a light bar): its own colour, one tone
        ld a,c : ld (tc_c4+1),a : ld (tc_c4+2),a : ld a,e : jr 7F       ; (no shadow)
51      ld a,(tc_c4+2)
        call tc_map : ld b,a : ld a,(tc_c4+1) : call tc_map : cp b : jr nz,55F         ; one tone in this palette
        ld a,15 : cp b : jr nz,54F : ld a,7                                     ; (a fight's: no dim cyan,
54      ld (tc_c4+2),a                                                          ; magenta) - white light
55      ld a,e : cp 9 : jr nc,56F
        or a : jr z,6F : xor a : jr 7F                                          ; a dark cell: a black shadow
56      ld hl,tc_dm : call 9F : ld hl,tc_c4+1 : cp (hl) : jr z,6F : inc hl : cp (hl) : jr nz,7F
6       ld a,e
7       ld (tc_c4+3),a
        ld ix,tc_c4 : ld b,4
7       ld a,(ix+0) : call tc_cl : ld (ix+4),a : ld a,(ix+0) : call tc_cr : ld (ix+8),a : inc ix : djnz 7B
        ld hl,tc_pt : ld ix,tc_c4+4 : ld a,4
8       push af : ld c,(ix+0) : inc ix : ld de,tc_c4+8 : ld b,4
81      ld a,(de) : or c : ld (hl),a : inc hl : inc de : djnz 81B
        pop af : dec a : jr nz,8B
        xor a : ld (tc_tb),a : ret
9       add a,l : ld l,a : jr nc,91F : inc h
91      ld a,(hl) : ret
; (as tpg.asm t_map: a location fight's slots)
tc_map  push hl : ld hl,tc_rm : add a,l : ld l,a : jr nc,1F : inc h
1       ld a,(hl) : pop hl : ret
tc_rm   db 0, 1, 2, 3, 4, 5, 6, 7, 0, 9, 10, 11, 12, 13, 14, 15
; a colour's bright / dim tone (the standard palette: the text is drawn in it - the fights' popups too, state B)
tc_br   db 0, 9, 10, 11, 12, 13, 14, 15, 0, 9, 10, 11, 12, 13, 14, 15
tc_dm   db 0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7
tc_lu   db 0, 1, 3, 4, 6, 7, 9, 10, 0, 2, 4, 5, 7, 8, 10, 11     ; a colour's lightness (G 6, R 3, B 1; bright +1)
tc_c4   ds 12                                   ; the 4 colours, their left bits, right bits
tc_e    ds 4
tc_lv   db 0
tc_wd   db 0
tc_fi   db 0
tc_lk   db 0
tc_lp   db 0
tc_k    db 0
tc_p    db 0
tc_r    db 0
tc_c    db 0
tc_g    db 0
tc_gg   db 0
tc_ch   db 0
tc_rp   dw 0
tc_ta   db 0
tc_x    ds 8
tc_o    ds 16
tc_ad   dw 0
tc_lm   db 0
tc_m    db 0
tc_pk   db 0
tc_pp   db 0
tc_s    ds 4
; (wideu.asm xp_go -> text.asm tx_rm) B = 0: the standard palette, 1 / 2: the location's (0.66.0: its 16 slots -
; xr_pal, wideu.asm lp_set puts UFO2.TIL's into it at the fight's start; the field's paper slot there: its ZX colour).
; The game's colours through the slots (tc_rm here, t_rm in TPG: the location's ZX colour -> slot, xr_zx - build/
; mktil.py: 5 cyan -> 13, 11 magenta -> 5 pink - 10 when 5 is the paper's -, 8 -> 0; 3, 4 as magenta's, green's dim
; tones; a slot the location took for a colour of its own: the nearest of the others); on a change TPG's attributes'
; tables made again (slot_of[] none). The location keeps its palette under the game's windows. DI; its own stack (the
; game's may be in W1)
xp_rmp  ld a,i : push af : di
        ld (xr_sp),sp : ld sp,#3F60
        ld hl,xr_std : ld a,b : or a : jr z,1F : ld hl,xr_pal
1
        IFDEF NEDOOS
        PAL_HK
        ENDIF
        push bc
        ld bc,#BD77 : ld a,VM_EGA : out (c),a
        ld c,0
2       ld a,c : and 7 : bit 3,c : jr nz,3F
        out (#FE),a : jr 31F
3       out (#F6),a
31      ld a,(hl) : out (#FF),a : inc hl : inc c : bit 4,c : jr z,2B
        ld bc,#FD77 : ld a,VM_EGA : out (c),a : xor a : out (#FE),a
        pop bc
        ld a,(xr_md) : cp b : jr z,9F : ld a,b : ld (xr_md),a
        ld hl,xr_tb : or a : jr z,5F : ld hl,xr_zx
5       push hl : ld de,tc_rm : ld bc,16 : ldir : pop hl
        ld bc,P_W2 : ld a,#7F-TPG : out (c),a
        ld de,t_rm-#4000 : ld bc,16 : ldir
        ld hl,#BC00 : ld de,#BC01 : ld bc,255 : ld (hl),0 : ldir
        ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a
9       ld sp,(xr_sp)
        pop af : ret po : ei : ret
xr_md   db 0                                            ; (lp_set: #FF - a new location's tables)
xr_std  db #FF,#FE,#FD,#FC,#EF,#EE,#ED,#EC,#FF,#DE,#BD,#9C,#6F,#4E,#2D,#0C        ; CP/M's (the standard EGA palette)
; the location's (lp_set: UFO2.TIL's - 32 bytes, xr_zx past xr_pal); here the fight's as before 0.66.0 (an old TIL)
xr_pal  db #FF,#FE,#FD,#BF,#8F,#1D,#ED,#EC,#7D,#DE,#BD,#AF,#6F,#4E,#2D,#0C
xr_zx   db 0, 1, 2, 3, 4, 13, 6, 7, 0, 9, 10, 5, 12, 13, 14, 15        ; (5 cyan -> 13, 11 magenta -> 5 pink)
xr_tb   db 0, 1, 2, 3, 4, 5, 6, 7, 0, 9, 10, 11, 12, 13, 14, 15        ; (the standard palette's)
xr_sp   dw 0
; (epg.asm's - TXPG, here for room)
; (tc_r, tc_c) the shadow's 8 lines all the same byte, #00 / #FF -> Z (a blank)
tx_bl   call tx_sh : ld a,(hl) : inc a : jr z,1F : dec a : ret nz
1       ld c,(hl) : ld b,7
2       ld a,l : add a,32 : ld l,a : ld a,(hl) : cp c : ret nz : djnz 2B
        ret
; (tc_r, tc_c) -> HL: its shadow's line 0 (SHP: lines 32 apart)
tx_sh   ld a,(tc_r) : add a,high SHP : ld h,a : ld a,(tc_c) : ld l,a : ret
txc_end
        ASSERT $ <= TX_TV
        ENT
txc_img_end
; (TXPG #D800..#DDFF: past TA_D, below tc_pt - XR_T, XR_M unused)
txo_img
        DISP #D800
; ---- the fight's name bar (panel.asm pn2_nconv: the word's characters at NMPG #3C00 - its length, then them; E =
; its slot): 20 cells x 8 lines (4 pairs each), centred, in our font - the bar blue, the letter yellow (its
; upper part bright), its shadow dark blue
nm_cv   ld a,i : push af : di
        ld l,e : ld h,0 : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : set 6,h : ex de,hl   ; DE = slot * 640 (W1)
        WIN P_W1, NMPG
        ld a,(NM_B) : ld b,a : ld a,20 : sub b : srl a : ld (nm_s),a
        ld c,0
7       push de
        ld a,(nm_s) : ld b,a : ld a,c : sub b : jr c,71F : ld hl,NM_B : cp (hl) : jr nc,71F
        inc a : add a,l : ld l,a : ld a,(hl) : jr 72F
71      ld a,#0F                                                ; (a space)
72      ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : ld a,h : add a,high TX_OF : ld h,a
        ld b,8
8       push bc : ld c,(hl) : inc hl : ld b,(hl) : inc hl : push hl
        ld a,c : rrca : rrca : rrca : rrca : call 9F
        ld a,c : call 9F
        ld a,b : rrca : rrca : rrca : rrca : call 9F
        ld a,b : call 9F
        ld a,e : add a,76 : ld e,a : jr nc,81F : inc d
81      pop hl : pop bc : djnz 8B
        pop de : ld a,e : add a,4 : ld e,a : jr nc,82F : inc d
82      inc c : ld a,c : cp 20 : jr c,7B
        WIN P_W1, PG_ZX+5
        pop af : ret po : ei : ret
9       and 15 : push hl : ld hl,nm_t : add a,l : ld l,a : jr nc,91F : inc h
91      ld a,(hl) : ld (de),a : inc de : pop hl : ret
nm_t    db #C9, #71, #F1, #49, #8E, #36, #B6, #0E, #CE, #76, #F6, #4E, #89, #31, #B1, #09   ; class left * 4 + right
; ---- (txf, not in the wide fight: W0 has screen 7's shadows SHP, SHA - as converted) the cell (tc_r, tc_c; tc_x: the
; game's glyph lines, tc_o: ours) direct: its shadow pixels are the glyph (or it inverted - a menu's line marked) ->
; the colours from its attribute (ink / paper, bright; the glyph's 1s: tc_k), ours drawn, all 8 lines. C: not so
tc_dir  ld a,(tc_s7) : or a : jp nz,tc_dr7
        ld a,(tc_r) : add a,high SHP : ld h,a : ld a,(tc_c) : ld l,a            ; HL = its line 0 in SHP
        ld de,(tc_dx) : ld bc,#0701                                           ; C: 1 - equal, 2 - inverted
        ld a,(de) : cp (hl) : jr z,3F
        cpl : cp (hl) : scf : ret nz
        inc c                                                                   ; (line 0 inverted: the rest so)
2       ld a,l : add a,32 : ld l,a : inc de
        ld a,(de) : cpl : cp (hl) : scf : ret nz : djnz 2B
        jr 5F
3       ld a,l : add a,32 : ld l,a : inc de
        ld a,(de) : cp (hl) : scf : ret nz : djnz 3B
5       ld a,(tc_r) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld a,(tc_c) : add a,l : ld l,a : ld de,SHA : add hl,de : ld a,(hl)       ; its attribute
tc_da   ld b,a : and 7 : ld d,a : ld a,b : rrca : rrca : rrca : and 7 : ld e,a  ; D: ink, E: paper
        bit 6,b : jr z,6F : set 3,d : set 3,e
6       bit 0,c : jr nz,7F : ld a,d : ld d,e : ld e,a                          ; (inverted: the 1s are the paper)
7       ld a,d : ld (tc_k),a : ld a,e : ld (tc_p),a
tc_dc   call tc_col
        ld a,(tc_tb) : or a : call z,tc_mkt                    ; (the colours' byte tables)
        ld a,(tc_lm) : inc a : jp z,tc_d8                      ; (all 8 lines: part by part)
        ld hl,(tc_ad) : ld ix,(tc_do) : ld b,8 : ld d,high TC_TH : ld a,(tc_lm) : ld c,a
8       push bc : rrc c : jr nc,82F                                            ; (the lines the step changed)
        ld e,(ix+0) : ld a,(de) : ld (hl),a                                    ; (TC_TH: its left pair)
        inc d : ld a,(de) : set 7,h : res 6,h : ld (hl),a                      ; (TC_TL: its right one)
        ld e,(ix+1) : ld a,(de) : set 5,h : ld (hl),a
        dec d : ld a,(de) : res 7,h : set 6,h : ld (hl),a
        res 5,h
82      ld a,l : add a,40 : ld l,a : jr nc,81F : inc h
81      inc ix : inc ix : pop bc : rrc c : djnz 8B
        ld a,1 : ld (tc_wd),a : or a : ret
; (the wide fight's state B: no shadow) the same from screen 7 itself - W1 = its page a moment (the cell's 8 lines: as
; converted in this step - the game waits meanwhile); the colours from the buffer (tc_cp)
tc_dr7  ld bc,P_W1 : ld a,#7F-15 : out (c),a
        ld a,(tc_r) : ld l,a : and #18 : or #40 : ld h,a : ld a,l : rrca : rrca : rrca : and #E0 : ld l,a
        ld a,(tc_c) : or l : ld l,a                                            ; HL = its line 0 (W1)
        ld de,(tc_dx) : ld bc,#0701                                            ; (compared there; C as tc_dir's)
        ld a,(de) : cp (hl) : jr z,4F
        cpl : cp (hl) : jr nz,9F
        inc c
3       inc h : inc de : ld a,(de) : cpl : cp (hl) : jr nz,9F : djnz 3B
        jr 7F
4       inc h : inc de : ld a,(de) : cp (hl) : jr nz,9F : djnz 4B
        jr 7F
9       call tc_w1 : scf : ret                                                 ; (not the glyph)
7       ld a,(tc_r) : rrca : rrca : rrca : ld l,a : and 3 : or #58 : ld h,a : ld a,l : and #E0 : ld l,a
        ld a,(tc_c) : or l : ld l,a : ld a,(hl) : ld (tc_at),a                  ; (its attribute)
        push bc : call tc_w1 : pop bc
        call tc_kp : ld a,(tc_at) : jp nz,tc_da                                  ; (the colours: its attribute)
        ld a,(tc_ch) : dec a : ld l,a : ld a,(tc_ta) : ld h,a : add hl,hl : ld de,TX_SP : add hl,de   ; (the colours from
        ld a,(hl) : or a : jr nz,8F                                                     ;  the buffer, as the slow
        ld a,(tc_ch) : dec a : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : push hl   ; path: the field's
        ld de,TX_GF : add hl,de : ld de,tc_x : ld c,1 : call tc_ln                      ;  palette; tc_x, tc_o for
        pop hl : add hl,hl : ld de,TX_OF : add hl,de : ld de,tc_o : ld c,2 : call tc_ln ;  tc_cp's first time)
8       call tc_cp : ret c
        jp tc_dc
tc_at   db 0
; a glyph's 8 lines (HL, C bytes a line) -> DE as TA says: 0 as they are, 1 / 2 (the tall letter's upper / lower
; cell) lines 0..3 / 4..7 each twice, 3 (the clock) lines 1..6, then 2 more
tc_ln   ld a,(tc_ta) : or a : jr nz,1F
        ld a,c : add a,a : add a,a : add a,a : ld c,a : ld b,0 : ldir : ret
1       cp 3 : jr z,5F
        dec a : jr z,2F
        ld a,c : add a,a : add a,a : add a,l : ld l,a : jr nc,2F : inc h
2       dec c : jr nz,3F                                ; (each of 4 lines twice)
        DUP 4
        ldi : dec hl : ldi
        EDUP
        ret
3       DUP 4
        ldi : ldi : dec hl : dec hl : ldi : ldi
        EDUP
        ret
5       ld a,c : push af                                ; 3: the clock's small font (PUTDAT: the glyph's lines 1..6)
        add a,l : ld l,a : jr nc,51F : inc h
51      pop af : push af : ld b,a : add a,a : add a,b : add a,a : ld c,a : ld b,0 : ldir
        pop af : dec a : jr nz,52F
        ld a,#FF : ld (de),a : inc de : ld (de),a : ret             ; (GF: lines 6, 7 the cell's ink)
52      ldi : ldi : xor a : ld (de),a : inc de : ld (de),a : ret    ; (OF: its line 7 - the shadow - then the cell)
; the recorder (far_t from uipage.asm mk_sc - SCOORD's vector; here in TXPG, its maps at hand; the stack: far_t's return, mk_sc's, its HL, AF, mkv's
; return, SCOORD's caller's, what that pushed): HL screen 7 (#C0..#D7) / DSCR (#90..#A7) -> CM_S / CM_D entry D * 32
; + E: PRINT's / LETTER's character + 1 (SCOORD's caller l_PRINR / l_LETR, the glyph's address under it, the main
; font: BC), else 0
tx_rec  push hl : push de : push bc
        ld hl,6+4 : add hl,sp : ld a,(hl) : inc hl : ld h,(hl) : ld l,a               ; HL = the cell's address
        ld a,h : cp high (G_TIM+22) : jr nz,01F : ld a,l : cp low (G_TIM+22) : jp z,tx_dat   ; (PUTDAT's end)
01
        ld a,h : cp #C0 : ld a,0 : jr nc,0F : ld a,h : cp #90 : jp c,9F : cp #A8 : jp nc,9F : ld a,4
0       ld (tx_mo),a
        xor a : ld (tx_ta),a
        ld hl,6+10 : add hl,sp
        ld a,(hl) : inc hl : cp low G_PRINR : jr nz,1F : ld a,(hl) : cp high G_PRINR : jr z,2F : dec hl : ld a,(hl) : inc hl
1       cp low G_LETR : jr nz,11F : ld a,(hl) : cp high G_LETR : jr z,2F : dec hl : ld a,(hl) : inc hl
11      cp low G_TALR : jr nz,3F : ld a,(hl) : cp high G_TALR : jr nz,3F
        ld a,1 : ld (tx_ta),a : ld bc,G_FONT : jr 22F                                  ; (LETTER's tall one: C = 2 there)
2       ld a,b : cp high G_FONT : jr nz,3F : ld a,c : cp low G_FONT : jr nz,3F
22      inc hl : ld a,(hl) : inc hl : ld h,(hl) : ld l,a : or a : sbc hl,bc           ; (the glyph - the font)
        ld a,h : cp 8 : jr nc,3F
        ld a,l : and 4 : jr z,23F : ld a,(tx_ta) : or a : jr z,23F : inc a : ld (tx_ta),a   ; (the lower half)
23      ld a,l : srl h : rra : srl h : rra : srl h : rra : inc a : jr nz,4F
3       xor a
4       ld c,a                                          ; C: the character + 1 / 0
        ld a,d : and 7 : rrca : rrca : rrca : or e : ld l,a
        ld a,d : rrca : rrca : rrca : and 3 : ld h,a : ld a,(tx_mo) : add a,h : add a,high TX_CS : ld h,a
        ld (hl),c
        ld a,h : sub #10 : ld h,a : ld a,c : or a : jr z,51F : ld a,(tx_ta)
51      ld (hl),a                                       ; (TA)
        ld a,c : or a : jr z,9F
        ld a,(tx_mo) : add a,high TX_RF : ld h,a : ld l,d : ld (hl),1
9       pop bc : pop de : pop hl : or a : ret
; PUTDAT (the clock, its small font: mods.py - JP LAY_MKSC at its end, HL = TIM + 22, DE past its last character on
; screen 7 / in DSCR): its 22 characters -> the text map (TA 3); C back: mk_sc marks the lines (as LAY_MKLN did)
tx_dat  ld a,d : cp #C0 : ld a,0 : jr nc,1F : ld a,4
1       ld (tx_mo),a
        ld hl,G_TIM : ld ix,tx_dtb : ld b,4
2       push bc
        ld a,(tx_mo) : add a,high TX_RF : ld d,a : ld e,(ix+0) : ld a,1 : ld (de),a                ; (the row's flag)
        ld a,(tx_mo) : add a,high TX_CS : ld d,a : ld a,(ix+0) : rrca : rrca : rrca : add a,(ix+1) : ld e,a
        ld b,(ix+2)
3       ld a,(hl) : inc a : ld (de),a : ld a,d : sub #10 : ld d,a : ld a,3 : ld (de),a : ld a,d : add a,#10 : ld d,a
        inc hl : inc e : djnz 3B
        inc ix : inc ix : inc ix : pop bc : djnz 2B
        pop bc : pop de : pop hl : scf : ret
tx_dtb  db 0, 24, 8,  1, 27, 2,  2, 24, 8,  3, 26, 4      ; (row, column, characters: as PUTDAT puts them)
tx_mo   db 0
tx_ta   db 0
; tc_dc's 8 lines, unrolled: per line W1 +0: TC_TH of the class byte's left pair, W2 +0: TC_TL of it, W2 + #2000: TL
; of the right one, W1 + #2000: TH of it (BC: the table, the class byte)
tc_d8   ld hl,(tc_ad) : ld ix,(tc_do) : ld b,high TC_TH : ld de,40
        ld c,(ix+0) : ld a,(bc) : ld (hl),a : inc b : ld a,(bc) : set 7,h : res 6,h : ld (hl),a
        ld c,(ix+1) : ld a,(bc) : set 5,h : ld (hl),a : dec b : ld a,(bc) : res 7,h : set 6,h : ld (hl),a : res 5,h : add hl,de
        ld c,(ix+2) : ld a,(bc) : ld (hl),a : inc b : ld a,(bc) : set 7,h : res 6,h : ld (hl),a
        ld c,(ix+3) : ld a,(bc) : set 5,h : ld (hl),a : dec b : ld a,(bc) : res 7,h : set 6,h : ld (hl),a : res 5,h : add hl,de
        ld c,(ix+4) : ld a,(bc) : ld (hl),a : inc b : ld a,(bc) : set 7,h : res 6,h : ld (hl),a
        ld c,(ix+5) : ld a,(bc) : set 5,h : ld (hl),a : dec b : ld a,(bc) : res 7,h : set 6,h : ld (hl),a : res 5,h : add hl,de
        ld c,(ix+6) : ld a,(bc) : ld (hl),a : inc b : ld a,(bc) : set 7,h : res 6,h : ld (hl),a
        ld c,(ix+7) : ld a,(bc) : set 5,h : ld (hl),a : dec b : ld a,(bc) : res 7,h : set 6,h : ld (hl),a : res 5,h : add hl,de
        ld c,(ix+8) : ld a,(bc) : ld (hl),a : inc b : ld a,(bc) : set 7,h : res 6,h : ld (hl),a
        ld c,(ix+9) : ld a,(bc) : set 5,h : ld (hl),a : dec b : ld a,(bc) : res 7,h : set 6,h : ld (hl),a : res 5,h : add hl,de
        ld c,(ix+10) : ld a,(bc) : ld (hl),a : inc b : ld a,(bc) : set 7,h : res 6,h : ld (hl),a
        ld c,(ix+11) : ld a,(bc) : set 5,h : ld (hl),a : dec b : ld a,(bc) : res 7,h : set 6,h : ld (hl),a : res 5,h : add hl,de
        ld c,(ix+12) : ld a,(bc) : ld (hl),a : inc b : ld a,(bc) : set 7,h : res 6,h : ld (hl),a
        ld c,(ix+13) : ld a,(bc) : set 5,h : ld (hl),a : dec b : ld a,(bc) : res 7,h : set 6,h : ld (hl),a : res 5,h : add hl,de
        ld c,(ix+14) : ld a,(bc) : ld (hl),a : inc b : ld a,(bc) : set 7,h : res 6,h : ld (hl),a
        ld c,(ix+15) : ld a,(bc) : set 5,h : ld (hl),a : dec b : ld a,(bc) : res 7,h : set 6,h : ld (hl),a : res 5,h
        ld a,1 : ld (tc_wd),a : or a : ret
; W1: the back buffer again
tc_w1   ld a,(bf) : or a : ld a,#7F-PS3 : jr z,1F : ld a,#7F-PS1
1       ld bc,P_W1 : out (c),a : ret
; NZ: the cell's colours from its attribute (tc_at) - converted from it (tpg.asm bc_t; not tc_cp's pixels from the
; buffer); Z: a fight's field cell kept under a popup (rows 0..16, BC_CMP): from the buffer (tc_cp)
tc_kp   ld a,(tc_r) : cp 17 : jr nc,1F
        ld a,(BC_CMP) : ld hl,tc_at : cp (hl) : ret
1       or a : ret
tc_s7   db 0                                    ; 1: tc_dir from screen 7 (the wide fight's state B)
; (at the start, xtil.asm tx_init: W3 = TXPG) every character's TX_SP entry for TA 0..3 - tc_cp found none at the
; screen's first text (tc_sp: ~7000 T each, a soldier's screen paid ~5 frames)
tc_spa  xor a : ld (tc_ta),a
1       ld a,1 : ld (tc_ch),a
2       ld a,(tc_ch) : dec a : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : push hl
        ld de,TX_GF : add hl,de : ld de,tc_x : ld c,1 : call tc_ln
        pop hl : add hl,hl : ld de,TX_OF : add hl,de : ld de,tc_o : ld c,2 : call tc_ln
        ld a,(tc_ch) : dec a : ld l,a : ld a,(tc_ta) : ld h,a : add hl,hl : ld de,TX_SP : add hl,de
        push hl : call tc_sp : pop hl : ld a,#FF : jr c,3F
        ld a,(tc_pk) : inc a : ld (hl),a : inc hl : ld a,(tc_pp) : inc a : ld (hl),a : jr 4F
3       ld (hl),a
4       ld a,(tc_ch) : call tc_tv                                       ; (TX_TV too)
        ld a,(tc_ch) : inc a : ld (tc_ch),a : cp 129 : jr c,2B
        ld a,(tc_ta) : inc a : ld (tc_ta),a : cp 4 : jr c,1B
        ret
; tc_pt (by a pair's classes) -> TC_TH / TC_TL (by a class byte: its left / right pair's output byte)
tc_mkt  ld hl,TC_TH : ld de,tc_pt : ld c,16
1       ld a,(de) : inc e : ld b,16
2       ld (hl),a : inc l : djnz 2B
        dec c : jr nz,1B
        ld hl,tc_pt : ld de,TC_TL : ld bc,16 : ldir
        ld hl,TC_TL : ld de,TC_TL+16 : ld bc,240 : ldir
        ld a,1 : ld (tc_tb),a : ret
tc_tb   db 0                                    ; 1: TC_TH, TC_TL made from tc_pt as it is
tc_dx   dw 0                                    ; (tc_dir) the game's glyph lines (8: tc_x, or GF itself)
tc_do   dw 0                                    ; ours (16: tc_o, or OF itself)
nm_end
        ASSERT nm_end <= tc_pt && nm_end <= tx_nm+5   ; (the landings: past it)
        ENT
txo_img_end
; the landing (TXPG at text.asm tx_sw + 5: map_w3p returned into TXPG)
txl_img
        DISP tx_sw+5
        call txf : push af : ld a,XPG : call map_w3p
        ENT
txl_img_end
        ASSERT txl_img_end-txl_img == 9
; the second landing (TXPG at text.asm tx_rm + 5): xp_rmp
txm_img
        DISP tx_rm+5
        call xp_rmp : ld a,XPG : call map_w3p
        ENT
txm_img_end
        ASSERT txm_img_end-txm_img == 8
; the third landing (TXPG at text.asm tx_nm + 5): nm_cv
txn_img
        DISP tx_nm+5
        call nm_cv : ld a,XPG : call map_w3p
        ENT
txn_img_end
        ASSERT txn_img_end-txn_img == 8
        ASSERT tx_sw+5 >= tc_pt+16 && tx_sw+14 < #E000      ; (past RC_B, tc_pt; below CM_S)
