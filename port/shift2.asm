; ------------------------------------------------------------------ the pending shift, done (UPG, #F570)
; sh_do (W1 W2 = the back buffer X, the front Y shown): each buffer has the offset its picture is at (off0, off1),
; the shadow the one of the field (cur_off) + the game's new scrolls (sh_off). X moved by t = cur_off + sh_off - off[X]
; (one move, not a copy of Y: Y's picture is moved the same at its turn), the shadow by sh_off; what Y has more
; (psync) copied into X moved by sh_off; the panels drawn again where they are, the field where their moved
; pictures are now made "all out"
sh_pan  ld a,(PL_USE) : or a : jp nz,.all           ; (the colour plane: the field all out from it - no moves)
        ld a,(bf) : xor 1 : call sh_px : ld e,(hl) : inc hl : ld d,(hl)
        ld hl,(cur_off) : ld bc,(sh_off) : add hl,bc : or a : sbc hl,de : ld (sh_tv),hl
        call sh_dec : jp c,.all
        ld a,(sp_dx) : ld (sh_tx),a : ld a,(sp_dy) : ld (sh_ty),a
        ld hl,(sh_off) : call sh_dec : jp c,.all
        ld a,(sp_dx) : ld (sh_dx),a : ld a,(sp_dy) : ld (sh_dy),a
        ld hl,(sh_tv) : ld a,h : or l : jr z,1F
        ld (sh_o),hl
        ld hl,#4000 : call sh_rg : ld hl,#6000 : call sh_rg
        ld hl,#8000 : call sh_rg : ld hl,#A000 : call sh_rg
1       call sh_fsh                             ; (the shadow: wideu.asm)
2       call sh_sync
        ld hl,(sh_tv) : ld de,(sh_off) : or a : sbc hl,de : call nz,sh_bands
        ld hl,(sh_tv) : ld a,h : or l : ld hl,(sh_off) : or h : or l : jp z,.fin
        ld hl,(sh_off) : ld a,h : or l : jr z,31F
        ld a,1 : ld (bchg),a                    ; (the field moved: X to be shown; else X = Y now)
31      ld a,(sh_tx) : ld b,a : ld a,(sh_dx) : ld c,0 : call 32F : ld a,b : call 32F : ld a,c : ld (sp_kf),a
        xor a : ld (pn_la),a : ld (pn_ca),a : ld a,200 : ld (pn_lb),a : ld a,40 : ld (pn_cb),a
        ld ix,pn_rects
3       ld a,(ix+0) : cp #FF : jr z,.fin
        call pn_on : jr z,4F
        ld a,(bf) : xor 1 : call pn_rc : call sp_key
        ld a,(sh_tx) : ld (sp_dx),a : ld a,(sh_ty) : ld (sp_dy),a : call sp_rect
        ld a,(sh_dx) : ld (sp_dx),a : ld a,(sh_dy) : ld (sp_dy),a : call sp_rect
4       ld de,PNR : add ix,de : jr 3B
.all    call sh_all                             ; too far: X all out (the shadow then too)
        ld a,1 : ld (bchg),a
        ld hl,psync : ld b,2*SYN
5       ld (hl),0 : inc hl : djnz 5B
.fin    ld hl,(cur_off) : ld de,(sh_off) : add hl,de : ld (cur_off),hl : ex de,hl
        ld a,(bf) : xor 1 : call sh_px : ld (hl),e : inc hl : ld (hl),d
        ld hl,0 : ld (sh_off),hl
        ld hl,(off0) : ld de,(off1) : or a : sbc hl,de : ld a,h : or l : jr z,6F : ld a,1
6       ld (sh_pend),a                          ; (Y to be moved at its turn)
        jp pn_back
; psync (what Y has more) copied into X, moved by sh_off; then the background of Y's cursor (in what was copied)
sh_sync ld a,(bf) : ld (ss_y),a
        ld c,0 : call ss_pass : ld c,4 : call ss_pass
        call pn_back
        call 9F
        ld hl,psync : ld b,2*SYN
1       ld (hl),0 : inc hl : djnz 1B
        ret
        ; Y's cursor: its background at its place moved by sh_off - only where Y was copied (psync), the rest of X
        ; is its own (no cursor)
9       ld a,(cs_on) : or a : ret z
        ld a,(cs_y) : ld (ss_r),a : ld ix,cs_buf : ld b,CS_H
2       push bc
        ld a,(ss_r) : cp 200 : jr nc,4F
        ld b,a : rrca : rrca : rrca : and #1F : ld e,a : ld d,0 : ld hl,psync : add hl,de
        ld a,(hl) : or a : jr z,4F : ld (ss_g),a
        ld de,SYN : add hl,de : ld a,b : and 7 : call gbit : and (hl) : jr z,4F     ; (this line not copied)
        ld a,b : call yoff
        ld a,(cs_p0) : ld c,a : ld b,5
3       push bc : ld a,c : cp 160 : jr nc,31F
        rrca : rrca : rrca : rrca : rrca : and 7 : call gbit : ld hl,ss_g : and (hl) : jr z,31F    ; (its group)
        ld a,c
        and 3 : ld e,a : ld d,0 : ld hl,pbase : add hl,de : ld a,(hl) : ld (ss_pb),a
        ld a,c : srl a : srl a : ld e,a : ld hl,(y_off) : add hl,de : ld de,(sh_off) : add hl,de
        bit 7,h : jr nz,31F : ld de,8000 : or a : sbc hl,de : add hl,de : jr nc,31F
        ld a,(ss_pb) : add a,h : ld h,a : ld a,(ix+0) : ld (hl),a
31      inc ix : pop bc : inc c : djnz 3B
        jr 5F
4       ld de,5 : add ix,de
5       ld hl,ss_r : inc (hl)
        pop bc : dec b : jp nz,2B
        ret
; one pass: C = 0 the pages 1 / 3 (parts 0, 2), 4: 5 / 7 (parts 1, 3); W1 = Y's page, W2 = X's
ss_pass ld a,(ss_y) : add a,a : inc a : add a,c : ld b,a : ld a,#7F : sub b : SCRV
        push bc : ld bc,P_W1 : out (c),a : pop bc
        ld a,(ss_y) : xor 1 : add a,a : inc a : add a,c : ld b,a : ld a,#7F : sub b : SCRV
        ld bc,P_W2 : out (c),a
        ld c,0                                  ; the rows
1       ld hl,psync : ld b,0 : add hl,bc : ld a,(hl) : or a : jr z,7F
        ld (ss_g),a : ld de,SYN : add hl,de : ld a,(hl) : ld (ss_l),a
        ld l,c : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l
        add hl,hl : add hl,hl : add hl,de : ld (ss_s),hl                ; the row's offset (320 r)
        push bc
        ld a,(ss_g) : ld c,a : ld b,0           ; B = group, C = mask
3       ld a,b : cp 5 : jr nc,6F
        rrc c : jr c,4F
        inc b : jr 3B
4       ld e,b                                  ; a run from group E
41      inc b : ld a,b : cp 5 : jr nc,5F
        rrc c : jr c,41B
        rlc c                                   ; (its bit for the next search)
5       push bc
        ld a,b : sub e : add a,a : add a,a : add a,a : ld c,a : ld b,0     ; bytes
        ld a,e : add a,a : add a,a : add a,a : ld e,a : ld d,0 : ld hl,(ss_s) : add hl,de
        call ss_blk
        pop bc : jr 3B
6       pop bc
7       inc c : ld a,(sy_n) : cp c : jp nz,1B
        ret
ss_y    db 0
ss_g    db 0
ss_l    db 0
ss_r    db 0
ss_s    dw 0
ss_pb   db 0
; A = a move's dx -> C |= 1 (left) / 2 (right)
32      or a : ret z : jp m,33F : set 1,c : ret
33      set 0,c : ret
sh_px   ld hl,off0 : or a : ret z : ld hl,off1 : ret
off0    dw 0                    ; the offsets of the buffers' pictures and of the shadow (cur_off)
off1    dw 0
cur_off dw 0
sh_tv   dw 0
sh_tx   db 0
sh_ty   db 0
sh_dx   db 0
sh_dy   db 0
; a keyed byte: its pixels of colour 8 (left: bits #47 = #40, right: #B8 = #80) not copied
kb      ld a,(hl) : ld c,a
        and #47 : cp #40 : ld b,#47 : jr nz,1F : ld b,0
1       ld a,c : and #B8 : cp #80 : ld a,b : jr z,2F : or #B8
2       ld b,a : and c : ld c,a
        ld a,b : cpl : ex de,hl : and (hl) : or c : ld (hl),a : ex de,hl
        inc hl : inc de : ret
; X moved by t, the shadow by sh_off (t != sh_off): what either move left at an edge (no source) is "different" now
sh_bands
        ld hl,(sh_tv) : call 0F
        ld a,(sh_tx) : ld b,a : ld a,(sh_dx) : call 5F : jr nc,4F     ; (sh_off's within t's: scrolling on)
        ld a,(sh_ty) : ld b,a : ld a,(sh_dy) : call 5F : ret c
4       ld hl,(sh_off)
0       call sh_dec : ret c
        ld a,(sp_dx) : or a : jr z,2F
        bit 7,a : jr z,1F
        add a,40 : ld b,a : ld c,40 : jr 11F    ; columns [40 + dx, 40)
1       ld c,a : ld b,0                         ; [0, dx)
11      ld de,0 : ld hl,200 : call sp_box
2       ld a,(sp_dy) : or a : ret z
        ld l,a : add a,a : sbc a,a : ld h,a : add hl,hl : add hl,hl : add hl,hl : ld b,0 : ld c,40
        bit 7,h : jr z,3F
        ld de,200 : add hl,de : ex de,hl : ld hl,200 : jp sp_box        ; lines [200 + 8 dy, 200)
3       ld de,0 : jp sp_box                     ; [0, 8 dy)
; A = d, B = t (signed) -> CY: d's band within t's (d = 0, or the same sign and |t| >= |d|)
5       or a : scf : ret z
        ld c,a : xor b : rla : ccf : ret nc
        bit 7,c : jr nz,6F
        ld a,b : cp c : ccf : ret
6       ld a,c : cp b : ccf : ret
; the field's row A just converted into the back buffer: the panels shown over it there (far_ui from conv_rw)
pn_ovl  add a,a : add a,a : add a,a : ld (pn_la),a : add a,8 : ld (pn_lb),a
        ld a,(fw_g) : ld c,0                    ; its columns: the converted groups' (first .. last)
0       rrca : jr c,01F : inc c : jr 0B
01      ld a,c : add a,a : add a,a : add a,a : ld (pn_ca),a
        ld a,(fw_g) : ld b,8
03      dec b : rlca : jr nc,03B
        ld a,b : inc a : add a,a : add a,a : add a,a : ld (pn_cb),a
        ld ix,pn_rects
1       ld a,(ix+0) : cp #FF : jr z,2F
        call pn_on : jr z,3F
        ld a,(ix+5) : or a : jr z,3F            ; opaque: the conversion left it (fc_t2)
        cp 2 : jr z,31F
        ld b,(ix+0) : call pn_k1                ; keyed edges: only them
        ld a,(ix+5) : cp 3 : jr nz,3F
        ld a,(ix+0) : add a,(ix+1) : dec a : ld b,a : call pn_k1 : jr 3F
31      ld a,(bf) : xor 1 : call pn_rc
3       ld de,PNR : add ix,de : jr 1B
2       jp pn_back
; column B of rectangle IX, if converted (pn_ca .. pn_cb)
pn_k1   ld hl,(pn_ca) : ld a,b : cp l : ret c : cp h : ret nc
        push hl : ld l,b : inc b : ld h,b : ld (pn_ca),hl
        ld a,(bf) : xor 1 : call pn_rc
        pop hl : ld (pn_ca),hl : ret
; the tabs' colour: grey (7) always (was: the field's paper - the user: grey), their black edge keeps them seen. The
; first time: the tabs' pixels in the picture recoloured, the shown ones copied onto both buffers
tb_la   db #FF                                  ; the tabs' colour in the picture now (#FF: as made, yellow)
; -> A = the colour wanted, NZ: not the picture's
tb_new  ld a,7 : ld hl,tb_la : cp (hl) : ret
tb_col  ld (tb_la),a : ld d,a : add a,a : add a,a : add a,a : ld e,a     ; D, E: the left / right pixel's bits
        ld ix,pn_rects+3*PNR
1       ld a,(ix+0) : cp #FF : jr z,2F
        ld a,OPG0 : call 5F : ld a,OPG1 : call 5F
        ld bc,PNR : add ix,bc : jr 1B
2       ld ix,pn_rects+3*PNR
3       ld a,(ix+0) : cp #FF : ret z
        call pn_on : call nz,pn_rc2
        ld bc,PNR : add ix,bc : jr 3B
        ; the picture's page A (W1): the rectangle's picture (its place - the offset), parts 0 / 1 and 2 / 3
5       push de : ld b,a : ld a,#7F : sub b : ld bc,P_W1 : out (c),a
        ld l,(ix+2) : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        ld e,(ix+0) : ld d,0 : add hl,de : ld e,(ix+6) : ld d,(ix+7) : or a : sbc hl,de : set 6,h : pop de
        push hl : call 6F : pop hl : set 5,h
6       ld b,(ix+3)
7       push bc : push hl : ld b,(ix+1)
8       ld a,(hl) : ld c,a : and #47 : jr z,81F : cp #40 : jr z,81F    ; the left pixel: not black, not KEY
        ld a,c : and #B8 : or d : ld c,a
81      ld a,c : and #B8 : jr z,82F : cp #80 : jr z,82F
        ld a,c : and #47 : or e : ld c,a
82      ld (hl),c : inc hl : djnz 8B
        pop hl : ld bc,40 : add hl,bc : pop bc : djnz 7B
        ret

; ---- our cursor's kinds (xpg.asm's cursor.asm, ui.asm cs_mode: bits 0, 1 = the game's 3D cursor's kind (PIMG - xMARKE) / 128;
; bit 3: over the fight's field - 0 walk, 1 aim: a little cross; 3 contact: a little sword; 2 lift: up / down
; arrows; else (panels, tabs, the map...) the arrow; bit 2: both floors shown ("1/2": a little "2" right of it);
; rows: mask, colour (1 white); hot spots (x, y)
cs_hot  db -7,-2, -7,-2, 3,5, -7,-2     ; over the field: walk / aim - the cross 7 right, 2 below the point; lift; the sword too
; ---- (pn_bxy, uimouse.asm) HL = x, C = y: over a panel shown -> pn_ovr = 1 (HL, C kept)
pn_ovp   ld a,(pv_bot) : or a : jr z,1F
        ld a,c : cp 160 : jr c,1F
        ld de,56 : ld b,208 : call pn_bxy.inr : jr c,3F
1       ld a,(pv_side) : or a : jr z,2F
        ld de,296 : ld b,24 : call pn_bxy.inr : jr nc,2F
        ld a,c : sub 18 : cp 163 : jr c,3F
2       ret                                     ; (the name: no button - the field's cursor stays)
3       ld a,1 : ld (pn_ovr),a : ret
; (enc_u.asm's) A = bf's: that buffer in W1, W2; its cursor off
ep_mb   ld bc,P_W1 : or a : ld a,#7F-PS1 : jr z,1F : ld a,#7F-PS3
1       out (c),a : sub 4 : ld b,H_W2 : out (c),a : ret
ep_ch   ld a,(cs_on) : or a : ret z : xor a : ld (cs_md),a : jp cs_iof   ; (cs_on: cursor.asm clears it)
; od_conv (OUTDSC or the game's own waits): xtil.asm's draw sequence ends there (iv_c)
sk_go2  ld hl,iv_c : inc (hl) : jp sk_go
; a conversion step's end (pn_fl): the items' / signs' overlays (ico.asm ov_fl; A = 1: the back's cursor off first)
ov_fl3  ld hl,ov_fl : call far_x : dec a : call z,ov_flb : jp pn2_upd
; (uipage.asm is_geo's patterns: room here)
xl_pat  db #3A : dw G_HAC2 : db #FE,#D6
xg_pat  XG_PAT
