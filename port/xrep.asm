; ---- the figures' places again (MX: W3 = MPG, W1 = TLPG - xpnt.asm's as_* used). The game redraws a fighter's (an
; alien's) cells only - his column of cells, back to front - when he stops, turns, leaves one: those draws cover the
; things in front of them (a ladder at a wall) and his frame where they draw none (his pieces left behind - the ZX
; picture's the same, there the few dots in one colour). The last whole redraw's list (as_os.. #C000, ASPG) is the
; field's picture in its order: where a figure's draw changed (his frame there now, another one, none) its place is
; drawn again from the list - each entry clipped to the place's cells, the frames as they are now (rp_tb: the list's
; figures, then each place a draw changed: its words, its frame word now - #FFFF none). Before the 3D cursor's place
; or a moving one's is kept (xpnt.asm cs_put, gb_put): rp_go.
RPN     equ 48                                  ; rp_tb's entries (more: none of this till the next whole redraw)
RPE     equ 4+AS_E+1                            ; an entry: the tile's place (rp_k: its left byte, code, first line
                                                ; - y - l0, 2), the draw there now (its words: a figure's whole, his
                                                ; frame - #FFFF none; the list has the tile's lines with pixels only),
RP_F    equ 4+AS_E                              ; how: 0 the list's (as it was), 1 its frame word now (on each of
                                                ; the list's entries of the tile - a figure's slices), 2 the words now
                                                ; (at the first of them, the rest not drawn: 3 meanwhile)
; HL = a draw's words -> rp_k: its tile's place (the slices of one tile, a whole redraw's or a figure's, the same)
rp_key  push hl : inc hl : ld a,(hl) : inc hl : ld e,(hl) : inc hl : ld d,(hl) : inc hl
        ld c,a : ld a,(hl) : cp 2 : ld a,c : jr nz,1F : dec a
1       ld (rp_k),a : inc hl : inc hl : ld a,(hl) : inc hl : ld c,(hl) : ld b,a     ; B = l0, C = code
        ld a,c : ld (rp_k+1),a : ex de,hl : ld c,b : ld b,0 : or a : sbc hl,bc : ld (rp_k+2),hl
        pop hl : ret
; (as_end) the new list's figures into rp_tb
rp_sd   xor a : ld (rp_n),a : ld (rp_bad),a : call rp_clr
        ld hl,rp_bl : ld de,rp_bl+1 : ld bc,511 : ld (hl),0 : ldir
        call as_w2 : ld hl,(as_os)
1       ld a,h : cp high #C000 : jr nc,9F
        call rp_key : push hl : call rp_bs : pop hl                     ; (its tile into the filter)
        push hl : ld de,8 : add hl,de : ld a,(hl) : inc hl : and (hl) : pop hl : inc a : jr z,2F       ; (no frame)
        call rp_key : push hl : call rp_fd : pop hl : jr z,2F                                         ; (there)
        ld a,(rp_n) : cp RPN : jr nc,8F : inc a : ld (rp_n),a
        push hl : xor a : call rp_put : pop hl
2       ld de,AS_E : add hl,de : jr 1B
8       ld a,1 : ld (rp_bad),a
9       jp as_w2x
; DE = an entry, HL = a draw's words, A = how (RP_F): rp_k, them, it there
rp_put  push af : push hl : ld hl,rp_k : ld bc,4 : ldir : pop hl : ld bc,AS_E : ldir : pop af : ld (de),a : ret
; rp_k: Z - in rp_tb, DE = its entry; NZ - not (DE past the last)
rp_fd   ld de,rp_tb : ld a,(rp_n) : or a : jr z,9F : ld b,a
        ld a,(rp_k) : ld c,a
1       ld a,(de) : cp c : jr z,3F
2       ld a,e : add a,RPE : ld e,a : jr nc,21F : inc d
21      djnz 1B
9       or 1 : ret
3       push de : inc de : ld hl,rp_k+1 : ld a,(de) : cp (hl) : jr nz,4F
        inc de : inc hl : ld a,(de) : cp (hl) : jr nz,4F : inc de : inc hl : ld a,(de) : cp (hl)
4       pop de : ret z : jr 2B
; rp_k's two bits in the filter (rp_bl: the last whole redraw's tiles, 4096 bits): rp_bs sets them, rp_bt - NZ: not
; both there (a tile the list has not: a cell changed since - a door opened)
rp_bs   call rp_h1 : or (hl) : ld (hl),a : call rp_h2 : or (hl) : ld (hl),a : ret
rp_bt   call rp_h1 : and (hl) : jr z,1F : call rp_h2 : and (hl) : jr z,1F : xor a : ret
1       or 1 : ret
rp_h1   ld a,(rp_k+1) : add a,a : ld l,a : ld a,(rp_k+2) : xor l : ld l,a              ; originL ^ code * 2
        ld a,(rp_k+1) : ld h,a : add a,a : add a,h : ld h,a : ld a,(rp_k) : add a,h : ld h,a
        ld a,(rp_k+3) : add a,h : jr rp_bit                                            ; tx + code * 3 + originH
