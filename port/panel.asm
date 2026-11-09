; ------------------------------------------------------------------ the fight's panels (state A; UPG)
; Ready blocks (tools/mkpanel2.py -> UFO2.PNL, loaded at the start): the panels' fixed picture straight into
; OPG0 / OPG1 (pages 16, 17: EGA's page layout, OPG0 = parts 0, 2, OPG1 = parts 1, 3), the atlas (pages 18, 19:
; pre-coloured variants of the changing slots: the buttons, the guns' cells, the rank / armour signs). Names: made
; by the game itself (NWRDM into DSCR; LAY_NAME) and kept converted in page 20 (24 of them).
; No reading of screen 7's pixels: at each conversion step's end (pn_fl) the game's state the panels show (39 bytes:
; pn2_rd) is compared with the one drawn; the slots it changed are drawn from the blocks into the picture, their lines
; marked; the marked lines then copied onto both buffers (pn_show).
OPG0    equ 16                          ; the panels' picture: parts 0, 2
OPG1    equ 17                          ; parts 1, 3
APG     equ 18                          ; the atlas (18, 19)
NMPG     equ 20                          ; the names (24 x 640: 80 pairs x 8 lines)
PN_BLK  equ #F000                       ; (UPG) a block on its way from the atlas / the names (640 at most: #F280.. ui6)
PN_ROW  equ #EF00                       ; (UPG) a line's pixel colours (up to 256)
PN_CMB  equ #F400                       ; (UPG, 256, made by pn2_init) left * 16 + right colour -> the pair's byte
pn2_s   equ #F500                       ; (UPG) the state now (PN2_NS)
pn2_p   equ #F540                       ; the state drawn
; (#FE40.. : the scroll code, uipage.asm)
pn_inv  db 1                            ; 1: not started yet (PN_CMB, all slots to draw)
pn2_frc db 0                            ; 1: all slots to draw
pn_name db #FF                          ; the name shown (the names' slot; #FF: none)
pn_hl   dw G_MAN                        ; the last fighter of ours (pn2_rd)
pn2_nn  db 0                            ; the next names' slot to take
pn2_nk  ds 48,#FF                       ; the names' keys: the word, its dictionary (0: NAMES, 1: WORDS)
pv_bot  db 1                            ; 1: the bottom panel shown
pv_side db 1                            ; 1: the side panel shown
pv_req  db 0                            ; toggles asked (the mouse on a tab): bit 0 the bottom one, bit 1 the side one
pn2_vis db 1                            ; 1: the slot drawn is shown (its panel)

; ---- at the conversion step's end (far_ui; W3 = UPG): NZ = something to draw (pn_fl hides the cursors, then
; pn2_show): the slots the state changed -> the picture and both buffers; after state B all of it onto the screen
pn2_upd ld a,(bwide) : or a : ret z
        ld a,(bst) : or a : jr z,1F
        call pn_bc2 : xor a : ret
