; ------------------------------------------------------------------ screen cache (page UPG, W3; called from scr.asm)
; Whole screens the game puts up again and again (the world map, the menu...): their converted pictures are kept.
; Slot s: page SC_P0+3s = the ZX picture as the shadow keeps it (6144 pixels by rows r*256 + l*32 + cx, 768
; attributes), +1 = parts 0, 2 of the EGA picture (as page 1 / 3), +2 = parts 1, 3 (as page 5 / 7); x 0..255 only.
; sc_row1 (a row of a whole-screen change, at its conversion): equal to a slot's row -> copied from the slot
; into the back buffer (and the shadow), else converted as usual.
; sc_capture (right after a flip: the front = the shadow): the front picture into a slot.
SC_P0   equ 55
SC_N    equ 1                       ; (pages 55..57; 58's start, 59: the text map, the fonts - xpg.asm TXPG; 60 free;
                                    ; 61, 62: the fight's object planes, obj.asm)

sc_val  db 0,0,0                        ; slot holds a picture
sc_age  db 0,0,0                        ; use (higher = more recent)
sc_hit  db 0,0,0                        ; rows found in each slot by the last restore
sc_tick db 0
sc_r    db 0
sc_s    db 0

; A = page -> W1 / W2
sc_w1   push bc : ld b,a : ld a,#7F : sub b : ld bc,P_W1 : out (c),a : pop bc : ret
sc_w2   push bc : ld b,a : ld a,#7F : sub b : ld bc,P_W2 : out (c),a : pop bc : ret
; A = slot -> A = its first page
sc_pg   ld b,a : add a,a : add a,b : add a,SC_P0 : ret

; row sc_r (marked by a whole-screen change), from the conversion (W1, W2 = back): each marked group (cmask) of
; 8 columns equal to a slot's -> copied from the slot into the back buffer and the shadow, its cmask bit cleared
sc_row1
        ld a,(cmask) : cp #0F : jr nz,0F        ; the whole row in the last slot? (the usual case)
        call sc_rowf1 : jr nc,0F
        xor a : ld (cmask),a : ret
0       xor a : ld (sc_g),a
.grp    ld a,(sc_g) : call gbit : ld (sc_gb),a
        ld hl,cmask : and (hl) : jp z,.ng
        xor a : ld (sc_k),a                     ; the slots, the last one that had it first
.slot   ld a,(sc_last) : ld c,a : ld a,(sc_k) : add a,c : cp SC_N : jr c,0F : sub SC_N
0       ld c,a : ld hl,sc_val : ld b,0 : add hl,bc : ld a,(hl) : or a : jr z,.nx
        ld a,c : ld (sc_s),a : call sc_pg : call sc_w2 : ld a,15 : call sc_w1     ; W1 = screen 7, W2 = the slot
        ; pixels: screen 7 (#4000 + its layout) against the slot (#8000 + r*256 + l*32), 8 bytes from 8g
        call sc_l0 : ld a,(sc_g) : add a,a : add a,a : add a,a : ld c,a : add a,l : ld l,a
        ld a,(sc_r) : add a,#80 : ld d,a : ld e,c
        ld c,8
1       push hl : push de : ld b,8
2       ld a,(de) : cp (hl) : jr nz,.nx1 : inc hl : inc e : djnz 2B
        pop de : pop hl : inc h : ld a,e : add a,32 : ld e,a : dec c : jr nz,1B
        call sc_ar : ld a,(sc_g) : add a,a : add a,a : add a,a : add a,l : ld l,a
        ld a,h : add a,#40 : ld d,a : ld e,l                                ; HL = #5800 + r*32 + 8g, DE = #9800 + ...
        ld b,8
3       ld a,(de) : cp (hl) : jr nz,.nx0 : inc hl : inc de : djnz 3B
        jr .hit
.nx1    pop de : pop hl
.nx0
.nx     ld a,(sc_k) : inc a : ld (sc_k),a : cp SC_N : jr c,.slot
        jp .ng
.hit    ld a,(sc_s) : ld (sc_last),a : ld e,a : ld d,0 : ld hl,sc_hit : add hl,de : inc (hl)
        ; the shadow = this group of screen 7 (W1)
        call sc_l0 : ld a,(sc_g) : add a,a : add a,a : add a,a : ld c,a : add a,l : ld l,a
        ld a,(sc_r) : add a,high SHP : ld d,a : ld e,c
        ld b,8
4       push bc : push hl : ld bc,8 : ldir : pop hl : inc h : ld a,e : add a,24 : ld e,a : pop bc : djnz 4B
        call sc_ar : ld a,(sc_g) : add a,a : add a,a : add a,a : add a,l : ld l,a
        ld de,SHA-#5800 : ex de,hl : add hl,de : ex de,hl : ld bc,8 : ldir
        call sc_cpgrp                                                   ; slot -> back buffer
        ; done: not to be converted, no copy pending; the other buffer gets it after the flip
        ld a,(sc_gb) : cpl : ld c,a
        ld hl,cmask : ld a,(hl) : and c : ld (hl),a
        ld a,(sc_r) : ld e,a : ld d,0
        ld hl,psync : add hl,de : ld a,(hl) : and c : ld (hl),a
        ld hl,bsync : add hl,de : ld a,(sc_gb) : or (hl) : ld (hl),a : ld bc,SYN : add hl,bc : ld (hl),#FF
        ld a,1 : ld (bchg),a
        ld hl,(budget) : ld de,10 : add hl,de : ld (budget),hl
.ng     ld a,(sc_g) : inc a : ld (sc_g),a : cp 4 : jp c,.grp
        ld hl,(budget) : ld de,6 : add hl,de : ld (budget),hl
        ret
sc_g    db 0
sc_k    db 0
; the whole row sc_r against slot sc_last: CY = equal and taken (back buffer, shadow, syncs as sc_row1)
sc_rowf1
        ld a,(sc_last) : ld c,a : ld hl,sc_val : ld b,0 : add hl,bc : ld a,(hl) : or a : ret z
        ld a,c : ld (sc_s),a : call sc_pg : call sc_w2 : ld a,15 : call sc_w1
        call sc_l0 : ld a,(sc_r) : add a,#80 : ld d,a : ld e,0
        ld c,8
1       ld b,32
2       ld a,(de) : cp (hl) : jr nz,.no : inc l : inc e : djnz 2B
        ld a,l : sub 32 : ld l,a : inc h : dec c : jr nz,1B
        call sc_ar : push hl : ld de,#9800-#5800 : add hl,de : ex de,hl : pop hl
        ld b,32
3       ld a,(de) : cp (hl) : jr nz,.no : inc l : inc e : djnz 3B
        jr .eq
.no     or a : ret                              ; (NC: different)
.eq     ; equal: the shadow
        call sc_l0 : ld a,(sc_r) : add a,high SHP : ld d,a : ld e,0
        ld c,8
4       DUP 32
        ldi
        EDUP
        ld a,l : sub 32 : ld l,a : inc h : dec c : jr nz,4B
        call sc_ar : push hl : ld de,SHA-#5800 : add hl,de : ex de,hl : pop hl
        DUP 32
        ldi
        EDUP
        ; the EGA row: slot -> back
        ld a,(sc_s) : call sc_pg : inc a : call sc_w1
        ld a,(bf) : or a : ld a,PS3 : jr z,5F : ld a,PS1
5       push af : call sc_w2 : call sc_cp32 : pop af
        add a,4 : call sc_w2
        ld a,(sc_s) : call sc_pg : add a,2 : call sc_w1 : call sc_cp32
        ld a,(sc_s) : ld e,a : ld d,0 : ld hl,sc_hit : add hl,de : ld a,(hl) : add a,4 : ld (hl),a
        ld a,(sc_r) : ld e,a
        ld hl,psync : add hl,de : ld (hl),0 : ld bc,SYN : add hl,bc : ld (hl),0
        ld hl,bsync : add hl,de : ld (hl),#0F : add hl,bc : ld (hl),#FF
        ld a,1 : ld (bchg),a
        ld hl,(budget) : ld de,32 : add hl,de : ld (budget),hl
        scf : ret
; the 8 lines of row sc_r, 32 bytes: W1 (#4000 + y*40, +#2000) -> W2 (#8000 + ...)
sc_cp32 ld a,(sc_r) : add a,a : add a,a : add a,a : add a,4 : call yoff
        ld hl,(y_off) : ld a,h : add a,#40 : ld h,a : push hl : call 1F : pop hl : ld a,h : add a,#20 : ld h,a
1       ld a,h : add a,#40 : ld d,a : ld e,l : ld a,8
2       DUP 32
        ldi
        EDUP
        ld bc,8 : add hl,bc : ex de,hl : add hl,bc : ex de,hl
        dec a : jr nz,2B
        ret
sc_last db 0
sc_gb   db 0
sc_miss db 0
; a whole-screen change (from mk_all, all rows marked, DI): every row from the cache now; A = 0: all of it found
sc_all  xor a : ld (sc_r),a : ld (sc_miss),a
1       ld a,#0F : ld (cmask),a
        call sc_row1
        ld a,(sc_r) : ld e,a : ld d,0 : ld hl,drow : add hl,de
        ld a,(cmask) : ld (hl),a : or a : jr nz,2F
        ld bc,24 : add hl,bc : ld (hl),a                ; nothing left to convert in this row
        ld hl,sc_rowf : add hl,de : ld (hl),a
        jr 3F
2       ld c,a : ld hl,sc_miss                           ; groups not found
5       srl c : jr nc,6F : inc (hl)
6       jr nz,5B
3       ld a,(sc_r) : inc a : ld (sc_r),a : cp 24 : jr c,1B
        ld a,(sc_miss) : ret
; HL = line 0 of row sc_r on screen 7 at W1
sc_l0   ld a,(sc_r) : and #18 : or #40 : ld h,a : ld a,(sc_r) : rrca : rrca : rrca : and #E0 : ld l,a : ret
; HL = #5800 + r*32
sc_ar   ld a,(sc_r) : rrca : rrca : rrca : ld l,a : and #1F : or #58 : ld h,a : ld a,l : and #E0 : ld l,a : ret
; the slot's EGA group (sc_r, sc_g) into the back buffer: 8 lines, 8 bytes at +0 and +#2000, both pages
sc_cpgrp
        ld a,(sc_s) : call sc_pg : inc a : call sc_w1                   ; parts 0, 2
        ld a,(bf) : or a : ld a,PS3 : jr z,1F : ld a,PS1                    ; back: B (3, 7) when A is shown
1       push af : call sc_w2 : call sc_cp8 : pop af
        add a,4 : call sc_w2                                            ; 7 / 5
        ld a,(sc_s) : call sc_pg : add a,2 : call sc_w1                 ; parts 1, 3
; the 8 lines of row sc_r, group sc_g: W1 (#4000 + y*40 + 8g, +#2000) -> W2 (#8000 + ...)
sc_cp8  ld a,(sc_r) : add a,a : add a,a : add a,a : add a,4 : call yoff
        ld hl,(y_off) : ld a,(sc_g) : add a,a : add a,a : add a,a : ld e,a : ld d,0 : add hl,de
        ld a,h : add a,#40 : ld h,a : push hl : call 1F : pop hl : ld a,h : add a,#20 : ld h,a
1       ld a,h : add a,#40 : ld d,a : ld e,l
        DUP 8
        ldi : ldi : ldi : ldi : ldi : ldi : ldi : ldi
        ld bc,32 : add hl,bc : ex de,hl : add hl,bc : ex de,hl
        EDUP
        ret

; the front picture (cursor off) and the shadow into a slot: the one most of the last restore came from, else the
; least used
; the capture: slot choice (when a whole-screen change settles) - the one most of the last lookups came from, else
; an empty one, else the least recently used
sc_capsel
        ld hl,sc_tick : inc (hl)
        ld hl,sc_hit : ld c,0 : ld b,0 : ld e,0                         ; best: C = slot, E = hits
1       ld a,(hl) : cp e : jr c,2F : jr z,2F : ld e,a : ld c,b
2       inc hl : inc b : ld a,b : cp SC_N : jr c,1B
        ld a,e : cp 6 : jr nc,4F
        ld hl,sc_val : ld c,0                                           ; an empty slot
3       ld a,(hl) : or a : jr z,4F
        inc hl : inc c : ld a,c : cp SC_N : jr c,3B
        ld hl,sc_age : ld c,0 : ld b,0 : ld e,#FF                       ; else the least recently used
5       ld a,(hl) : cp e : jr nc,6F : ld e,a : ld c,b
6       inc hl : inc b : ld a,b : cp SC_N : jr c,5B
4       ld a,c : ld (sc_cs),a
        ld hl,sc_val : ld e,c : ld d,0 : add hl,de : ld a,(hl) : ld (sc_ok),a     ; an empty one: valid at the end
        xor a : ld (sc_hit),a : ld (sc_hit+1),a : ld (sc_hit+2),a
        ret
; the end of a capture: the slot valid, used now
sc_capfin
        ld a,(sc_cs) : ld e,a : ld d,0
        ld hl,sc_val : add hl,de : ld (hl),1
        ld hl,sc_age : add hl,de : ld a,(sc_tick) : ld (hl),a
        ret
; row A (settled: the back buffer = the front = the shadow) into slot sc_cs, group by group (only what differs)
sc_caprow
        ld (sc_r),a : ld a,(sc_cs) : ld (sc_s),a
        xor a : ld (sc_g),a
2       ld a,(sc_s) : call sc_pg : call sc_w2                           ; W2 = the slot's ZX picture
        ld a,(sc_ok) : or a : jr z,.cp
        ; shadow (SHP + r*256 + l*32 + 8g) against the slot (#8000 + the same)
        ld a,(sc_g) : add a,a : add a,a : add a,a : ld l,a : ld e,a
        ld a,(sc_r) : add a,high SHP : ld h,a : ld a,(sc_r) : add a,#80 : ld d,a
        ld c,8
3       ld b,8 : push hl : push de
4       ld a,(de) : cp (hl) : jr nz,.cp0 : inc l : inc e : djnz 4B
        pop de : pop hl : ld a,l : add a,32 : ld l,a : ld e,a : dec c : jr nz,3B
        call sc_sa : push hl : ld de,#9800-SHA : add hl,de : ex de,hl : pop hl     ; DE = #9800 + r*32 + 8g
        ld b,8
5       ld a,(de) : cp (hl) : jr nz,.cp : inc hl : inc de : djnz 5B
        jr .nxg                                                         ; the same: nothing to do
.cp0    pop de : pop hl
.cp     ; the shadow's group -> the slot (W2)
        ld a,(sc_g) : add a,a : add a,a : add a,a : ld l,a : ld e,a
        ld a,(sc_r) : add a,high SHP : ld h,a : ld a,(sc_r) : add a,#80 : ld d,a
        ld b,8
6       push bc : push hl : push de : ld bc,8 : ldir : pop de : pop hl : ld a,l : add a,32 : ld l,a : ld e,a : pop bc : djnz 6B
        call sc_sa : push hl : ld de,#9800-SHA : add hl,de : ex de,hl : pop hl : ld bc,8 : ldir
        ; the back buffer's EGA group -> the slot
        ld a,(sc_s) : call sc_pg : inc a : call sc_w2
        ld a,(bf) : or a : ld a,PS3 : jr z,7F : ld a,PS1
7       push af : call sc_w1 : call sc_cp8 : pop af
        add a,4 : call sc_w1
        ld a,(sc_s) : call sc_pg : add a,2 : call sc_w2 : call sc_cp8
.nxg    ld a,(sc_g) : inc a : ld (sc_g),a : cp 4 : jp c,2B
        ret
sc_cs   db 0
sc_ok   db 0
; HL = SHA + r*32 + 8g
sc_sa   ld a,(sc_r) : rrca : rrca : rrca : ld l,a : and #1F : ld h,a : ld a,l : and #E0 : ld l,a
        ld a,(sc_g) : add a,a : add a,a : add a,a : add a,l : ld l,a
        ld de,SHA : add hl,de : ret
; W1 -> W2: lines 4..195, 32 bytes at +0 and +#2000
sc_cpall
        ld hl,#4000+4*40 : ld b,192
1       push bc : push hl
        ld a,h : add a,#40 : ld d,a : ld e,l : ld bc,32 : ldir
        pop hl : push hl
        ld a,h : add a,#20 : ld h,a : add a,#40 : ld d,a : ld e,l : ld bc,32 : ldir
        pop hl : ld bc,40 : add hl,bc
        pop bc : djnz 1B
        ret