rp_h2   ld a,(rp_k) : ld l,a : add a,a : add a,a : add a,a : sub l : ld l,a : ld a,(rp_k+1) : add a,l : ld l,a
        ld a,(rp_k+2) : rrca : rrca : rrca : xor l : ld l,a                            ; (tx * 7 + code) ^ rr3 originL
        ld a,(rp_k+2) : rrca : rrca : rrca : rrca : ld h,a : ld a,(rp_k) : add a,a : add a,h : ld h,a
        ld a,(rp_k+3) : add a,h                                                         ; originL >> 4 + tx * 2 + originH
; A (bits 0-3), L: the bit's number -> HL its byte, A its mask
rp_bit  and 15 : ld h,a : ld a,l : and 7 : ld b,a : ld a,1 : jr z,2F
1       add a,a : djnz 1B
2       srl h : rr l : srl h : rr l : srl h : rr l : ld bc,rp_bl : add hl,bc : ret
; (xtil_i.asm pl_sq: a draw as it comes, not a whole redraw's) HL = its words: a frame there now / none now - its
; place noted (IX kept)
rp_nt   push ix : call 0F : pop ix : ret
0       ld a,(as_ok) : or a : ret z
        ld a,(rp_bad) : or a : ret nz
        push hl : pop ix : call rp_key : call rp_fd : jr z,1F
        call rp_bt : jr nz,8F                                   ; (a tile the list has not: no more till it is made again)
        ld a,(ix+8) : and (ix+9) : inc a : ret z                ; (no frame, not a figure's place: nothing)
        ld a,(rp_n) : cp RPN : jr nc,8F : inc a : ld (rp_n),a   ; (a new one: DE past the last)
        push ix : pop hl : ld a,2 : call rp_put : jr rp_bxa
8       ld a,1 : ld (rp_bad),a : ret
1       ld hl,4 : add hl,de                                     ; HL: the draw there
        ld a,(ix+4) : cp 3 : jr nz,4F                           ; (a part of the tile - one column: its frame only)
        push hl : ld de,5 : add hl,de : ld a,(hl) : pop hl : cp (ix+5) : jr z,2F : jr nc,4F   ; (fewer lines: as one column)
2       push ix : pop de : ld b,AS_E
21      ld a,(de) : cp (hl) : jr nz,3F : inc hl : inc de : djnz 21B
        ret                                                     ; (the same: nothing)
3       ld a,AS_E : sub b : ld c,a : ld b,0 : or a : sbc hl,bc   ; (its first word)
        push hl : push ix : push hl : pop ix : call rp_bxa : pop ix : pop de     ; (the old one's place too)
        push ix : pop hl : ld bc,AS_E : ldir : ld a,2 : ld (de),a : jr rp_bxa
4       ld de,8 : add hl,de : ld a,(ix+8) : cp (hl) : jr nz,5F
        inc hl : ld a,(ix+9) : cp (hl) : ret z : dec hl         ; (the same frame: nothing)
5       ld a,(ix+8) : ld (hl),a : inc hl : ld a,(ix+9) : ld (hl),a
        inc hl : ld a,(hl) : or a : jr nz,51F : inc (hl)        ; (the list's: its frame now - 1)
51      ld de,-10 : add hl,de : push ix : push hl : pop ix : call rp_bxa : pop ix      ; (its whole place)
; IX = a draw's words: its place (its byte and one each side; its lines' rows) into rp_bx
rp_bxa  ld a,(ix+1) : dec a : jp p,1F : xor a
1       ld hl,rp_bx : cp (hl) : jr nc,2F : ld (hl),a
2       ld a,(ix+1) : inc a : jp m,9F : cp 40 : jr c,3F : ld a,39
3       inc hl : cp (hl) : jr c,4F : ld (hl),a
4       ld l,(ix+2) : ld h,(ix+3) : push hl
        ld e,(ix+5) : ld d,0 : add hl,de : dec hl               ; the last line
        bit 7,h : jr nz,8F : ld a,h : or a : jr nz,41F : ld a,l : cp 200 : jr c,42F
41      ld a,199
42      rrca : rrca : rrca : and #1F : ld e,a                   ; E = the last row
        pop hl : bit 7,h : jr nz,43F : ld a,h : or a : ret nz : ld a,l : cp 200 : ret nc : jr 44F
43      xor a
44      rrca : rrca : rrca : and #1F
        ld hl,rp_bx+2 : cp (hl) : jr nc,45F : ld (hl),a
45      inc hl : ld a,e : cp (hl) : jr c,46F : ld (hl),a
46      ld a,1 : ld (rp_on),a
9       ret
8       pop hl : ret
; (xpnt.asm, before a place is kept: W1 = TLPG, W3 = MPG) the noted place drawn again from the list
rp_go   ld a,(rp_on) : or a : ret z
        ld a,(as_on) : or a : ret nz                            ; (a whole redraw going on: it draws all)
        ld a,(cs_v) : ld hl,gb_v : or (hl) : ret nz             ; (places kept: they would put back the old)
        ld a,(as_ok) : or a : jp z,rp_clr
        ld a,(rp_bad) : or a : jp nz,rp_clr
        ld hl,(rp_bx) : ld (as_bc),hl
        ld a,(rp_bx+2) : ld (as_br),a : ld a,(rp_bx+3) : cp 25 : jr c,1F : ld a,24
1       ld (as_br+1),a
        ld a,(as_br) : ld c,a                                   ; its cells dirty (DB_C)
2       ld a,(as_br+1) : cp c : jr c,4F
        ld l,c : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        ld a,(as_bc) : ld e,a : ld d,0 : add hl,de : ld de,DB_C : add hl,de
        ld a,(as_bc) : ld e,a : ld a,(as_bc+1) : sub e : jr c,3F : inc a : ld b,a
21      ld (hl),1 : inc hl : djnz 21B
3       inc c : jr 2B
4       ld a,1 : ld (as_rp),a : call as_w2
        ld a,(as_bc) : ld b,a : ld a,(as_bc+1) : add a,3 : ld c,a      ; (an entry's x + 1 in B .. C - 1)
        ld a,(as_br) : add a,a : add a,a : add a,a : ld d,a             ; (its lines: past D, before E)
        ld a,(as_br+1) : inc a : add a,a : add a,a : add a,a : ld e,a
        ld hl,(as_os)
5       ld a,h : cp high #C000 : jp nc,7F
        push hl                                                 ; (not near the place: skipped as it is)
        inc hl : ld a,(hl) : inc a : jp m,6F : cp b : jr c,6F : cp c : jr nc,6F
        inc hl : inc hl : ld a,(hl) : dec hl : or a : jr z,51F
        inc a : jr nz,6F                                        ; (y: -256.. only)
        ld a,(hl) : inc hl : inc hl : inc hl : add a,(hl) : jr nc,6F : cp d : jr c,6F : jr z,6F : jr 62F
51      ld a,(hl) : cp e : jr nc,6F : inc hl : inc hl : inc hl : add a,(hl) : jr c,62F : cp d : jr c,6F : jr z,6F
62      pop hl : push hl : push bc : push de
        ld de,as_e : ld bc,AS_E : ldir
        ld hl,as_e : call rp_key : call rp_fd : jr nz,63F       ; (the draw there now)
        ld hl,RP_F : add hl,de : ld a,(hl) : or a : jr z,63F
        cp 2 : jr c,64F : jr nz,66F                             ; (1: its frame; 3: drawn - not again)
        ld (hl),3 : ld hl,4 : add hl,de : ld de,as_e : ld bc,AS_E : ldir : jr 63F
64      ld hl,4+8 : add hl,de : ld a,(hl) : ld (as_e+8),a : inc hl : ld a,(hl) : ld (as_e+9),a
63      call as_rpe
        call as_w2
66      pop de : pop bc
6       pop hl : push de : ld de,AS_E : add hl,de : pop de : jp 5B
7       call as_w2x
        ld hl,rp_tb : ld a,(rp_n) : or a : jr z,79F : ld b,a    ; (2 not drawn - the list has not its tile there:
71      push bc : push hl                                       ; drawn last; 3 -> 2)
        ld de,RP_F : add hl,de : ld a,(hl) : cp 3 : jr nz,72F : ld (hl),2 : jr 78F
72      cp 2 : jr nz,78F
        pop hl : push hl : ld de,4 : add hl,de : ld de,as_e : ld bc,AS_E : ldir : call as_rpe
78      pop hl : ld de,RPE : add hl,de : pop bc : djnz 71B
79      xor a : ld (as_rp),a
        call as_db0
rp_clr  ld hl,#00FF : ld (rp_bx),hl : ld (rp_bx+2),hl : xor a : ld (rp_on),a : ret
rp_n    db 0
rp_bad  db 0
rp_on   db 0
rp_bx   db #FF, 0, #FF, 0                       ; bytes c0, c1, rows r0, r1 (the plane's)
rp_k    ds 4
rp_tb   equ $                                   ; (past MX's image: not in UFO2.DAT; rp_n, rp_sd make them)
rp_bl   equ rp_tb+RPN*RPE
        ASSERT rp_bl+512 <= OB_Z0