1       ld a,(pn_inv) : or a : call nz,pn2_init
        call pn2_rd
        call tb_new : ret nz                    ; (the tabs' colour)
        ld a,(pn_full) : ld hl,pn2_frc : or (hl) : ld hl,pv_req : or (hl) : ret nz
        ld hl,pn2_s : ld de,pn2_p : ld b,PN2_NS
2       ld a,(de) : cp (hl) : ret nz : inc hl : inc de : djnz 2B
        ret
pn2_show
        ld a,(pv_req) : or a : call nz,pn_tog
        call tb_new : call nz,tb_col
        call pn2_rd                             ; (pv_* may have changed)
        ld a,(pn_full) : or a : jr z,1F
        xor a : ld (pn_full),a : ld (pn2_fs),a  ; (the whole picture to be copied: the slots into it only)
1       call pn2_draw
        ld a,(pn2_fs) : or a : jr nz,3F
        inc a : ld (pn2_fs),a
        call pn_show
3       jp pn_back
; the tabs clicked: a panel hidden (the field under it converted again: forced) or shown (copied onto the screen)
pn_tog  ld b,a : xor a : ld (pv_req),a
        bit 0,b : jr z,2F
        push bc
        ld a,(pv_bot) : xor 1 : ld (pv_bot),a
        ld bc,18*256+7 : ld a,#1F : call z,pn_force             ; (with its tab over it: lines 149..)
        ld a,(pv_bot) : or a : ld ix,pn_rects+PNR : call nz,pn_rc2
        ld a,(pv_bot) : or a : ld ix,pn_rects+3*PNR : call nz,pn_rc2
        pop bc
2       bit 1,b : jr z,pn_pvw
        ld a,(pv_side) : xor 1 : ld (pv_side),a
        ld bc,2*256+21 : ld a,#10 : call z,pn_force
        ld a,(pv_side) : or a : ld ix,pn_rects+2*PNR : call nz,pn_rc2
        ld a,(pv_side) : or a : ld ix,pn_rects+5*PNR : call nz,pn_rc2
pn_pvw  ld a,(pv_side) : add a,a : ld hl,pv_bot : or (hl) : ld (pvw),a : ret
; field rows B.. (C of them), groups A: converted again, all of their bytes
pn_force
        ld e,a
1       push bc : ld a,b : ld c,a : ld b,0
        ld hl,fs_row : add hl,bc : ld (hl),#FF
        ld hl,fe_row : add hl,bc : ld a,e : or (hl) : ld (hl),a
        ld hl,fe_lin : add hl,bc : ld (hl),#FF
        pop bc : inc b : dec c : jr nz,1B
        ret
pn2_fs  db 1                            ; 1: the slots into both buffers too
pn2_init
        xor a : ld (pn_inv),a : inc a : ld (pn2_frc),a
        ld de,PN_CMB : ld bc,pn_tl
4       ld hl,pn_tr
5       ld a,(bc) : or (hl) : ld (de),a : inc de : inc l : ld a,l : cp low pn_tr+16 : jr nz,5B
        inc c : ld a,c : cp low pn_tl+16 : jr nz,4B
        ret

; ---- the state: 0 name, 1..12 the buttons' attributes, 13 CANF_B, 14 G_TIME, 15..21 LA_DIM, 22..25 guns,
; 26 the gun chosen, 27..30 ammo, 31..36 TU, EN, HEALTH, WOUND, MORAL, accuracy, 37 rank, 38 armour
pn2_rd  ld a,(pn_name) : ld (pn2_s),a
        WIN P_W1, 15                           ; screen 7 at #4000
        ld hl,pn2_bat : ld de,pn2_s+1 : ld b,12
1       ld a,(hl) : inc hl : push hl : ld h,(hl) : ld l,a : ld a,(hl) : pop hl : inc hl : ld (de),a : inc de : djnz 1B
        WIN P_W1, PG_ZX+5
        WIN P_W2, PG_ZX+2
        ld a,(G_CANFB) : ld (de),a : inc de
        ld a,(G_GTIME) : ld (de),a : inc de
        ld hl,G_LADIM : ld bc,7 : ldir
        ld hl,(G_HERAD) : push de : ld de,-G_MAN-10*32 : add hl,de : pop de : ld hl,(pn_hl) : jr c,0F
        ld hl,(G_HERAD) : ld (pn_hl),hl                 ; (ours: the aliens' turn's HER_AD - an alien's - not shown)
0       push hl : ld bc,17 : add hl,bc : ld bc,4 : ldir                                ; guns
        pop hl : push hl : ld bc,25 : add hl,bc : ld a,(hl) : and 3 : ld (de),a : inc de
        pop hl : push hl : ld bc,21 : add hl,bc : ld bc,4 : ldir                       ; ammo
        pop hl : push hl : ld bc,11 : add hl,bc : ld bc,6 : ldir                       ; TU..accuracy
        pop hl : ld bc,9 : add hl,bc : ldi : ldi                                       ; rank, armour
        ld a,(pv_bot) : ld (de),a : inc de : ld a,(pv_side) : ld (de),a                ; the tabs
        ret
pn2_bat                                         ; the buttons' attributes (screen 7 at #4000)
.j = 0
        DUP 3
.i = 0
        DUP 4
        dw #5800+(17+2*.j)*32+2+3*.i
.i = .i + 1
        EDUP
.j = .j + 1
        EDUP

; ---- the slots the state changed (or all) into the picture
pn2_draw
        ld iy,pn2_slots
1       ld a,(iy+0) : cp #FF : jr z,9F
        ld a,(pn2_frc) : or a : jr nz,2F
        ld a,(iy+1) : call pn2_ch : jr nz,2F
        ld a,(iy+2) : call pn2_ch : jr nz,2F
        ld a,(iy+3) : call pn2_ch : jr z,3F
2       call pn2_slot
3       ld de,16 : add iy,de : jr 1B
9       xor a : ld (pn2_frc),a
        ld hl,pn2_s : ld de,pn2_p : ld bc,PN2_NS : ldir
        ret
; A = a state byte's index (#FF: none) -> NZ: changed
pn2_ch  cp #FF : ret z
        ld e,a : ld d,0 : ld hl,pn2_s : add hl,de : ld a,(hl) : ld hl,pn2_p : add hl,de : cp (hl) : ret
; A = state byte (IY+1) -> A
pn2_v   ld e,(iy+1) : ld d,0 : ld hl,pn2_s : add hl,de : ld a,(hl) : ret
; the slot IY: type, state (3), x (2), y, w, h, atlas (2), size (2), c, m, panel
pn2_slot
        ld a,(iy+15) : or a : ld a,1 : jr z,0F
        ld a,(iy+15) : dec a : ld a,(pv_bot) : jr z,0F : ld a,(pv_side)
0       ld (pn2_vis),a
        WIN P_W1, OPG0
        WIN P_W2, OPG1
        ld a,(iy+0) : dec a : jr z,.name : dec a : jr z,.var : dec a : jp z,.fill : dec a : jp z,pn2_num
        ; 5: a gun's cell: gun (15: none) x chosen
        call pn2_v : cp 15 : jr c,1F : ld a,15
1       add a,a : ld c,a
        ld a,(pn2_s+26) : cp (iy+13) : jr nz,2F : inc c
2       ld a,c : jr .blk
.var    call pn2_v
        bit 0,(iy+14) : jr nz,3F
        cp #7A : ld a,0 : jr nz,.blk : inc a : jr .blk          ; a button: highlighted?
3       cp (iy+13) : jr c,.blk : jr z,.blk : ld a,(iy+13)       ; a sign: up to c
        ; block A of the slot's set (atlas)
.blk    ld e,(iy+11) : ld d,(iy+12) : ld hl,0
        or a : jr z,5F
        ld b,a
4       add hl,de : djnz 4B
5       ld e,(iy+9) : ld d,(iy+10) : add hl,de                  ; its address (#4000: the second page)
        ld a,APG : bit 6,h : jr z,6F : inc a
6       res 6,h : set 6,h : ld c,(iy+11) : ld b,(iy+12)
        call pn2_get
        jp pn2_blt
.name   ld a,(pn2_s) : cp 24 : jr nc,7F
        ld l,a : ld h,0 : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de    ; * 20
        add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl                                       ; * 640
        set 6,h : ld bc,640 : ld a,NMPG : call pn2_get
        jp pn2_blt
7       ld a,9 : jr pn2_fil                     ; no name: the blue strip
.fill   call pn2_v : bit 0,(iy+14) : jr z,8F
        cp 255 : ld a,#68 : jr z,8F             ; LA_DIM (as LA_OUT): none
        ld a,(hl) : rla : ld a,#58 : jr c,8F : ld a,#70
8       call pn2_pap
        ; the slot's pixels (x, w: any) colour A (the rest of the pairs at their ends black)
pn2_fil ld c,a
        ld a,(iy+4) : and 1 : ld (pn2_lead),a
        ld de,PN_ROW : jr z,1F : xor a : ld (de),a : inc de
1       ld b,(iy+7) : ld a,c
2       ld (de),a : inc de : djnz 2B
        xor a : ld (de),a
        ld a,(iy+7) : ld hl,pn2_lead : add a,(hl) : inc a : srl a : ld (pn2_np),a
        call pn2_pack
        ld l,(iy+4) : ld h,(iy+5) : srl h : rr l : ld a,l : ld (pn2_p0),a
        ld a,(iy+6) : ld (pn2_y),a : ld b,(iy+8)
3       push bc : call pn2_row : pop bc : djnz 3B
        ret
; PN_ROW's colours -> PN_BLK's pn2_np pairs
pn2_pack
        ld hl,PN_ROW : ld de,PN_BLK : ld a,(pn2_np) : ld b,a
1       ld a,(hl) : inc hl : add a,a : add a,a : add a,a : add a,a : or (hl) : inc hl
        push hl : ld l,a : ld h,high PN_CMB : ld a,(hl) : pop hl : ld (de),a : inc de : djnz 1B
        ret
; PN_BLK (rows of w / 2 pairs, h lines) -> the picture at the slot's x, y
pn2_blt ld hl,PN_BLK : ld c,1
pn2_bl1 ld a,(iy+8) : ld b,a
1       push bc : push hl
        ld a,(iy+8) : sub b : add a,(iy+6) : ld e,a                 ; the line
        ld a,(iy+4) : ld d,(iy+5) : srl d : rra                     ; the pair
        ld b,(iy+7) : srl b : call pn2_put
        pop hl : pop bc
        ld a,c : or a : jr z,2F
        ld e,(iy+7) : srl e : ld d,0 : add hl,de
2       djnz 1B
        ret
; A = an attribute -> its paper's colour (0..15)
pn2_pap rrca : rrca : rrca : and 7 : ret z : or 8 : ret      ; (the panels: bright)
; A = page, HL = its address (W1), BC = bytes -> PN_BLK (W1 = OPG0 again)
pn2_get push bc : ld b,a : ld a,#7F : sub b : ld bc,P_W1 : out (c),a : pop bc
        ld de,PN_BLK : ldir
        WIN P_W1, OPG0
        ret
; A = pair, E = line, HL = pairs, B = count -> the picture (and both buffers: pn2_fs)
pn2_put push hl : push bc : call pn2_ad : pop bc : pop hl
        ld (pn2_pd),de : ld (pn2_ph),hl : ld c,a : ld (pn2_pb),bc
        call pn2_wr
        ld a,(pn2_fs) : or a : ret z
        ld a,(pn2_vis) : or a : ret z
        xor a : call pn_map : call 1F
        ld a,1 : call pn_map : call 1F
        WIN P_W1, OPG0
        WIN P_W2, OPG1
        ret
1       ld de,(pn2_pd) : ld hl,(pn2_ph) : ld bc,(pn2_pb) : ld a,c : jr pn2_wr
pn2_pd  dw 0
pn2_ph  dw 0
pn2_pb  dw 0
; A = pair, E = line -> DE = its byte (W1 = OPG0, W2 = OPG1), A = its part
pn2_ad  push hl : push af
        ld l,e : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        pop af : push af : rrca : rrca : and #3F : add a,l : ld l,a : jr nc,1F : inc h
1       pop af : and 3 : push af : ld e,a : ld d,0 : push hl : ld hl,pn2_hb : add hl,de : ld a,(hl) : pop hl
        add a,h : ld d,a : ld e,l : pop af : pop hl : ret
pn2_hb  db #40,#80,#60,#A0
; HL = pairs, DE = the first one's byte, A = its part, B = count
pn2_wr  or a : jr z,.p0 : dec a : jr z,.p1 : dec a : jr z,.p2 : jr .p3
.p0     ld a,(hl) : inc hl : ld (de),a : dec b : ret z : ld a,d : add a,#40 : ld d,a
.p1     ld a,(hl) : inc hl : ld (de),a : dec b : ret z : ld a,d : sub #20 : ld d,a
.p2     ld a,(hl) : inc hl : ld (de),a : dec b : ret z : ld a,d : add a,#40 : ld d,a
.p3     ld a,(hl) : inc hl : ld (de),a : dec b : ret z : ld a,d : sub #60 : ld d,a : inc de : jr .p0

; ---- a number: x = the room's first pixel, w its width, y its first line (6 lines), c the colour, m: 0 as WB,
; 1 as GUNOUT (its last 2 characters), 2 as WB but 0 not shown. The digits: the game's font (pn2_dig)
pn2_num call pn2_v : ld (pn2_val),a
        ; the room's whole pairs black
        ld l,(iy+4) : ld h,(iy+5) : inc hl : srl h : rr l : ld a,l : ld (pn2_p0),a
        ld l,(iy+4) : ld h,(iy+5) : ld e,(iy+7) : ld d,0 : add hl,de : srl h : rr l
        ld a,(pn2_p0) : ld b,a : ld a,l : sub b : ld (pn2_np),a
        ld hl,PN_BLK : ld b,a : xor a
1       ld (hl),a : inc hl : djnz 1B
        ld a,(iy+6) : ld (pn2_y),a : ld b,6
2       push bc : call pn2_row : pop bc : djnz 2B
        ; its digits
        ld a,(pn2_val) : ld e,a : ld l,100 : call pn2_div : ld (pn2_dd),a
        ld l,10 : call pn2_div : ld (pn2_dd+1),a : ld a,e : ld (pn2_dd+2),a
        ld a,(iy+14) : cp 2 : jr nz,3F
        ld a,(pn2_val) : or a : ret z           ; ammo 0: nothing
3       ld hl,pn2_dd : ld b,3
        ld a,(hl) : or a : jr z,4F
        ld a,(iy+14) : cp 1 : jr nz,6F          ; WB: 3
        inc hl : dec b : jr 6F                  ; GUNOUT: its last 2
4       inc hl : dec b : ld a,(hl) : or a : jr nz,6F
        inc hl : dec b
6       ld (pn2_dp),hl : ld a,b : ld (pn2_n),a
        ; (6 + g) n - g pixels (g: the gap, 1 in a room narrower than 22) from c = x + (w - that) / 2; pairs from c & ~1
        ld a,(iy+7) : cp 22 : ld a,2 : jr nc,61F : dec a
61      ld (pn2_gp),a : add a,6 : ld c,a : xor a
62      add a,c : djnz 62B
        ld hl,pn2_gp : sub (hl) : ld e,a
        ld a,(iy+7) : sub e : srl a
        ld l,(iy+4) : ld h,(iy+5) : add a,l : ld l,a : jr nc,8F : inc h
8       ld a,l : and 1 : ld (pn2_lead),a        ; 1: a black pixel first
        srl h : rr l : ld a,l : ld (pn2_p0),a
        ld a,e : ld hl,pn2_lead : add a,(hl) : inc a : srl a : ld (pn2_np),a
        ld a,(iy+6) : ld (pn2_y),a
        ld b,0                                  ; B = the glyphs' row
9       push bc
        ld de,PN_ROW : ld a,(pn2_lead) : or a : jr z,10F : xor a : ld (de),a : inc de
10      ld hl,(pn2_dp) : ld a,(pn2_n) : ld c,a
11      push bc : push hl
        ld a,(hl) : ld l,a : add a,a : add a,l : add a,a : add a,b              ; digit * 6 + row
        ld l,a : ld h,0 : ld bc,pn2_dig : add hl,bc
        ld a,(hl) : add a,a : ld h,a                                            ; (column 0 out)
        ld b,6
12      xor a : sla h : jr nc,13F : ld a,(iy+13)
13      ld (de),a : inc de : djnz 12B
        xor a : ld (de),a : inc de : ld a,(pn2_gp) : dec a : jr z,14F : xor a : ld (de),a : inc de    ; the gap
14
        pop hl : pop bc : inc hl : dec c : jr nz,11B
        xor a : ld (de),a
        call pn2_pack
        call pn2_row
        pop bc : inc b : ld a,b : cp 6 : jr c,9B
        ret
; PN_BLK's pn2_np pairs -> line pn2_y (then the next), from pair pn2_p0
pn2_row ld a,(pn2_y) : ld e,a : inc a : ld (pn2_y),a
        ld hl,pn2_np : ld b,(hl) : ld hl,PN_BLK : ld a,(pn2_p0) : jp pn2_put
; E / L -> A, E = the remainder
pn2_div xor a
1       ld h,a : ld a,e : sub l : jr c,2F : ld e,a : ld a,h : inc a : jr 1B
2       ld a,h : ret
pn2_val db 0
pn2_gp  db 2
pn2_p0  db 0
pn2_y   db 0
pn2_n   db 0
pn2_np  db 0
pn2_lead db 0
pn2_dp  dw 0
pn2_dd  ds 3

; ---- LAY_NAME (the game: PANELM, NAMPRE; far_g): A = the word NWRDM printed into DSCR's row 0 (columns 6..):
; columns 5..24 kept converted (yellow on blue) unless kept already; it is the name shown now
pn2_name
        ld c,a : ld hl,(G_WORDSP) : ld de,G_NAMES : or a : sbc hl,de : ld b,0 : jr z,1F : inc b
1       ld hl,pn2_nk : ld e,0
2       ld a,(hl) : cp c : jr nz,3F : inc hl : ld a,(hl) : dec hl : cp b : jr z,9F
3       inc hl : inc hl : inc e : ld a,e : cp 24 : jr c,2B
        ld a,(pn2_nn) : ld e,a : inc a : cp 24 : jr c,4F : xor a
4       ld (pn2_nn),a
        ld l,e : ld h,0 : add hl,hl : ld a,l : add a,low pn2_nk : ld l,a : ld a,h : adc a,high pn2_nk : ld h,a
        ld (hl),c : inc hl : ld (hl),b
        push de : call pn2_nconv : pop de       ; (C, B: the word, its list)
9       ld a,e : ld (pn_name),a : ret
; E = the slot, C = the word, B = its list -> page NMPG (text.asm tx_nm -> textc.asm nm_cv: in our font)
pn2_nconv
        ld a,i : push af : di
        push de : ld a,c : ld de,P_W1 : push bc : ld b,d : ld c,e : ld e,a : ld a,#7F-NMPG : out (c),a
        ld b,H_W2 : ld a,#7F-(PG_ZX+1) : out (c),a : pop bc                     ; W1 = NMPG, W2 = bank 1 (the words)
        ld hl,G_NAMES-#4000 : ld a,b : or a : jr z,1F : ld hl,G_WORDS-#4000
1       ld b,e : inc b
2       ld a,(hl) : inc hl : cp #7E : jr nz,2B : djnz 2B                    ; (as NWRD)
        ld de,NM_B+1 : ld b,0
3       ld a,(hl) : inc hl : cp #80 : jr c,4F
        push hl : and #7F : add a,a : add a,low (G_TWCMPR-#4000) : ld l,a : ld a,high (G_TWCMPR-#4000) : adc a,0 : ld h,a   ; (a pair: as WORD)
        ld a,(hl) : call 5F : inc hl : ld a,(hl) : pop hl : jr 41F
4       cp #7E : jr nc,6F
41      call 5F : jr 3B
5       ld c,a : ld a,b : cp 20 : ret nc : ld a,c : ld (de),a : inc de : inc b : ret
6       ld a,b : ld (NM_B),a
        WIN P_W2, PG_ZX+2
        pop de : ld hl,tx_nm : call far_x       ; (E = the slot; W1 the game's again after)
        pop af : ret po : ei : ret

; ---- the panels' rectangles on the screen: columns x, n; lines y, h; shown: 0 always, 1 / 2 the bottom / side panel
; shown, 3 / 4 hidden; copy: 0 all, 1 the first column keyed, 3 the first and last, 2 all keyed (the picture's colour 8: the
; field shows); the picture's place = the screen's - the offset (the hidden tabs' pictures are elsewhere)
PNR     equ 8
pn_rects
        db 10,20,0,8,0,0 : dw 0                 ; the name
        db 7,26,160,40,1,3 : dw 0               ; the bottom panel (its box x 61..257)
        db 37,3,18,163,2,0 : dw 0               ; the side one (x 296..319)
        db PN2_TBX/8,4,PN2_TBY,10,1,2 : dw 0    ; the tabs: V over the bottom panel
        db PN2_TBX/8,4,PN2_TBY2,10,3,2 : dw PN2_TBD     ; ^ at the bottom
        db PN2_TSX/8,2,PN2_TSY,26,2,2 : dw 0    ; > left of the side panel
        db PN2_TSX2/8,2,PN2_TSY,26,4,2 : dw PN2_TSD     ; < at the right edge
        db #FF
; all of them shown: from the picture onto both buffers
pn_show xor a : ld (pn_la),a : ld a,200 : ld (pn_lb),a
        ld ix,pn_rects
1       ld a,(ix+0) : cp #FF : ret z
        call pn_on : call nz,pn_rc2
        ld de,PNR : add ix,de : jr 1B
; IX = a rectangle -> NZ: shown now
pn_on   ld a,(ix+4) : or a : jr z,1F
        cp 3 : jr nc,3F
        dec a : ld a,(pv_bot) : jr z,2F : ld a,(pv_side)
2       or a : ret
3       sub 3 : ld a,(pv_bot) : jr z,4F : ld a,(pv_side)
4       xor 1 : ret
1       inc a : ret
pn_la   db 0                                    ; lines pn_la .. pn_lb - 1 of it
pn_lb   db 0
pn_ca   db 0                                    ; columns pn_ca .. pn_cb - 1 of it
pn_cb   db 40
pn_y0   db 0
pn_n    db 0
pn_md   db 0
pn_k    db 0
pn_k2   db 0
pn_d1   dw 0
pn_d2   dw 0
pn_ny   db 0
pn_bk   db 0
pn_x0   db 0
; rectangle IX (all its lines) into both buffers
pn_rc2  xor a : ld (pn_la),a : ld (pn_ca),a : ld a,200 : ld (pn_lb),a : ld a,40 : ld (pn_cb),a
        xor a : call pn_rc : ld a,1
; rectangle IX's lines within pn_la..pn_lb from the picture into buffer A (0: pages 1 / 5, 1: 3 / 7)
pn_rc   ld (pn_bk),a
        ld a,(ix+2) : ld hl,pn_la : cp (hl) : jr nc,1F : ld a,(hl)
1       ld (pn_y0),a
        ld a,(ix+2) : add a,(ix+3) : ld hl,pn_lb : cp (hl) : jr c,2F : ld a,(hl)
2       ld hl,pn_y0 : sub (hl) : ret c : ret z
        ld (pn_ny),a
        ld a,(ix+0) : ld hl,pn_ca : cp (hl) : jr nc,5F : ld a,(hl)
5       ld (pn_x0),a : ld c,a
        ld a,(ix+0) : add a,(ix+1) : ld hl,pn_cb : cp (hl) : jr c,6F : ld a,(hl)
6       sub c : ret c : ret z
        ld (pn_n),a : ld c,a : ld b,0 : ld hl,#2000 : or a : sbc hl,bc : ld (pn_d1),hl  ; (the next part, the next line)
        ld hl,40-#2000 : sbc hl,bc : ld (pn_d2),hl
        ld a,(ix+5) : ld (pn_md),a : bit 0,a : ld a,c : jr z,7F     ; (keyed columns: not LDI)
        dec a : bit 1,(ix+5) : jr z,7F : dec a : jp p,7F : xor a
7       ld c,a : ld a,40 : sub c : add a,a : ld e,a : ld d,0 : ld hl,pn_l40 : add hl,de : ld (pn_ent+1),hl
        ld a,OPG0 : ld c,0 : call 3F
        ld a,OPG1 : ld c,4
3       ld b,a : ld a,#7F : sub b : push bc : ld bc,P_W1 : out (c),a : pop bc      ; W1: the picture
        ld a,(pn_bk) : add a,a : inc a : add a,c                                  ; 1 / 3 (+4: 5 / 7)
        ld b,a : ld a,#7F : sub b : SCRV : ld bc,P_W2 : out (c),a                ; W2: the buffer
        ld a,(pn_y0) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l
        add hl,hl : add hl,hl : add hl,de       ; * 40
        ld a,(pn_x0) : ld e,a : ld d,#80 : add hl,de      ; HL = the buffer's (+ #8000)
        ld e,(ix+6) : ld d,(ix+7) : push hl : or a : sbc hl,de : ld de,#4000 : sbc hl,de : pop de   ; the picture's
        ld a,(pn_ny) : ld (pn_k2),a
4       call pn_cp                              ; part 0 / 1 (HL, DE: n bytes on)
        ld bc,(pn_d1) : add hl,bc : ex de,hl : add hl,bc : ex de,hl
        call pn_cp                              ; part 2 / 3
        ld bc,(pn_d2) : add hl,bc : ex de,hl : add hl,bc : ex de,hl
        ld a,(pn_k2) : dec a : ld (pn_k2),a : jr nz,4B
        ret
pn_ent  jp 0
pn_l40
        DUP 40
        ldi
        EDUP
        ret
; state B (the game's windows): EGA lines 0..3 and 196..199 (state A's, not screen 7's) black in both buffers
pn_bclr push bc : push de : push hl
        ld hl,wn_det : call far_m : jr z,0F : jp m,pn_nm        ; a popup over state A (mx.asm): its rows only
        call sy_bp : xor a : ld (pn_bcp),a : pop hl : pop de : pop bc : ret    ; (no black lines)
; state A stays (mx.asm wn_det: no window rows - the aliens' turn's line, LAY_NAME just before): the panels (its name
; bar) drawn now - the game goes on busy, no conversion step soon. Both cursors off (the steps put them on again)
pn_nm   ld a,i : push af : di                           ; (the fight's stack: W0 #3CA0.. - deep calls here)
        call pn2_upd : jr z,1F
        ld a,(bf) : call pn_map : call 3F                       ; (pn_map: W1, W2 only - W3 stays UPG)
        call swaprec : call pn_back : call 3F : call swaprec
        call pn2_show
1       WIN P_W1, PG_ZX+5
        WIN P_W2, PG_ZX+2
        pop af : jp po,2F : ei
2       pop hl : pop de : pop bc : ret
3       ld a,(cs_on) : or a : ret z : xor a : ld (cs_md),a : jp cs_iof   ; (cs_on: cursor.asm clears it)
0       ; (the location's palette stays: screen 7's colours through its slots - wideu.asm xp_rmt)
        call sy_b                               ; (state B's copy grid)
        ld a,(bf) : xor 1 : ld (pn_bcb),a : ld a,1 : ld (pn_bcp),a
pn_bc1  ld a,i : push af                        ; (interrupts as they are: the music - int_f touches W3 only)
        ld (pn_sp),sp : ld sp,#3F60             ; (the game's stack may be in W1)
        ld a,(pn_bcb) : call pn_map : call 1F
        WIN P_W1, PG_ZX+5
        WIN P_W2, PG_ZX+2
        ld sp,(pn_sp)
        pop af : jp po,0F : ei
0       pop hl : pop de : pop bc : ret
pn_sp   dw 0
pn_bcb  db 0                                    ; the buffer cleared
pn_bcp  db 0                                    ; 1: the other one still to be
; state B, a conversion step's end: the other buffer's lines 0..3, 196..199 black too once it is the back one
pn_bc2  ld a,(pn_bcp) : or a : ret z
        ld a,(bf) : xor 1 : ld hl,pn_bcb : cp (hl) : ret z
        ld (hl),a : xor a : ld (pn_bcp),a
        push bc : push de : push hl : ld a,(pn_bcb) : jr pn_bc1
1       ld hl,#4000 : ld b,4 : call pn_cln
        ld hl,#4000+196*40 : ld b,4 : jr pn_cln
        ; B lines from HL (part 0): all 4 parts black
pn_cln  push bc : push hl : ld c,4
21      push hl : ld a,c : dec a : ld e,a : ld d,0 : push hl : ld hl,pn_po : add hl,de : ld a,(hl) : pop hl
        add a,h : ld h,a : ld d,h : ld e,l : inc de : ld (hl),0 : push bc : ld bc,39 : ldir : pop bc : pop hl
        dec c : jr nz,21B
        pop hl : ld de,40 : add hl,de : pop bc : djnz pn_cln
        ret
pn_po   db #00,#40,#20,#60              ; parts 0..3: W1 +0, W2 +0, W1 +#2000, W2 +#2000
; W1, W2: the back buffer
pn_back ld a,(bf) : xor 1
pn_map  push de : ld bc,P_W1 : or a : ld a,#7F-PS1 : ld e,#7F-PS5 : jr z,1F : ld a,#7F-PS3 : ld e,#7F-PS7
1       out (c),a : ld b,H_W2 : out (c),e : pop de : ret
; a colour 0..15 -> the left / right pixel's bits
        ALIGN 32
pn_tl   db #00,#01,#02,#03,#04,#05,#06,#07,#40,#41,#42,#43,#44,#45,#46,#47
pn_tr   db #00,#08,#10,#18,#20,#28,#30,#38,#80,#88,#90,#98,#A0,#A8,#B0,#B8
        include "pn2_tab.inc"
