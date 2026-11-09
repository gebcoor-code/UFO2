; ---- our cursor (MPG's MX; uipage.asm cs_iof -> far_m: W1, W2 = a buffer): the 5 pairs of each line under it, (cs_md) = 1
; save and draw, 0 restore. Its pairs' bytes (keep, value: cs_kv) made again only when its shape, the "2" or x's
; parity change (cs_ck)
cs_iox  ld hl,(cs_x) : ld a,l : and 1 : ld (cs_s),a
        srl h : rr l : ld a,l : ld (cs_p0),a
        ld hl,cs_off : ld b,5                   ; the 5 pairs' offsets in a line (part base, byte)
0       push af : ld c,a : and 3 : ld e,a : ld d,0 : push hl : ld hl,pbase : add hl,de : ld d,(hl) : pop hl
        ld a,c : srl a : srl a : ld (hl),a : inc hl : ld (hl),d : inc hl
        pop af : inc a : djnz 0B
        ld ix,cs_buf
        ld a,(cs_md) : or a : jp z,.fr          ; (off: the saved bytes back)
        ld a,(cs_mode) : call .sel
3       push iy : ld iy,cs_kv
        ld a,(cs_y) : ld (cs_ln),a : ld a,CS_H : ld (cs_n),a
.row    ld a,(cs_ln) : cp 200 : jr nc,.end
        call yoff
        ld a,(cs_p0) : ld c,a : ld b,5 : ld de,cs_off
.p      ld a,c : cp 160 : jr nc,.n
        push bc : ex de,hl : ld c,(hl) : inc hl : ld b,(hl) : dec hl : ex de,hl
        ld hl,(y_off) : add hl,bc : ld a,(hl) : ld (ix+0),a : and (iy+0) : or (iy+1) : ld (hl),a : pop bc
.n      inc ix : inc iy : inc iy : inc de : inc de : inc c : djnz .p
        ld hl,cs_ln : inc (hl) : ld hl,cs_n : dec (hl) : jr nz,.row
.end    pop iy : ret
; cs_kv: per row (mask, colour from cs_sp; the "2"), per pair: cs_keep's AND, OR
.bld    ld hl,(cs_sp) : ld (cs_ck),hl : ld hl,(cs_ovp) : ld (cs_ck+2),hl : ld a,(cs_s) : ld (cs_ck+4),a
        push iy : ld iy,cs_kv
        ld a,CS_H : ld (cs_n),a
.brow   ld hl,(cs_sp) : ld d,(hl) : inc hl : ld b,(hl) : inc hl : ld (cs_sp),hl   ; D = mask, B = colour
        ld e,0 : ld c,0
        ld a,(cs_ovp+1) : or a : jr z,3F : ld a,(cs_n) : cp 6 : jr c,3F
        ld a,d : or 3 : ld d,a : ld e,#C0 : ld a,b : and #FC : ld b,a     ; (columns 6..9 of rows 0..5: black, its picture white)
        push hl : ld a,(cs_n) : neg : add a,CS_H : ld hl,(cs_ovp) : add a,l : ld l,a : jr nc,4F : inc h
4       ld a,(hl) : pop hl
        rrca : jr nc,5F : set 6,c
5       rrca : jr nc,6F : set 7,c
6       rrca : jr nc,7F : set 0,b
7       rrca : jr nc,3F : set 1,b
3       ld a,(cs_s) : or a : jr z,1F
        srl d : rr e : srl b : rr c                             ; odd x: one pixel later in the pairs
1       ld a,5 : ld (cs_k),a
.bp     xor a
        sla e : rl d : rla : sla e : rl d : rla                 ; mask of the pair
        add a,a : add a,a : ld (cs_t),a
        xor a
        sla c : rl b : rla : sla c : rl b : rla                 ; colour of the pair
        push de : ld hl,cs_t : or (hl) : ld e,a : ld d,0 : ld hl,cs_keep : add hl,de
        ld a,(hl) : ld (iy+0),a : ld de,16 : add hl,de : ld a,(hl) : ld (iy+1),a : pop de
        inc iy : inc iy
        ld a,(cs_k) : dec a : ld (cs_k),a : jr nz,.bp
        ld a,(cs_n) : dec a : ld (cs_n),a : jp nz,.brow
        pop iy : ret
; A = a kind: its shape, the "2" -> cs_kv (made again only if not what it is)
.sel    ld hl,0 : bit 2,a : jr z,11F : ld hl,cs_two     ; the little "2" right of it
11      ld (cs_ovp),hl
        ld hl,cs_shape : bit 3,a : jr z,1F      ; the arrow (not over the field)
        and 3 : ld hl,cs_lift : cp 2 : jr z,1F
        ld hl,cs_swp : cp 3 : jr z,1F
        ld hl,cs_crs
1       ld (cs_sp),hl
        ld de,(cs_ck) : or a : sbc hl,de : jr nz,2F
        ld hl,(cs_ovp) : ld de,(cs_ck+2) : or a : sbc hl,de : jr nz,2F
        ld a,(cs_s) : ld hl,cs_ck+4 : cp (hl) : ret z
2       jp .bld
.fr     push iy : call 4F : pop iy : ret
; off: a saved byte back only where the buffer still has what the cursor made of it (the kind drawn: cs_on - 1; the
; callers leave it, cleared here) - where something drew over the cursor meanwhile (the field: a cell opened under it),
; that stays (was: the old picture back - a black hole under the cursor). No kind known (cs_on 0): all back
4       ld a,(cs_on) : ld b,a : xor a : ld (cs_on),a : ld iy,0 : or b : jr z,0F
        dec a : call .sel : ld iy,cs_kv
0       ld a,(cs_y) : ld (cs_ln),a : ld a,CS_H : ld (cs_n),a
.frow   ld a,(cs_ln) : cp 200 : ret nc
        call yoff
        ld a,(cs_p0) : ld c,a : ld b,5 : ld de,cs_off
.fp     ld a,c : cp 160 : jr nc,.fn
        push bc : ex de,hl : ld c,(hl) : inc hl : ld b,(hl) : dec hl : ex de,hl
        ld hl,(y_off) : add hl,bc
        ld a,iyh : or a : jr z,1F
        ld a,(ix+0) : and (iy+0) : or (iy+1) : cp (hl) : jr nz,2F     ; (not as drawn: kept)
1       ld a,(ix+0) : ld (hl),a
2       pop bc
.fn     inc ix : inc de : inc de : inc c : ld a,iyh : or a : jr z,3F : inc iy : inc iy
3       djnz .fp
        ld hl,cs_ln : inc (hl) : ld hl,cs_n : dec (hl) : jr nz,.frow
        ret
cs_s    db 0
cs_ovp  dw 0
cs_off  ds 10
cs_sp   dw 0
cs_ln   db 0
cs_n    db 0
cs_k    db 0
cs_t    db 0
cs_ck   ds 5                                    ; (cs_kv's: the shape, the "2", the parity)
cs_kv   ds CS_H*5*2
; index = mask (left, right) * 4 + colour (left, right): byte = byte AND keep OR value
cs_keep db #FF,#FF,#FF,#FF, #47,#47,#47,#47, #B8,#B8,#B8,#B8, 0,0,0,0
        db 0,0,0,0, 0,#B8,0,#B8, 0,0,#47,#47, 0,#B8,#47,#FF
; the kinds (ui.asm cs_mode: bits 0, 1 = the game's 3D cursor's kind (PIMG - xMARKE) / 128; bit 3: over the fight's
; field - 0 walk, 1 aim: a little cross; 3 contact: a little sword; 2 lift: up / down arrows; else (panels, tabs, the
; map...) the arrow; bit 2: both floors shown ("1/2": a little "2" right of it); rows: mask, colour (1 white); hot
; spots: shift2.asm cs_hot
cs_lift db #10,#00,#38,#10,#7C,#38,#FE,#7C,#FE,#10,#38,#10,#FE,#10,#FE,#7C,#7C,#38,#38,#10,#10,#00
; rows: mask, colour (1 = white, 0 = black), bit 7 = left
cs_shape
        db #80,#00, #C0,#00, #E0,#40, #F0,#60, #F8,#70, #FC,#78, #FE,#7C, #FF,#7E, #FF,#70, #FC,#58, #DC,#00   ; (the tail's end black: the edge closed)
cs_crs  db #70,#20,#F8,#20,#F8,#D8,#F8,#20,#70,#20,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00     ; cross.png
cs_swp  db #70,#20,#F8,#50,#F8,#50,#F8,#50,#F8,#F8,#F8,#20,#70,#20,#00,#00,#00,#00,#00,#00,#00,#00     ; sword.png
cs_two  db 0,6,2,4,6,0                  ; the "2" (2nd.png): bits 3..0 = columns 6..9 (on black), rows 0..5
