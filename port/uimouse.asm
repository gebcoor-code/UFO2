; ------------------------------------------------------------------ the mouse (page UPG; ui_mouse in window 0 calls it)
; A = base, D = signed delta, B = lo, C = hi -> A = clamp(base + delta)
cadd    push hl : push de
        ld l,a : ld h,0 : ld e,d : ld a,d : rla : sbc a,a : ld d,a
        add hl,de
        bit 7,h : jr nz,.lo
        ld a,h : or a : jr nz,.hi
        ld a,l : cp b : jr c,.lo
        ld a,c : cp l : jr c,.hi
        ld a,l : jr .r
.lo     ld a,b : jr .r
.hi     ld a,c
.r      pop de : pop hl : ret

; the game's mouse routine (called from the game's code, the game's windows)
ui_mouse_u
        ld hl,POLLN : inc (hl)                  ; (mx.asm hk_mx: a held whole picture out at the game's poll)
        ld hl,10 : add hl,sp : ld a,(hl) : inc hl : ld h,(hl) : ld l,a : ld (MO_RT),hl    ; (far_g, CONTR's PUSH$)
        ld a,(MUS_TRK) : cp 5 : jr nz,0F        ; a fight's music waits for its field on the screen (fs_all done)
        ld a,(ega) : or a : jr z,1F : ld a,(fs_all) : or a : jr nz,0F
1       ld a,2 : ld (MUS_TRK),a
0       call sk_pol
        ld hl,(G_COORD)                         ; L = x, H = y
        ld bc,#FBDF : ld de,(G_OLDCO) : ld (mo_de),de
        in a,(c) : ld (G_OLDCO),a : sub e : ld e,a      ; E = dx
        ld b,#FF : in a,(c) : ld (G_OLDCO+1),a : sub d : neg : ld d,a   ; D = dy
        ; sensitivity: delta * spd / 4 (remainders kept)
        push hl
        ld a,e : call m_clmp : ld hl,acc_x : call scale : ld e,a
        ld a,d : call m_clmp : ld hl,acc_y : call scale : ld d,a
        ld hl,x_kb : call far_x : ld (kfire),a  ; the keys: their move added, their button
        pop hl
        ld a,(ega) : or a : jr nz,.geo
        ; ZX screen mode: the game's limits, no panel; the 3D fight: the joystick's bits too (x_3d)
        ld a,(MUS_TRK) : cp 3 : jr nz,0F
        push hl : push de : ld hl,x_3d : call far_x
        jr nc,$+7 : ld hl,btn_l : ld (hl),0        ; (the game waits after the 3D view: no click latched meanwhile)
        ld hl,G_CONTRB : or (hl) : ld (hl),a : pop de : pop hl
0
        xor a : ld (svc),a : ld (free),a
        push de
        ld a,h : ld b,2 : ld c,#BE : call cadd : ld h,a
        pop de : ld d,e
        ld a,l : ld b,2 : ld c,#FD : call cadd : ld l,a
        ld a,l : rrca : rrca : rrca : and #1F : ld (bxy),a     ; (the wide fight's BMOV: the cell)
        ld a,h : rrca : rrca : rrca : and #1F : ld (bxy+1),a
        jp .xok
.geo    ; our cursor (scx, scy: the screen) follows the game's one, unless in the panel or the game moved it itself
        ld (m_dxy),de
        ld a,d : or e : jr z,01F : xor a : ld (cs_hid),a  ; (moved: our cursor back)
01
        ld a,(bwide) : or a : jp nz,.wide
        ld a,(free) : or a : jr nz,1F
        ld a,(lastx) : cp l : jr z,7F
        ld a,l : ld (scx),a : xor a : ld (scx+1),a
7       ld a,(lasty) : cp h : jr z,1F
        ld a,h : add a,4 : ld (scy),a
1       ld a,(m_dy) : ld d,a : ld a,(scy) : ld b,0 : ld c,196 : call cadd : ld (scy),a
        ld a,(m_dx) : ld e,a : rla : sbc a,a : ld d,a
        ld hl,(scx) : add hl,de
        bit 7,h : jr z,2F : ld hl,0
2       ld de,0 : or a : sbc hl,de : add hl,de : jr nc,3F : ld hl,0
3       ld de,XMAX+1 : or a : sbc hl,de : add hl,de : jr c,4F : ld hl,XMAX
4       ld (scx),hl
        ; outside the game's window (its MMOV: x > MWINX, y > MWINY; x <= #FC, y <= 187) our cursor is free:
        ; the game's one waits at the window's edge, the game gets no buttons
        xor a : ld (svc),a : ld (free),a
        ld a,h : or a : jr z,5F
        ld a,1 : ld (svc),a : ld (free),a : ld hl,(lastx) : jp .xok      ; the panel: the game's cursor stays (at an edge the fight would scroll)
5       ld a,(G_MWINX) : cp l : jr c,8F
        inc a : ld l,a : ld a,1 : ld (free),a
8       ld a,l : cp #FC : jr c,6F : ld l,#FC
6       ld a,(scy) : sub 4 : jr nc,9F : xor a
9       ld h,a
        ld a,(G_MWINX+1) : cp h : jr c,10F
        inc a : ld h,a : ld a,1 : ld (free),a
10      ld a,h : cp 188 : jr c,11F : ld h,187
11      ld a,l : ld (lastx),a : ld a,h : ld (lasty),a
        jp .xok
; the wide fight: our cursor moves on its own; state A: the game gets the character cell (bxy) for BMOV
; (pn_bxy: the field's cells, the panel's elements as the ZX panel's cells, the scroll edges), always the buttons
.wide   ld a,(m_dy) : ld d,a : ld a,(scy) : ld b,0 : ld c,196 : call cadd : ld (scy),a
        ld a,(m_dx) : ld e,a : rla : sbc a,a : ld d,a
        ld hl,(scx) : add hl,de
        bit 7,h : jr z,1F : ld hl,0
1       ld de,XMAX+1 : or a : sbc hl,de : add hl,de : jr c,2F : ld hl,XMAX
2       ld (scx),hl
        xor a : ld (svc),a : ld (free),a
        ld a,(bst) : or a : jr z,3F
        ld a,h : or a : jr z,.wg                ; state B: past x 255 no buttons, the game's cursor stays
        ld a,1 : ld (free),a : ld hl,(lastx) : jr .xok
3       call pn_bxy
        ld hl,x_snap : call far_x               ; (the aim on an alien: his cell)
        ld hl,x_hot : call far_x : jr nc,31F    ; a quick key: a click on its panel cell
        ld (bxy),de : ld a,1 : ld (kfire),a : jr .xok
31
        ld a,(pn_tabk) : or a : jr z,4F
        ld a,1 : ld (free),a : inc a : ld (svc),a : ld hl,(lastx) : jr .xok     ; a tab: ours (not the game's)
4       ld hl,(scx) : jr .wg
.wg     ld a,h : or a : ld a,l : jr z,10F : ld a,#FC
10      cp #FC : jr c,11F : ld a,#FC
11      ld l,a : ld a,(scy) : sub 4 : jr nc,12F : xor a
12      cp 188 : jr c,13F : ld a,187
13      ld h,a : ld (lastx),hl
.xok    ld (G_COORD),hl
        ; buttons
        ld bc,#FADF : in a,(c) : cpl : and 7 : cp 7 : jr nz,$+3 : xor a : ld hl,btn_l : or (hl) : ld (hl),0 : ld hl,kfire : or (hl) : ld e,a     ; (and a click latched meanwhile, the keys' button)
        or a : jr nz,$+6 : inc a : ld (PM_REL),a        ; (released: build/mods.py SELPM)
        ld a,(oldbtn) : ld d,a : ld a,e : ld (oldbtn),a
        ld a,(free) : or a : jr nz,.click
        ld a,(m_eat) : or a : jr z,1F           ; a click of ours: the game gets no button till all released
        ld a,e : or a : jr nz,9F : ld (m_eat),a
1       ld a,e : rlca : rlca : rlca : rlca
        ld hl,G_CONTRB : or (hl) : ld (hl),a
        ld de,(mo_de)                           ; as the game's routine leaves them: DE = old counters
        ret
.click  ld a,e : ld (m_eat),a
        ld a,(svc) : or a : jr z,9F
        ld a,d : or a : jr nz,9F              ; was pressed already
        ld a,e : or a : call nz,.hit
9       ld de,(mo_de) : ret
.hit    ld a,(svc) : cp 2 : jr nz,0F
        ld a,(pn_tabk) : ld hl,pv_req : or (hl) : ld (hl),a : ret       ; a tab: its panel hidden / shown
0       ld a,(scy) : cp BT_Y0+NBT*BT_STEP : jr c,01F    ; below our buttons, a menu (the game's INIMNU: MWINX, Y
        ld hl,(G_MWINX) : ld de,#0101 : or a : sbc hl,de : ret nz       ;  1, 1): a click past its screen is outside
        ld (G_COORD),hl : ld (lastx),hl : ld hl,G_CONTRB : set 4,(hl) : ret   ;  its window - the game's at (0, 0): a level up
01      ld a,(scy) : cp 9 : jr nc,1F          ; the music's icon (top right)
        ld a,(scx) : cp 304-256 : jr c,1F
        ld a,(MUS_OFF) : xor 1 : ld (MUS_OFF),a
        ld a,1 : ld (ui_red),a : ret
1       ld a,(DBG) : or a : ret z            ; (no service buttons but "UFO2 DEBUG")
        ; x in the buttons BT_X..+39
        ld a,(scx) : sub BT_X-256 : cp 40 : ret nc
        ; which button
        ld a,(scy) : ld c,a
        ld b,0 : ld e,BT_Y0
4       ld a,c : sub e : ret c
        cp BT_H : jr c,5F
        ld a,e : add a,BT_STEP : ld e,a
        inc b : ld a,b : cp NBT : jr c,4B
        ret
5       ld a,b : cp 2 : jr z,.tog
        cp 3 : jr c,6F
        IFDEF SRCB
        ld a,1 : ld (LZ_ON),a : ld (ui_red),a   ; (LAZY green from now)
        ld hl,lazy : jp far_x
        ENDIF
        ret
6       inc a : ld (pend),a : ld a,150 : ld (pend_t),a
        ld a,1 : ld (ui_red),a : ret
.tog    ld a,(d3off) : xor 1 : ld (d3off),a
        ld a,1 : ld (ui_red),a : ret

; a counter's jump (an emulator's window out of focus and back): at most 40 a frame
m_clmp  bit 7,a : jr nz,1F
        cp 41 : ret c : ld a,40 : ret
1       cp -40 : ret nc : ld a,-40 : ret
; mouse sensitivity: A = signed delta, HL -> accumulator (word) -> A = delta * spd / 4 (floor, remainder kept)
spd     db 4
kfire   db 0                    ; the keys' button (x_kb)
acc_x   dw 0
acc_y   dw 0
scale   push bc : push de : push hl
        ld e,a : rla : sbc a,a : ld d,a         ; DE = delta
        ld a,(hl) : inc hl : ld h,(hl) : ld l,a ; HL = accumulator
        ld a,(spd) : ld b,a
1       add hl,de : djnz 1B
        ld d,h : ld e,l
        sra d : rr e : sra d : rr e             ; DE = floor(acc / 4)
        ld a,l : and 3 : ld c,a                 ; remainder
        pop hl : ld (hl),c                      ; (the high byte stays 0)
        ld a,e
        pop de : pop bc : ret

; state A: the mouse (scx, scy) -> the game's cell (bxy): the field (x < 296, y 8..159) BX = x / 8 + 1, BY = 1..19;
; the panel's elements: their ZX cells (rows from l_PROW = 20); the edges: x < 4 -> BX 0, x >= 316 -> BX 39,
; y < 8 -> BY 0 (scroll); the corner right of the panel: BY 26 (scroll down); else (29, 25)
PN_ROWD equ 32                          ; the game's l_PROW + 6: scroll down
pn_tabk db 0                            ; the tab under the cursor: 1 the bottom panel's, 2 the side one's
pn_bxy  push ix : xor a : ld (pn_tabk),a : ld (pn_ovr),a : call 0F : pop ix : ret
0       ld hl,(scx) : ld a,(scy) : ld c,a
        ; the tabs
        ld de,PN2_TBX : ld b,26 : call .inr : jr nc,1F
        ld a,(pv_bot) : or a : ld a,c : jr z,19F : add a,PN2_TBY2-PN2_TBY
19      sub PN2_TBY2 : cp 10 : jr nc,1F : ld a,1 : jr .tab
1       ld de,PN2_TSX : ld a,(pv_side) : or a : jr nz,11F : ld de,PN2_TSX2
11      ld b,10 : call .inr : jr nc,2F
        ld a,c : sub PN2_TSY : cp 26 : jr nc,2F : ld a,2
.tab    ld (pn_tabk),a : jp .none               ; (a click is ours; no scrolling over a tab)
        ; the screen's edges: scroll (over a panel / the name: our arrow still)
2       call pn_ovp
        ld a,c : cp 2 : jr nc,3F
        ld b,0 : jr .bx                         ; the top: BY 0
3       cp 195 : jr c,4F
        ld b,PN_ROWD : jr .bx                   ; the bottom
4       ld a,h : or a : jr nz,5F : ld a,l : cp 2 : jr nc,5F
        call .by : ld c,0 : jr .st              ; the left: BX 0
5       ld de,315 : or a : sbc hl,de : add hl,de : jr c,6F
        call .by : ld c,41 : jr .st             ; the right: BX 41
        ; the panels shown
6       ld a,(pv_bot) : or a : jr z,7F
        ld a,c : cp 160 : jr c,7F
        ld de,56 : ld b,208 : call .inr : jr c,.pan
7       ld a,(pv_side) : or a : jr z,8F
        ld de,296 : ld b,24 : call .inr : jr nc,8F
        ld a,c : sub 18 : cp 163 : jr c,.none
8       ld a,c : cp 8 : jr nc,9F                ; the name
        ld de,80 : ld b,160 : call .inr : jr c,.none
        ; the field: BX = x / 8 + 1 (1..40), BY = y / 8 + 1 (1..25)
9       call .by
.bx     srl h : rr l : srl l : srl l : ld a,l : inc a : ld c,a
.st     ld (bxy),bc : ret
.by     ld a,(scy) : rrca : rrca : rrca : and #1F : inc a : ld b,a : ret
.none   ld a,1 : ld (pn_ovr),a : ld bc,(PN_ROWD-1)*256+29 : jr .st      ; (the game: no zone)
        ; HL = x, DE = x0, B = w -> CY: x0 <= x < x0 + w (HL kept)
.inr    push hl : or a : sbc hl,de : jr c,1F
        ld a,h : or a : jr nz,1F
        ld a,l : cp b : pop hl : ret
1       pop hl : or a : ret
.pan    ld a,1 : ld (pn_ovr),a : ld ix,pn_mouse
4       ld e,(ix+0) : ld d,(ix+1) : ld a,d : and e : inc a : jr z,.none           ; (#FFFF: the end)
        or a : sbc hl,de : jr c,5F              ; x < dx
        ld a,l : cp (ix+3) : jr nc,5F           ; x >= dx + w (w < 256, x - dx < 256 here)
        ld a,h : or a : jr nz,5F
        ld a,c : sub (ix+2) : jr c,5F : cp (ix+4) : jr nc,5F
        ld c,(ix+5) : ld b,(ix+6) : jr .st
5       ld hl,(scx) : ld de,7 : add ix,de : jr 4B
