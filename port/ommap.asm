; ---- XPG #FC00.. (past UFO2.TIL's index; copied there at the start - zxl.asm): the world map's marks drawn
; (ico.asm ov_map -> om_upd); their lists past this code
; ---- the back buffer's marks (om_dp: as drawn there) -> om_ml's: those changed and shown erased (ours back:
; PLA's), then the shown ones changed or near an erased one drawn; pixel by pixel, the map's cells only (om_at)
om_upd  WIN P_W1, PLA
        xor a : ld (om_xa),a
        ld a,#FF : ld (om_ar),a
        ld a,(bf) : or a : ld a,#7F-PS3 : ld e,#7F-PS7 : jr z,3F : ld a,#7F-PS1 : ld e,#7F-PS5
3       ld (om_pa),a : ld a,e : ld (om_pb),a
        ld hl,(om_dp) : ld de,om_ml : ld ix,om_el                          ; (the erased: x, y)
4       ld a,(hl) : inc a : jr z,49F
        call om_cmp : jr z,48F
        push hl : inc hl : inc hl : inc hl : ld a,(hl) : pop hl : or a : jr z,48F
        push hl : push de : ld c,0 : call om_drw : pop de : pop hl
        inc hl : ld a,(hl) : ld (ix+0),a : inc hl : ld a,(hl) : ld (ix+1),a : dec hl : dec hl : inc ix : inc ix
48      ld bc,4 : add hl,bc : ld a,(de) : inc a : jr z,4B : ex de,hl : add hl,bc : ex de,hl : jr 4B
49      ld (ix+0),#FF
        ld hl,(om_dp) : ld de,om_ml
5       ld a,(de) : inc a : jr z,59F
        inc de : inc de : inc de : ld a,(de) : dec de : dec de : dec de : or a : jr z,58F
        ld a,(hl) : inc a : jr z,57F
        call om_cmp : jr nz,57F
        call om_near : jr nc,58F
57      push hl : push de : ex de,hl : ld c,1 : call om_drw : pop de : pop hl
58      ld bc,4 : ex de,hl : add hl,bc : ex de,hl : ld a,(hl) : inc a : jr z,5B : add hl,bc : jr 5B
59      ld hl,om_ml : ld de,(om_dp) : ld bc,4*OM_N+1 : ldir
        ld bc,P_W1 : ld a,(om_pa) : out (c),a : ld b,H_W2 : ld a,(om_pb) : out (c),a   ; (W1, W2: the back buffer)
        ret
; CY: the entry DE near an erased one (its pixels may be gone)
om_near ld a,(om_xa) : or a : scf : ret nz                          ; (a crosshair changed: all of them)
        push hl : push de : ex de,hl : inc hl : ld d,(hl) : inc hl : ld e,(hl) : ld hl,om_el
1       ld a,(hl) : inc a : jr z,3F
        ld a,(hl) : sub d : jr nc,$+4 : neg : cp 6 : jr nc,2F
        inc hl : ld a,(hl) : dec hl : sub e : jr nc,$+4 : neg : cp 7 : jr nc,2F
        scf : jr 4F
2       inc hl : inc hl : jr 1B
3       or a
4       pop de : pop hl : ret
; the entry HL: C = 0 erased (ours back), 1 drawn
om_drw  ld a,c : ld (om_md),a
        ld a,(hl) : cp 10 : jp z,om_dcr
        ld b,a : add a,a : add a,b : add a,a : add a,b : add a,a : ld e,a : ld d,0   ; (type * 14)
        inc hl : ld a,(hl) : dec a : ld (om_x0),a : inc hl : ld a,(hl) : dec a : ld (om_ly),a
        ld hl,om_sh : add hl,de
        push hl : ld de,12 : add hl,de : ld a,(hl) : ld (om_ce),a : inc hl : ld a,(hl) : ld (om_cf),a : pop hl
        ld b,6
1       push bc : push hl
        ld a,(om_ly) : cp 120 : jp nc,8F
        call om_rb
        pop hl : push hl
        ld a,(om_md) : or a : jr nz,2F
        ld a,(hl) : inc hl : or (hl) : call om_row : jr 8F               ; (erased: all its pixels)
2       ld a,(hl) : or a : jr z,3F
        ld c,a : ld a,(om_ce) : call om_col : ld a,c : call om_row        ; (the edge, then the shape)
3       inc hl : ld a,(om_cf) : call om_col : ld a,(hl) : call om_row
8       pop hl : inc hl : inc hl : ld a,(om_ly) : inc a : ld (om_ly),a : pop bc : dec b : jp nz,1B
        ret
; line om_ly's bases: om_lp (ours), om_lo (the buffer), om_at (its cells; HL, DE, B gone)
om_rb   ld a,(om_ly) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : ld e,l : ld d,h
        add hl,hl : add hl,de : ld de,#4000 : add hl,de : ld (om_lp),hl    ; (ours: y * 96)
        ld a,(om_ly) : add a,4 : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld e,l : ld d,h
        add hl,hl : add hl,hl : add hl,de : ld (om_lo),hl                   ; (the buffer: (y + 4) * 40)
        ld a,(om_ly) : and #F8 : ld hl,om_ar : cp (hl) : ret z               ; (its cells: om_at - 0 the map's)
        ld (hl),a : ld l,a : ld h,0 : add hl,hl : add hl,hl : ld de,#5800 : add hl,de
        WIN P_W1, PG_ZX+7
        ld de,om_at : ld b,24
12      ld a,(hl) : and #FE : sub #68 : ld (de),a : inc hl : inc de : djnz 12B
        WIN P_W1, PLA
11      ret
; the target's crosshair (xlic.asm PMAP; om_gat: type 10, x, y): its lines - x 1..190 at y, y 1..118 at x - white
om_dcr  inc hl : ld a,(hl) : ld (om_x0),a : inc hl : ld a,(hl) : ld (om_cy),a
        ld a,1 : ld (om_xa),a
        ld a,15 : call om_col : ld a,1
1       ld (om_ly),a : call om_rb : ld a,(om_x0) : call om_p1 : ld a,(om_ly) : inc a : cp 119 : jr c,1B
        ld a,(om_cy) : cp 120 : ret nc : ld (om_ly),a : call om_rb
        ld a,1 : ld b,190
2       call om_p1 : inc a : djnz 2B
        ret
om_col  ld (om_cl),a : ld b,a : and 7 : rlca : rlca : rlca : ld e,a : ld a,b : and #40 : add a,a : or e : ld (om_cr),a : ret
; A = a row's pixels (bit 7: x - 1)
om_row  or a : ret z
        ld c,a : ld a,(om_x0) : ld b,8
1       rl c : call c,om_p1 : inc a : djnz 1B
        ret
; pixel A of line om_ly (its bases om_at, om_lp, om_lo): om_md 0 - ours, 1 - om_cl / om_cr
om_p1   cp 192 : ret nc
        push af : push bc : push de : push hl
        ld c,a : rrca : rrca : rrca : and 31 : ld e,a : ld d,0              ; (its byte)
        ld hl,om_at : add hl,de : ld a,(hl) : or a : jr nz,9F              ; (not a map cell)
        ld a,c : rrca : and 3 : ld b,a                                      ; (its pair)
        ld a,(om_md) : or a : jr nz,2F
        push de : ld hl,om_po : ld a,b : add a,l : ld l,a : jr nc,$+3 : inc h
        ld a,(hl) : add a,e : ld e,a : ld hl,(om_lp) : add hl,de : ld a,(hl) : pop de
        jr 3F
2       ld a,(om_cl) : bit 0,c : jr z,3F : ld a,(om_cr)
3       ld h,a : ld a,c : and 1 : ld a,#B8 : jr z,4F : ld a,#47
4       ld l,a : cpl : and h : ld h,a                                       ; (H: its bits, L: the others kept)
        ld a,b : and 1 : ld a,(om_pa) : jr z,5F : ld a,(om_pb)
5       push bc : ld bc,P_W2 : out (c),a : pop bc
        push hl : ld hl,(om_lo) : add hl,de : ld a,b : and 2 : ld a,#80 : jr z,6F : ld a,#A0
6       add a,h : ld h,a : pop de
        ld a,(hl) : and e : or d : ld (hl),a
9       pop hl : pop de : pop bc : pop af : ret
        display "xpg marks end ",$
        ASSERT $ <= om_ml
