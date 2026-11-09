; ------------------------------------------------------------------ the wide field's scrolling (UPG, #FAE0)
; ---- scrolling by shifting (state A, EGA). lay_fall (DI, the game's windows): HL = the game's routine + 3.
; The shift is only noted (sh_off: new(p) = old(p - sh_off), flat over 40-byte lines) and the marks moved with the
; field; sh_do (before the next conversion of OUTDSC) moves the back buffer and the shadow (sh_mv), the panels (sh_pan).
sh_fall ld ix,sh_tab : ld b,4
1       ld e,(ix+0) : ld d,(ix+1) : or a : sbc hl,de : add hl,de : jr z,2F
        ld de,5 : add ix,de : djnz 1B
        ld a,1 : ld (fall),a : ret              ; (someone else: all again)
2       call xs_scr
        ld l,(ix+2) : ld h,(ix+3) : ld de,(sh_off) : add hl,de : ld (sh_off),hl
        ld a,1 : ld (sh_pend),a
        ld a,(ix+4) : or a : jp z,.lt : dec a : jp z,.rt : dec a : jp z,.up
        ; down 8 lines (URT): the rows' marks one down, row 0 new
        ld hl,fe_row+FDN-2 : call .dn : ld hl,fe_lin+FDN-2 : call .dn : ld hl,fs_row+FDN-2 : call .dn
        ld hl,fdrow+FDN-2 : call .dn : ld hl,fdlin+FDN-2 : call .dn
        ld a,#1F : ld (fe_row),a : ld a,#FF : ld (fe_lin),a : ret
.dn     ld de,1 : add hl,de : ex de,hl : ld hl,0 : add hl,de : dec hl     ; DE = last, HL = last - 1
        ld bc,FDN-1 : lddr : ex de,hl : ld (hl),0 : ret
.up     ; up 8 lines (DRT): the rows' marks one up, row 24 new
        ld hl,fe_row : call .u1 : ld hl,fe_lin : call .u1 : ld hl,fs_row : call .u1
        ld hl,fdrow : call .u1 : ld hl,fdlin : call .u1
        ld a,#1F : ld (fe_row+FDN-1),a : ld a,#FF : ld (fe_lin+FDN-1),a : ret
.u1     ld d,h : ld e,l : inc hl : ld bc,FDN-1 : ldir : ex de,hl : ld (hl),0 : ret
.lt     ; a byte left (RRT): a group's bytes into it or the one before; column 39 new
        ld hl,fe_row : call .l1 : ld hl,fdrow : call .l1
        ld hl,fe_row : ld c,#10 : jr .col
.l1     ld b,FDN
3       ld a,(hl) : srl a : or (hl) : ld (hl),a : inc hl : djnz 3B
        ret
.rt     ; a byte right (LRT): column 0 new
        ld hl,fe_row : call .r1 : ld hl,fdrow : call .r1
        ld hl,fe_row : ld c,#01
.col    ld b,FDN
4       ld a,(hl) : or c : ld (hl),a : push hl : ld de,FDN : add hl,de : ld (hl),#FF : pop hl : inc hl : djnz 4B
        ret
.r1     ld b,FDN
5       ld a,(hl) : add a,a : or (hl) : and #1F : ld (hl),a : inc hl : djnz 5B
        ret
sh_tab  dw G_RRT+3,-1 : db 0
        dw G_LRT+3,1 : db 1
        dw G_DRT+3,-320 : db 2
        dw G_URT+3,320 : db 3

sp_dx   db 0
sp_dy   db 0                                    ; rows (8 lines)
sp_y8   dw 0                                    ; 8 sp_dy
; rectangle IX's picture moved by (sp_dx bytes, sp_dy rows): the field where it is now (not under it) all out
sp_rect ld a,(sp_dy) : ld l,a : add a,a : sbc a,a : ld h,a : add hl,hl : add hl,hl : add hl,hl : ld (sp_y8),hl
        call sp_wrap
        ld a,(sp_dx) : or a : jr z,2F
        ; columns beside it: dx > 0 [x+n, x+n+dx), dx < 0 [x+dx, x); its lines moved
        bit 7,a : jr nz,1F
        ld a,(ix+0) : add a,(ix+1) : ld b,a : ld hl,sp_dx : add a,(hl) : ld c,a : jr 11F
1       ld hl,sp_dx : ld a,(ix+0) : add a,(hl) : ld b,a : ld a,(ix+0) : ld c,a
11      ld e,(ix+2) : ld d,0 : ld hl,(sp_y8) : add hl,de : push hl : ex de,hl
        ld l,(ix+3) : ld h,0 : add hl,de : pop de : call sp_box
2       ld a,(sp_dy) : or a : ret z
        ; lines above / below it: dy > 0 [y+h, y+h+8dy), dy < 0 [y+8dy, y); its columns moved
        ld hl,sp_dx : ld a,(ix+0) : add a,(hl) : ld b,a : add a,(ix+1) : ld c,a
        ld a,(sp_dy) : bit 7,a : jr nz,3F
        ld e,(ix+2) : ld d,0 : ld l,(ix+3) : ld h,d : add hl,de : ex de,hl     ; DE = y + h
        ld hl,(sp_y8) : add hl,de : jp sp_box
3       ld l,(ix+2) : ld h,0 : ex de,hl : ld hl,(sp_y8) : add hl,de : ex de,hl  ; DE = y + 8dy, HL = y
        jp sp_box
; a keyed rectangle: its own transparent pixels may hold its moved picture: its keyed columns (all: copy 2) again
sp_key  ld a,(ix+5) : or a : ret z
        ld e,(ix+2) : ld d,0 : ld l,(ix+3) : ld h,d : add hl,de
        ld b,(ix+0) : ld a,b : add a,(ix+1) : ld c,a
        ld a,(ix+5) : cp 2 : jp z,sp_box        ; 2: all of it
        ; the first / last column: only if a picture moved into it (left: something moved left)
        ld a,(sp_kf) : rrca : jr nc,1F
        push bc : push de : push hl : ld c,b : inc c : call sp_box : pop hl : pop de : pop bc
1       ld a,(ix+5) : cp 3 : ret nz
        ld a,(sp_kf) : and 2 : ret z
        ld b,c : dec b : jp sp_box              ; 3: the last too
sp_kf   db 0                                    ; bit 0: a move left, bit 1: right (sh_pan)
; the part of it moved past the right / left edge (flat: into the next / previous line's other end)
sp_wrap ld a,(ix+0) : add a,(ix+1) : ld hl,sp_dx : add a,(hl) : sub 41 : jr c,1F
        inc a : ld c,a : ld b,0 : ld de,1 : jr 3F           ; [0, x+n+dx-40), a line down
1       ld a,(ix+0) : add a,(hl) : bit 7,a : ret z
        add a,40 : ld b,a : ld c,40 : ld de,-1                ; [x+dx+40, 40), a line up
3       ld l,(ix+2) : ld h,0 : add hl,de : push bc : ld bc,(sp_y8) : add hl,bc : pop bc
        ex de,hl : ld l,(ix+3) : ld h,0 : add hl,de : jp sp_box
; columns B..C-1 (signed), lines DE..HL-1 (signed): converted again (marked, the shadow made different there)
sp_box  bit 7,b : jr z,1F : ld b,0
1       ld a,b : cp 40 : ret nc
        bit 7,c : ret nz
        ld a,c : cp 41 : jr c,2F : ld c,40
2       ld a,b : cp c : ret nc
        bit 7,h : ret nz                        ; (all above)
        ld a,h : or a : jr nz,3F : ld a,l : cp 201 : jr c,4F
3       ld hl,200
4       bit 7,d : jr z,5F : ld de,0
5       ld a,d : or a : ret nz
        ld a,e : cp l : ret nc                  ; (H = 0 now, L <= 200)
        ld a,l : sub e : ld (sb_e),a            ; lines
        ld a,b : ld (sb_c),a : ld a,c : sub b : ld (sb_n),a
        ; the groups B / 8 .. (C - 1) / 8 of rows E / 8 .. (L - 1) / 8 marked (all their lines)
        ld a,c : dec a : rrca : rrca : rrca : and 7 : inc a : call gbit : dec a : ld c,a
        ld a,b : rrca : rrca : rrca : and 7 : call gbit : dec a : cpl : and c : ld c,a
        ld a,l : dec a : rrca : rrca : rrca : and #1F : ld b,a      ; the last row
        ld a,e : rrca : rrca : rrca : and #1F : push af : neg : add a,b : inc a : ld b,a   ; rows
        pop af : ld hl,fe_row : add a,l : ld l,a : jr nc,6F : inc h
6       ld a,(hl) : or c : ld (hl),a : push hl : ld a,l : add a,FDN : ld l,a : jr nc,61F : inc h
61      ld (hl),#FF : pop hl : inc hl : djnz 6B
        ; the shadow there made different from the field (converted where it differs: only these bytes)
        WIN P_W1, TPG                          ; (the shadow at W1 #5000)
        ld l,e : ld h,0 : add hl,hl : add hl,hl : ld b,h : ld c,l : add hl,hl : push hl     ; 4e, 8e
        add hl,hl : add hl,hl : add hl,bc : pop bc : add hl,bc                          ; 44e
        ld a,(sb_c) : ld c,a : ld b,0 : add hl,bc : ld bc,BDSC+32*BW+2 : add hl,bc : ex de,hl   ; DE = field
        ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld b,h : ld c,l : add hl,hl : add hl,hl : add hl,bc   ; 40e
        ld a,(sb_c) : ld c,a : ld b,0 : add hl,bc : ld bc,FSH-#8000 : add hl,bc         ; HL = shadow
        ld a,(sb_e) : ld c,a
7       ld a,(sb_n) : ld b,a
8       ld a,(de) : cpl : ld (hl),a : inc hl : inc de : djnz 8B
        ld a,(sb_n) : neg : push af : add a,40 : add a,l : ld l,a : jr nc,9F : inc h
9       pop af : add a,BW : add a,e : ld e,a : jr nc,10F : inc d
10      dec c : jr nz,7B
        ret
sb_c    db 0
sb_n    db 0
sb_g    db 0
sb_e    db 0
; 8000 bytes at HL moved by sh_o
sh_rg   ld de,(sh_o) : bit 7,d : jr z,1F
        ld (sh_t),hl : or a : sbc hl,de : push hl               ; down in memory: from base - o to base
        ld hl,8000 : add hl,de : ld b,h : ld c,l
        pop hl : ld de,(sh_t) : jp mv_f
1       ld bc,7999 : add hl,bc : ld (sh_t),hl : or a : sbc hl,de : push hl     ; up: from the end
        ld hl,8000 : or a : sbc hl,de : ld b,h : ld c,l
        pop hl : ld de,(sh_t) : jp mv_b
sh_t    dw 0
sh_o    dw 0
; HL = offset in a part, BC = bytes (< 256): from W1 (+0, +#2000) to W2 at offset + sh_off (within the part)
ss_run  ld de,(sh_off) : add hl,de              ; destination
        bit 7,h : jr z,1F
        ld a,h : inc a : ret nz                 ; (far before the part)
        ld a,c : add a,l : ld c,a : ret nc      ; from -dest on: bytes + dest
        or a : ret z
        ld hl,0
1       ld de,8000 : or a : sbc hl,de : add hl,de : ret nc     ; past the part
        push hl : add hl,bc : ld de,8001 : or a : sbc hl,de : jr c,2F
        inc hl : ld a,c : sub l : ld c,a        ; cut at the part's end
2       pop hl
        ld a,c : or a : ret z
        ld (ss_d),hl
        ld a,40 : sub c : add a,a : ld c,a : ld b,0 : push hl : ld hl,pn_l40 : add hl,bc : ld (ss_ent+1),hl : pop hl
        ld de,(sh_off) : or a : sbc hl,de : ld de,#4000 : add hl,de     ; HL = source
        ex de,hl : ld hl,(ss_d) : ld a,h : add a,#80 : ld h,a : ex de,hl  ; DE = destination
        push hl : push de : call ss_ent : pop de : pop hl
        set 5,h : set 5,d
ss_ent  jp 0                                    ; (into pn_l40: LDI x bytes)
ss_d    dw 0
; the run at offset HL (C bytes) on the row's marked lines (ss_l)
ss_blk  ld (ss_o),hl : ld a,c : ld (ss_n),a
        ld de,(sh_off) : add hl,de : bit 7,h : jr nz,.slow            ; the first line's destination
        ld (ss_d),hl : ld de,280 : add hl,de : add hl,bc : ld de,8001 : or a : sbc hl,de : jr nc,.slow
        ; all of it within the part: line by line, both parts
        ld a,40 : sub c : add a,a : ld e,a : ld d,0 : ld hl,pn_l40 : add hl,de : ld (ss_ent+1),hl
        ld hl,(ss_o) : ld de,#4000 : add hl,de : ex de,hl : ld hl,(ss_d) : ld a,h : add a,#80 : ld h,a : ex de,hl
        call 1F : set 5,h : set 5,d
1       push hl : push de : ld a,(ss_l) : ld c,a : ld b,8
2       push bc : push hl : push de
        rrc c : call c,ss_ent
        pop hl : ld bc,40 : add hl,bc : ex de,hl : pop hl : add hl,bc
        pop bc : rrc c : djnz 2B
        pop de : pop hl : ret
.slow   ld a,(ss_l) : ld c,a : ld b,8 : ld hl,(ss_o)
3       push bc : push hl
        rrc c : jr nc,4F
        ld a,(ss_n) : ld c,a : ld b,0 : call ss_run
4       pop hl : ld bc,40 : add hl,bc : pop bc : rrc c : djnz 3B
        ret
ss_o    dw 0
ss_n    db 0
; fc_t2 (kept in OVPG #A000) -> TPG #EF40 (bat_on, the game's windows, DI; own stack: the game's may be in W1)
t2_ld   ld (t2_sp),sp : ld sp,#3F60
        WIN P_W1, OVPG
        WIN P_W2, TPG
        ld hl,#6000 : ld de,#AF40 : ld bc,tpg2_img_end-tpg2_img : ldir
        ld hl,#6400 : ld de,#B320 : ld bc,tpg3_img_end-tpg3_img : ldir
        WIN P_W1, MPG                          ; the object planes empty (obj.asm: OB_V .. M's end)
        ld hl,OB_Z0-#8000 : ld de,OB_Z0-#8000+1 : ld bc,OB_Z1-OB_Z0-1 : ld (hl),0 : ldir
        XS_CLR
        WIN P_W1, PG_ZX+5
        WIN P_W2, PG_ZX+2
        ld sp,(t2_sp) : ret
t2_sp   dw 0
; HL -> DE, BC (> 0) bytes, forward / backward (16 at a time)
mv_f    ld a,c : and 15 : jr z,1F
        push bc : ld c,a : ld b,0 : ldir : pop bc
        ld a,c : and #F0 : ld c,a : or b : ret z
1
        DUP 16
        ldi
        EDUP
        jp pe,1B
        ret
mv_b    ld a,c : and 15 : jr z,1F
        push bc : ld c,a : ld b,0 : lddr : pop bc
        ld a,c : and #F0 : ld c,a : or b : ret z
1
        DUP 16
        ldd
        EDUP
        jp pe,1B
        ret

; a scroll step skipped (sk_go) and still pending: the next mouse poll (ui_mouse, fights) converts at once - while the
; game goes on scrolling that already has its next step, else (stopped) the last one is shown without waiting
sk_pol  ld a,(sh_pend) : or a : ret z
        ld a,(sk_c) : or a : ret nz
        ld a,63 : ld (od_cnt),a : ret
