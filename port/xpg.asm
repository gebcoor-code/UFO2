; ------------------------------------------------------------------ more of the UI's code: page XPG (W3, DISP #C000)
; Called through far_x (W0: HL = the routine; back with W3 = UPG). Only W0's variables and the game's windows
; (W1 = bank 5, W2 = bank 2) are seen from here.
XS_TEST equ 0                           ; 1: the aim's snap tried on our fighters (no red check) - a test build

; ---- the keys move the cursor: the cursor keys (CAPS + 5 left, 6 down, 7 up, 8 right: the ATM's arrows too) and
; Sinclair 2 (6 left, 7 right, 8 down, 9 up, 0 the button). In: E = dx, D = dy (the mouse's); out: the keys' move
; added, A = 1 the key button held. By the frames since the last call (ifr: int_h's count, up to 4); in the same
; frame: none; with interrupts off (no frames counted) as two.
x_kb    ld a,(MUS_TRK) : cp 3 : jr nz,14F : ld a,d : neg : ld d,a             ; (the 3D fight: the mouse's Y inverted)
14      ld a,2 : ld (xk_n),a
        ld a,(ifr) : ld hl,xk_fr : sub (hl) : jr nz,0F
        ld a,i : jp po,1F                       ; (no frame counted, interrupts off - a fight's loop: as two)
        ld a,(xk_fire) : ret
0       cp 5 : jr c,13F : ld a,4
13      ld (xk_n),a : ld a,(ifr) : ld (hl),a ; (the frames since the last look: up to 4)
1       ld bc,#EFFE : in a,(c) : cpl : and #1F : ld l,a ; bits: 4 '6', 3 '7', 2 '8', 1 '9', 0 '0'
        ld b,#FE : in a,(c) : rra : jr c,2F     ; no CAPS: Sinclair 2 as it is (4 left, 3 right, 2 down, 1 up, 0 fire)
        ld h,0
        bit 4,l : jr z,3F : set 2,h             ; 6 down
3       bit 3,l : jr z,4F : set 1,h             ; 7 up
4       bit 2,l : jr z,5F : set 3,h             ; 8 right
5       ld b,#F7 : in a,(c) : bit 4,a : jr nz,6F : set 4,h     ; 5 left
6       ld l,h
2       ld a,l : and 1 : ld (xk_fire),a
        ld a,l : and #1E : jr nz,7F
        ld (xk_acc),a : ld a,(xk_fire) : ret
7       ld a,(xk_n) : ld b,a : ld a,(xk_acc) : add a,b : cp 28 : jr c,8F : ld a,27
8       ld (xk_acc),a
        rrca : rrca : and 7 : inc a : ld c,a            ; the step: 1 .. 7 pixels a frame (faster while held)
        xor a
81      add a,c : djnz 81B : ld c,a                     ; x the frames
        bit 4,l : jr z,9F : ld a,e : sub c : ld e,a
9       bit 3,l : jr z,10F : ld a,e : add a,c : ld e,a
10      bit 2,l : jr z,11F : ld a,d : add a,c : ld d,a
11      bit 1,l : jr z,12F : ld a,d : sub c : ld d,a
12      ld a,(xk_fire) : ret
xk_fr   db 0
; the location's quick keys (ui_mouse_u, state A): 1..4 - the weapon slots, Q / E - the previous / next fighter, W -
; the fire type (aimed / normal), R - one floor / both, T - the lift; a new press (no CAPS) as a click on the game's
; panel cell (GETZON / ACTION): CY, DE = the cell (bxy: the wide fight's BMOV), HL = its place (the game's COORD) for
; this poll (the next one ours again)
x_hot   ld hl,(MO_RT) : ld de,G_BMOVR : or a : sbc hl,de : jr z,0F : or a : ret       ; (not BMOV's poll: none)
0       ld bc,#F7FE : in a,(c) : cpl : and #0F : ld e,a         ; 1..4: bits 0..3
        ld b,#FB : in a,(c) : cpl : and #1F : ld d,a            ; Q W E R T: bits 0..4
        ld hl,HK_L1 : ld a,(hl) : ld (hl),0 : or e : ld e,a : ld hl,HK_L2 : ld a,(hl) : ld (hl),0 : or d : ld d,a
        ld b,#FE : in a,(c) : rra : jr c,1F : ld de,0           ; (CAPS: none; HK_L: latched meanwhile - wideu.asm)
1       ld hl,(xh_old) : ld (xh_old),de
        ld a,l : cpl : and e : ld e,a : ld a,h : cpl : and d : ld d,a : or e : ret z    ; (NC)
        ld hl,xh_t-2 : ld a,e : or a : jr nz,2F : ld hl,xh_t+6 : ld a,d
2       inc hl : inc hl : rrca : jr nc,2B
        ld e,(hl) : inc hl : ld d,(hl)
        ld a,e : or a : jr nz,3F                                ; W: the other fire type's button
        ld de,#1C05 : ld a,(G_FIRTYP) : or a : jr z,3F : ld e,8
3       ld a,e : add a,a : add a,a : add a,a : add a,4 : ld l,a
        ld a,d : add a,a : add a,a : add a,a : add a,4 : ld h,a : scf : ret
xh_old  dw 0
xh_t    db 14,29, 18,29, 22,29, 26,29                           ; (x, y cells; the panel's rows from l_PROW = 26:
        db 11,26, 0,0, 8,26, 2,26, 5,26                         ; build/wide.py) Q P_MAN, W, E N_MAN, R N_FLR, T LIFT
xk_fire db 0
xk_acc  db 0
xk_n    db 0

; ---- the 3D fight starts (ALEX, zx_alexq): int_f, its music, interrupts on (E_I's and DELAY's DI off)
x_m3d   ld hl,int_f : ld (#3D3E),hl : ld a,3 : ld (MUS_TRK),a
        xor a : ld (G_EIDI),a : ld (G_DLDI),a : ei : ret

; ---- the 3D fight (MUS_TRK 3): its controls as the game's joystick (CONTRB: 0 right, 1 left, 2 down, 3 up, 4 fire;
; the game reads only its keys / Kempston, both off here). E = dx, D = dy (the mouse, the arrows / Sinclair through
; x_kb) gathered (up to 24 pixels), X3S of them spent a call while a direction is held; Q A O P, space as the game's
; own keys. Out: A = the bits.
X3S     equ 3
x_3d    ld a,(ifr) : ld hl,x3_f : cp (hl) : jr z,1F                       ; the mouse moves the stick only while the
        ld (hl),a : ld a,(x3_c) : cp 5 : jr nc,2F : xor a : ld (x3_s),a  ; 3D view runs: the game asks a few times a
2       xor a : ld (x3_c),a                                             ; frame then; in its waits (TMOF: "the
1       ld hl,x3_c : inc (hl) : jr nz,3F : dec (hl)                     ; interceptor damaged...") many times - the
3       ld a,(hl) : cp 17 : jr c,4F : ld a,1 : ld (x3_s),a              ; slightest move would end the wait
4       ld a,(x3_s) : or a : jr z,5F : ld de,0
5       ld a,(x3_x) : call x3_add : call x3_use : ld (x3_x),a : ld l,b
        ld e,d : ld a,(x3_y) : call x3_add : call x3_use : ld (x3_y),a
        ld a,b : add a,a : add a,a : cp 4 : jr nz,6F : ld a,8 : jr 7F     ; (as a mouse look: down -> the stick
6       cp 8 : jr nz,7F : ld a,4                                        ; forward, bit 3; up -> back, bit 2)
7       or l : ld l,a
        ld bc,#DFFE : in a,(c) : cpl : and 3 : or l : ld l,a     ; P right, O left
        ld b,#FD : in a,(c) : rra : jr c,3F : set 2,l           ; A down
3       ld b,#FB : in a,(c) : rra : jr c,4F : set 3,l           ; Q up
4       ld b,#7F : in a,(c) : rra : jr c,5F : set 4,l           ; space: fire
5       ld a,(x3_s) : rra : ld a,l : ret                                ; (CY: the game waits)
; A = the sum, E = a move (signed) -> A = the new sum, -24..24
x3_add  add a,e : jp pe,2F
        bit 7,a : jr nz,1F
        cp 25 : ret c : ld a,24 : ret
1       cp -24 : ret nc : ld a,-24 : ret
2       bit 7,e : ld a,24 : ret z : ld a,-24 : ret
; A = the sum -> B: 0 none, 1 +, 2 -; A = the sum less X3S
x3_use  ld b,0 : or a : ret z
        jp m,1F
        ld b,1 : sub X3S : ret nc : xor a : ret
1       ld b,2 : add a,X3S : ret nc : xor a : ret
x3_x    db 0
x3_f    db 0
x3_c    db 0
x3_s    db 0                                    ; 1: the game waits (no mouse moves)
x3_y    db 0

; ---- the aim (the wide fight, state A, after pn_bxy): the crosshair / the blade's point within an alien's figure
; (its box, 2 pixels around) -> the game's cell is that alien's own (as the old cell cursor standing on him): bxy
x_snap
        IF XS_TEST == 0
        ld a,(cs_mode) : and 3 : cp 1 : jr z,0F : cp 3 : ret nz
        ENDIF
0       ld a,(pn_ovr) : or a : ret nz
        ld a,(bxy) : or a : ret z : cp 38 : ret nc
        ld a,(bxy+1) : or a : ret z : cp 20 : ret nc
        ; the aliens: the one whose figure (the game's 3D cursor's box there: 16 x 32) is around the point; of
        ; several, the front one (the larger half-row)
        ld a,(G_SH) : or a : ld a,0 : jr nz,1F : inc a
1       ld (xs_s),a
        ld a,#FF : ld (xs_bd),a
        IF XS_TEST >= 1
        ld ix,G_MAN : ld b,10
        ELSE
        ld ix,G_MAN+320 : ld b,22
        ENDIF
2       push bc
        ld a,(ix+8) : or a : jp z,.nx           ; (as HERLIV)
        ld a,(ix+13) : or a : jp z,.nx
        cp (ix+26) : jp c,.nx
        ld a,(G_FLR) : or a : jr z,3F : cp (ix+2) : jp nz,.nx
3       ; as INFR: l = x - X0, h = y - Y0, E = l + h (half-row), D = l - h + s (column; = BX - 1 for BOUT)
        ld a,(G_X0) : ld c,a : ld a,(ix+0) : sub c : ld l,a
        ld a,(G_X0+1) : ld c,a : ld a,(ix+1) : sub c : ld h,a
        add a,l : cp 45 : jp nc,.nx : ld e,a
        ld a,(xs_s) : add a,l : sub h : cp 37 : jp nc,.nx : ld d,a
        ; the box: x (D - 1) * 8 .. +15, y 4E - 28 .. +31 (BDSC's line 4E + 4, byte D + 1), 2 pixels more around
        push hl
        ld l,d : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld b,h : ld c,l
        ld hl,(scx) : ld a,10 : add a,l : ld l,a : jr nc,4F : inc h
4       or a : sbc hl,bc                        ; scx + 10 - 8D = dx + 2
        ld a,h : or a : jr nz,5F : ld a,l : cp 20
5       pop hl : jp nc,.nx
        ld a,e : add a,a : add a,a : ld c,a
        ld a,(scy) : add a,30 : sub c : jp c,.nx : cp 36 : jp nc,.nx
        ld a,(xs_bd) : inc a : jr z,6F : dec a : cp e : jp nc,.nx    ; (the front one)
6       ld a,e : ld (xs_bd),a
        ; BOUT's cell: BX = D + 1, BY = h - s + D / 2 + 1
        ld a,d : inc a : ld (xs_bx),a
        ld a,d : srl a : add a,h : ld c,a : ld a,(xs_s) : neg : add a,c : cp 19 : jr c,7F
        ld a,#FF : ld (xs_bd),a : jp .nx        ; (outside the rows BOUT takes)
7       inc a : ld (xs_bx+1),a
.nx     ld de,32 : add ix,de
        pop bc : dec b : jp nz,2B
        ld a,(xs_bd) : inc a : ret z
        ld hl,(xs_bx) : ld (bxy),hl : ret
xs_s    db 0
xs_bd   db 0
xs_bx   dw 0

; ---- LOC GO with nobody aboard: 4 aquanauts with guns (the game's windows)
crew_set
        xor a : ld (G_AQNAVT+16*4),a            ; (the list ends with name 0)
        ld a,4 : ld (G_AQU),a
        ld de,G_AQNAVT : ld c,1
2       ld hl,crew : ld b,16
3       ld a,(hl) : ld (de),a : inc hl : inc de : djnz 3B
        ld hl,-16 : add hl,de : ld a,c : cp 3 : jr nc,6F : xor 3   ; name (1, 2 swapped: the 2nd name first)
6       ld (hl),a
        inc c : ld a,c : cp 5 : jr c,2B
        ret
crew    db 0,0,0,50,50,50,0,50,50,9,2,10,13,0,0,0     ; name, rank, armour, TU, energy, health, wound, moral, precision, guns x4

        IFDEF SRCB
; ---- "the lazy mode" (LAZY; the game's windows): everything researched, money, stores full, the best fighter,
; 10 strong aquanauts
lazy    ld hl,G_RS : ld b,80 : xor a
1       ld (hl),a : inc hl : djnz 1B            ; research: all done (0)
        ld a,80-#1F : ld (G_RNUM),a             ; (the game's own count check: RESNUM)
        ld hl,38527 : ld (G_MONEY),hl : ld hl,152 : ld (G_MONEY+2),hl   ; 9 999 999 $
        ld hl,G_SGUN : ld b,(G_SDUM-G_SGUN)/2   ; stores: weapons, equipment, armour - 99 each
2       ld (hl),99 : inc hl : ld (hl),0 : inc hl : djnz 2B
        ld hl,G_SDUM+2 : ld b,(G_STMP-G_SDUM-2)/2   ; UFO types, artefacts, aliens - 10 each
3       ld (hl),10 : inc hl : ld (hl),0 : inc hl : djnz 3B
        ld a,50 : ld (G_RSN),a : ld (G_RSN+1),a ; scientists, engineers
        ld a,2 : ld (G_TINTR),a                 ; the best fighter
        ld a,10 : ld (G_AQU),a
        ld de,G_AQNAVT : ld c,1
4       ld hl,lz_crew : ld b,16
5       ld a,(hl) : ld (de),a : inc hl : inc de : djnz 5B
        ld hl,-16 : add hl,de : ld a,c : cp 3 : jr nc,6F : xor 3   ; name (1, 2 swapped: the 2nd name first)
6       ld (hl),a
        inc c : ld a,c : cp 11 : jr c,4B
        ret
lz_crew db 0,7,3,80,80,80,0,100,100,9,2,10,6,0,0,0      ; name, rank, armour, TU, energy, health, wound, moral, precision, guns x4 (6: the cutter)
        ENDIF

; ---- the fight's SAVE / LOAD with the disk (lay_dsk -> u_dsk; A = 0 save, 1 load; the game's windows): in a wide
; fight window 0's overlay is covered by BDSC: that part of BDSC kept in OVPG #3000 meanwhile, the overlay brought in
; (dk_op: UFO2.BTL through CP/M); after a load the object planes emptied (as at a fight's start: the game redraws all)
x_dsk   ld (xd_a),a
        ld a,i : push af : di
        ld bc,#FFFD : ld a,7 : out (c),a : ld b,#BF : ld a,#3F : out (c),a      ; the music quiet (no note held
        ld a,15 : ld (FADE),a                                                   ; while the disk works; faded in after)
        ld a,(bwide) : ld (xd_w),a : or a : jr z,1F
        WIN P_W1, OVPG
        ld hl,ovl_start : ld de,#7000 : ld bc,ovl_end-ovl_start : ldir
        ld hl,#4000 : ld de,ovl_start : ld bc,ovl_end-ovl_start : ldir
        WIN P_W1, PG_ZX+5
1       ld a,(xd_a) : call dk_op : ld (xd_ok),a
        di
        ld a,(xd_w) : or a : jp z,2F
        WIN P_W1, OVPG
        ld hl,#7000 : ld de,ovl_start : ld bc,ovl_end-ovl_start : ldir
        ld a,(xd_a) : ld hl,xd_ok : and (hl) : jr z,3F
        ld a,1 : ld (fs_all),a                  ; loaded: the field all converted again (bytes equal to the old
        WIN P_W1, MPG                          ; fight's kept its colours), the object planes empty
        ld hl,OB_Z0-#8000 : ld de,OB_Z0-#8000+1 : ld bc,OB_Z1-OB_Z0-1 : ld (hl),0 : ldir
        XS_CLR
        WIN P_W1, PG_ZX+5                      ; (an older save's code: BATRET's CALL MEM7 -> CALL LAY_GEO, as now)
        ld hl,G_BATRET+22 : ld a,(hl) : cp #CD : jr nz,4F : inc hl : ld (hl),#15 : inc hl : ld (hl),#01
4       ld a,(G_MS20) : cp #1A : jr z,3F        ; a save before v75 (its sprites with SP): interrupts off in this fight
        ld hl,int_h : ld (#3D3E),hl : ld a,4 : ld (MUS_TRK),a   ; (no music: int_h, the DIs back)
        ld a,#F3 : ld (G_EIDI),a : ld (G_DLDI),a
        ld bc,#FFFD : ld a,7 : out (c),a : ld b,#BF : ld a,#3F : out (c),a
        pop af : ret
3       WIN P_W1, PG_ZX+5
2       pop af : jp pe,9F                       ; (called with DI - the game's disk code does that - in a fight
        push af : ld a,(#3D3F) : or a : jr nz,8F        ; with int_f: interrupts on anyway, else the music stood
        ld a,(#3D3E) : cp low int_f : jr nz,8F          ; till the next DELAY; AF as it was)
        pop af : ei : ret
8       pop af : ret
9       ei : ret
        ASSERT ovl_end-ovl_start <= #1000
xd_a    db 0
xd_w    db 0
xd_ok   db 0
; the exit's line (zx_exit copies it into SHP, free by then: CP/M prints it from window 0)
m_back  db 27,"Z1",27,"M1",13,10,"UFO2 CPM port by ae485 (ai support). Oct 2026.",13,10,"$"
m_back_n equ $-m_back
; ---- the coloured location (xtil.asm's plane): row A's marked groups (E) and lines (D) - the field's marks: what the
; game and our planes' work touched there - copied from the plane into the back buffer, but the panels' columns. Per
; line: W1 = PLA, W2 = the back buffer's first page (parts 0, 2), then PLB and the second (1, 3); the same offsets (W1
; #4000 + o, W2 #8000 + o). The columns to copy as runs (pp_rn: made again when the groups or the panels change). W1,
; W2 = the back after.
pl_post ld (pp_r),a
        ld a,(PL_USE) : or a : ret z
        ld a,e : and #1F : ret z : ld (pp_g),a
        ld a,d : or a : ret z : ld (pp_l),a
        ld a,(pp_r) : add a,a : add a,a : add a,a : ld (pp_y),a
        push ix : ld b,8
1       push bc
        ld hl,pp_l : rrc (hl) : call c,pp_line
        ld hl,pp_y : inc (hl)
        pop bc : djnz 1B
        pop ix : jp pp_back
; (wideu.asm lay_prog_u: the progress bar gone from both buffers, A = its first line, E = its first pair) the
; field's two rows' groups there: from the plane into both buffers now - the game may draw nothing for long (a fight's
; start); without the plane: marked
pl_now  push af : ld a,e : rlca : rlca : rlca : and 7 : ld b,a : ld a,3 : jr z,5F       ; (32 pairs: two groups)
6       add a,a : djnz 6B
5       and #1F : ld (pn_g),a : pop af
        rrca : rrca : rrca : and #1F : ld c,a : ld b,2
1       ld a,c : cp FDN : ret nc
        push bc
        ld a,(PL_USE) : or a : jr nz,2F
        ld hl,fs_row : ld e,c : ld d,0 : add hl,de : ld (hl),#FF
        ld hl,fe_row : add hl,de : ld (hl),#1F : ld de,FDN : add hl,de : ld (hl),#FF
        jr 3F
2       ld a,c : ld (pn_r),a : ld a,(bf) : push af
        xor a : call 4F : ld a,1 : call 4F
        pop af : ld (bf),a
3       pop bc : inc c : djnz 1B
        ret
4       ld (bf),a : ld a,(pn_g) : ld e,a : ld d,#FF : ld a,(pn_r) : jp pl_post
pn_g    db 0
pn_r    db 0
; the back buffer in W1, W2 again (map_back's, without its W3 = bank 7: this code is in W3)
pp_back ld a,(bf) : or a : jr nz,1F
        WIN P_W1, PS3
        WIN P_W2, PS7
        ret
1       WIN P_W1, PS1
        WIN P_W2, PS5
        ret
; pp_m's columns C .. B - 1: #FF
pp_pan  ld a,b : sub c : ld b,a : ld hl,pp_m : ld a,l : add a,c : ld l,a : jr nc,1F : inc h
1       ld (hl),#FF : inc hl : djnz 1B
        ret
; line pp_y
pp_line ld c,0 : ld a,(pp_y) : cp 8 : jr nc,1F : inc c     ; the panels on this line (C: top, bottom, side)
1       cp 160 : jr c,2F : ld a,(pvw) : rrca : jr nc,2F : set 1,c
2       ld a,(pp_y) : cp 18 : jr c,3F : cp 181 : jr nc,3F : ld a,(pvw) : and 2 : jr z,3F : set 2,c
3       ld a,(pp_g) : ld b,a : ld a,(pp_gk) : cp b : jr nz,4F
        ld a,(pp_kk) : cp c : jr z,5F                           ; (as the last line's: pp_rn as it is)
4       ld a,c : ld (pp_kk),a : ld a,b : ld (pp_gk),a
        ld hl,pp_m : ld de,pp_m+1 : ld bc,39 : ld (hl),0 : ldir
        ; the panels' columns [from, to) (the bottom one and the side one may share lines), the groups not marked
        ld a,(pp_kk) : rrca : push af : ld bc,30*256+10 : call c,pp_pan
        pop af : rrca : push af : ld bc,32*256+8 : call c,pp_pan
        pop af : rrca : ld bc,40*256+37 : call c,pp_pan
        ld a,(pp_gk) : ld e,a : ld c,0
41      ld a,c : add a,8 : ld b,a : rrc e : call nc,pp_pan
        ld a,c : add a,8 : ld c,a : cp 40 : jr c,41B
        ; the runs: (length, the first column) .., 0
        ld hl,pp_m : ld de,pp_rn : ld c,0
42      ld a,c : cp 40 : jr nc,45F
        ld a,(hl) : or a : jr z,43F : inc hl : inc c : jr 42B
43      ld b,c                                                  ; (a run from C)
44      inc hl : inc c : ld a,c : cp 40 : jr nc,46F : ld a,(hl) : or a : jr z,44B
46      ld a,c : sub b : ld (de),a : inc de : ld a,b : ld (de),a : inc de : jr 42B
45      xor a : ld (de),a
5       ; o = y * 40
        ld a,(pp_y) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l
        add hl,hl : add hl,hl : add hl,de : ld (pp_o),hl
        ; parts 0, 2: W1 = PLA, W2 = the back's first page
        WIN P_W1, PLA
        ld a,(bf) : or a : ld a,#7F-PS7 : jr z,6F : ld a,#7F-PS5    ; (the back: 3, 7 or 1, 5)
6       ld (pp_b2),a : add a,4 : ld bc,P_W2 : out (c),a        ; (#7F-3 / #7F-1)
        call pp_runs
        WIN P_W1, PLB
        ld a,(pp_b2) : ld bc,P_W2 : out (c),a
; the runs of the line: parts p, p + 2 (the plane at W1 #4000 + o, the back at W2 #8000 + o; p + 2 at +#2000)
pp_runs ld ix,pp_rn
1       ld a,(ix+0) : or a : ret z
        add a,a : ld c,a : ld b,0 : ld hl,pp_le : sbc hl,bc : ld (pp_jp+1),hl  ; (CY = 0: OR A)
        ld a,(ix+1) : ld hl,(pp_o) : add a,l : ld l,a : jr nc,$+3 : inc h
        ld d,h : ld e,l : set 6,h : set 7,d                     ; (HL the plane, DE the back)
        push hl : push de : call pp_jp : pop de : pop hl
        set 5,h : set 5,d : call pp_jp
        inc ix : inc ix : jr 1B
pp_jp   jp 0
        DUP 40
        ldi
        EDUP
pp_le   ret
pp_o    dw 0
pp_r    db 0
pp_g    db 0
pp_gk   db #FF
pp_kk   db #FF
pp_l    db 0
pp_y    db 0
pp_b2   db 0
pp_m    ds 40
pp_rn   ds 2*20+1
; debug LOC GO: the locations in turn, each LOC GO the next (dbg_n -> dbg_tb: L_LAND - the sea floor, ship I, the
; port (both: the city's, the other), the island, our base, colony I, base I, Tleth, colony II, base II, ship II; other
; variants at random), the target type (2 - a port's aliens - past 6); at the fight's start (bat_on -> dbg_bat; BDSC
; just cleared, nothing drawn till the location's generated) the patch table (zxl.asm ptab) copied into BDSC's tail
; with L_Land's LD A,(L_LAND) -> LD A,n (and the port's choice: JR C -> none / JR) when their modules unpack; the
; first sprite drawn (obj.asm ob_spr) puts ptab back
dbg_loc ld a,(dbg_fx) : or a : ld a,(dbg_n) : jr nz,1F                    ; ("UFO2 DEBUG Xnn": always nn)
        inc a : cp 12 : jr c,1F : xor a
1       ld (dbg_n),a : ld l,a : add a,a : add a,l : ld hl,dbg_tb+1 : add a,l : ld l,a : jr nc,$+3 : inc h
        ld a,(hl) : ld (G_TTYPE),a : ld a,1 : ld (dbg_lc),a
        ld a,(G_PERIOD) : cp 2 : ret nc : ld a,2 : ld (G_PERIOD),a : ret     ; (colony I, base I, Tleth: before period 2 the
                                                                            ; game shows its demo's end there - PERgt1)
dbg_bat ld a,(dbg_lc) : or a : ret z : xor a : ld (dbg_lc),a
        ld a,(dbg_n) : ld l,a : add a,a : add a,l : ld hl,dbg_tb : add a,l : ld l,a : jr nc,$+3 : inc h
        ld a,(hl) : ld (dl_ln+8),a : inc hl : inc hl : ld a,(hl) : push af
        ld hl,ptab : ld de,DBG_PT : ld bc,ptab_e-ptab-1 : ldir
        ld hl,dl_ln : ld bc,dl_lne-dl_ln : ldir
        pop af : or a : jr z,2F
        ld hl,#0000 : dec a : jr z,1F : ld hl,#0518             ; (none / JR)
1       ld (dl_ll2+12),hl : ld hl,dl_ll2 : ld bc,dl_ll2e-dl_ll2 : ldir
2       xor a : ld (de),a
        ld hl,DBG_PT : ld (ptab_p),hl : ret
DBG_PT  equ BDSC+BLINES*BW-80
        ASSERT ptab_e-ptab-1 + dl_lne-dl_ln + dl_ll2e-dl_ll2 + 1 <= 80
dbg_lc  db 0
dbg_n   db #FF                                  ; (the first LOC GO: 0)
dbg_fx  db 0                                    ; 1: dbg_n fixed (title.asm a_dbg)
dbg_tb  db 0,0,0, 1,1,0, 2,2,1, 2,2,2, 3,3,0, 4,4,0, 5,5,0, 6,6,0, 7,2,0, 8,2,0, 9,2,0, 10,2,0   ; L_LAND, T_TYPE, port's
dl_ln   db 6, #3A, low G_LLAND, high G_LLAND, #21, low G_LLL, high G_LLL
        db #3E, 0, 0, #21, low G_LLL, high G_LLL                 ; (+8: n)
dl_lne
dl_ll2  db 8, #0F,#3E,#10,#38,#05,#21,#2C,#0A : db #0F,#3E,#10,0,0,#21,#2C,#0A    ; (+12: JR C's bytes)
dl_ll2e
TE_X    equ #FC00                       ; (XPG's code up to ommap.asm: UFO2.TIL's index was at #E000.. - TIPG now)
te_t    equ BDSC+236*BW                 ; (128) the tile (ZX) - in BDSC's bottom margin: not drawn there now, nor
te_o    equ te_t+128                    ; (256) its EGA lines   - by the game (obj.asm ob_nd); the patch table past it
        ASSERT te_o+256 <= DBG_PT
        ASSERT $ <= TE_X
        include "enc.asm"
        include "ico.asm"
        include "text.asm"
        ASSERT $ <= TE_X
