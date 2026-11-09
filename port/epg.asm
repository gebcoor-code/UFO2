; ---- more of XPG's code: TXPG's free tail #FA00.. (DISP; W3 = TXPG while it runs). XPG calls it through text.asm
; xe_far (HL = the routine; its A, flags back): its landing at xe_far + 5 (map_w3p returned into TXPG - past nm_s)
EPG     equ TXPG
EPG_A   equ #FA00                               ; (TXPG: past TC_TL)
epg_img
        DISP EPG_A
xe_jp   jp (hl)
; ---- the text's recognition table (tx_rp; textr.asm tx_rcg): TX_RB - 512 entries (the character + 1, TA: 0, 1 / 2
; the tall letter's upper / lower half - its 4 lines each twice; its tag), one at the cell's hash (per line: rotated
; left, its byte XORed in) * 2 or the first free one past it: build/mktxr.py's (the game's font), xtil.asm tx_init
; copies it (textr.asm tx_rbi)
TX_RB   equ #FC00
rb_b    ds 8
; ---- (textc.asm txf) a changed cell's character (HL: its CM_S byte, kept) -> A (+ 1; 0: none). Not in the wide fight:
; recognized in the shadow (SHP: screen 7 as converted) - the map's character replaced (CM_S, TA_S) when another one
; is there (the map stale: the game put back its own copy of a part of the screen; or text put there without PRINT);
; a blank there: the map's kept (e.g. not typed yet), none for none; nothing recognized: the map's (a tall letter
; between the rows, ...)
tx_cv   ld a,(bwide) : or a : ld a,(hl) : ret nz
        or a : jr z,1F : cp #10 : jr z,1F
        push hl : call tx_gq : pop hl : ld a,(hl) : ret z       ; (the map's is there: as it is)
1       ld a,(tc_r) : ld e,a : ld d,0 : ex de,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld a,(tc_c) : add a,l : ld l,a : push de : ld de,SHA : add hl,de : pop de : ld a,(hl) : ex de,hl
        and #FE : cp #68 : jr z,7F                              ; (the world map's cells: #69 / #68 - no text there)
        push hl : call tx_bl : pop hl : jr z,7F                 ; (a blank cell)
        push hl : call tx_rs : pop hl : jr z,8F
        cp #10 : jr z,7F                                        ; (a blank)
        ld b,a : ld (hl),a : ld a,h : sub #10 : ld h,a : ld (hl),c : add a,#10 : ld h,a : ld a,b : ret     ; (CM_S, TA_S)
7       ld a,(hl) : cp #10 : ret nz : xor a : ret               ; (the map's, a blank: none)
8       ld a,(hl) : ret
; HL: the map's CM_S byte (A: its character + 1) -> Z: the shadow there is that glyph (as TA says), as it is or inverted
tx_gq   push af : ld a,h : sub #10 : ld h,a : ld c,(hl) : pop af   ; (C: TA)
        ld b,a : ld a,c : cp 3 : ret z                          ; (the clock's: not checked)
        ld a,b : dec a : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld de,TX_GF : add hl,de
        ld a,c : or a : jr z,1F : dec a : jr z,1F : inc hl : inc hl : inc hl : inc hl
1       ex de,hl : call tx_sh                                   ; (DE: the glyph, HL: the shadow)
        ld a,(de) : xor (hl) : jr z,2F : inc a : ret nz : dec a ; (#00: as it is, #FF: inverted)
2       ld b,8 : inc c : dec c : jr nz,5F
        ld c,a                                                  ; (a plain one: C the XOR)
3       ld a,(de) : xor (hl) : cp c : ret nz
        inc de : ld a,l : add a,32 : ld l,a : djnz 3B
        xor a : ret
5       ld (tq_x),a                                             ; (a tall one: each line twice)
6       ld a,(de) : xor (hl) : push hl : ld hl,tq_x : cp (hl) : pop hl : ret nz
        ld a,l : add a,32 : ld l,a
        ld a,b : and 1 : jr z,7F : inc de
7       djnz 6B
        xor a : ret
tq_x    db 0
; (tc_r, tc_c) its shadow's 8 bytes -> A = the character + 1 (Z: none), C = TA (epg.asm TX_RB, GF)
tx_rs   ld a,(tc_r) : add a,high SHP : ld h,a : ld a,(tc_c) : ld l,a
        ld de,rb_b : ld b,8 : xor a
1       rlca : xor (hl) : ld c,a : ld a,(hl) : ld (de),a : ld a,c : inc de
        ld a,l : add a,32 : ld l,a : ld a,c : djnz 1B
        call tx_rp : ret nz
        ld hl,rb_b : ld b,8 : xor a                                         ; (inverted: a menu's marked line)
2       ld c,a : ld a,(hl) : cpl : ld (hl),a : ld a,c : rlca : xor (hl) : inc hl : djnz 2B
        call tx_rp : ret nz
        xor a : ld c,a : ret
; A = rb_b's hash -> NZ: its glyph found (A: the character + 1, C: TA). The table: 512 entries (the character + 1,
; TA + a tag - rb_b's bytes' sum & #FC: most entries skipped without the glyph), from the hash's * 2 on to the first
; free one (wrapping)
tx_rp   ld e,a
        ld hl,rb_b : ld b,8 : xor a
0       add a,(hl) : inc hl : djnz 0B
        and #FC : ld (rp_t),a
        ld l,e : ld h,0 : add hl,hl : add hl,hl : ld de,TX_RB : add hl,de
1       ld a,(hl) : or a : ret z                                            ; (a free one: none)
        inc hl : ld a,(hl) : inc hl : ld c,a : and #FC
        push hl : ld hl,rp_t : cp (hl) : pop hl : jr nz,4F                  ; (another tag: not it)
        ld a,c : and 3 : ld c,a : dec hl : dec hl : ld a,(hl) : inc hl : inc hl
        push hl : push af : call 5F : jr nz,41F
        pop af : pop hl : or a : ret                                        ; (NZ: found)
41      pop af : pop hl
4       ld a,h : or a : jr nz,1B : ld h,high TX_RB : jr 1B                  ; (past the table's end: its start)
rp_t    db 0
5       dec a : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld de,TX_GF : add hl,de
        ld a,c : or a : jr z,6F : dec a : jr z,6F : inc hl : inc hl : inc hl : inc hl     ; (TA 2: lines 4..7)
6       ld de,rb_b : ld b,8
7       ld a,(de) : cp (hl) : ret nz                                        ; (Z: rb_b is that glyph)
        ld a,c : or a : jr z,8F : ld a,b : and 1 : jr z,9F                  ; (tall: each line twice)
8       inc hl
9       inc de : djnz 7B
        xor a : ret
epg_end
        display "epg end ",epg_end
        ASSERT epg_end <= TX_RB
        ENT
epg_img_end
xel_img
        DISP xe_far+5
        call xe_jp : push af : ld a,XPG : call map_w3p
        ENT
xel_img_end
        ASSERT xel_img_end-xel_img == 9
        ASSERT xe_far+5 > nm_s && xe_far+14 <= tx_nm+5   ; (TXPG: free there)
