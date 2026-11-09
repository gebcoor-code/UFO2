; ---- the items' and the signs' pictures in EGA (XPG; UFO2.ICO - build/mkico.py - in page ICPG from ICO_A, xtil.asm
; ico_load). The game draws them onto screen 7 (bank 3's pictures): PUTSIM xWBUTT (an item's button, 4 x 3 characters)
; and xSIGN + 72 k (the ranks 0..7, the armours 8..11: 3 x 3), PUTSCR xWEAPO + 64 g (item g, 32 x 16, into its button:
; 4 lines down). The mark vectors (mku.asm's dispatch -> ui5's ov_sim3 / ov_psc3) report them here: ov_sim / ov_psc
; keep each as an overlay (the place, the picture, screen 7's sum there). Every conversion step (pn_fl -> ui3's
; ov_fl3 -> ov_fl), state B: an overlay whose groups the step changed in the back buffer (bsync) is drawn there again
; - if screen 7 there is what the game drew (the sum: drawn onto screen 7 or into its DSCR, copied later); forgotten
; when not so any more once seen.
; UFO2.ICO: "IC", the buttons 0..15 (15: empty; 32 x 24: 24 lines x the 4 parts' 4 bytes), the signs 0..11 (24 x
; 24: 24 lines x 4 x 3 bytes), the parameters' 6 signs (xPARAM: 24 x 96, PUTSIM 3 x 12; id 28) - EGA bytes as the
; buffers have them.
ICPG    equ 19                                  ; (the panels' atlas' second page: its first #0800 bytes)
ICO_A   equ #0800
OV_N    equ 24
OV_NB   equ 14                                  ; the buttons (build/mkico.py NBT)
; (from ov_sim3 / ov_psc3: far_x - the stack: far_x's return, ov_*3's, the game's HL; all but HL kept)
ov_sim  push af : push bc : push de : call 0F : pop de : pop bc : pop af : ret
ov_psc  push af : push bc : push de : call ov_p0 : pop de : pop bc : pop af : ret
0       ld a,(ico_ok) : or a : ret z
        ld a,(G_SCOSCR+1) : call ov_bas : ret nz
        call ov_hl
        ld a,d : cp #C0 : jr nz,0F : ld a,e : or a : jr nz,0F : ld a,l : or h : jr nz,0F   ; the world map (xEARTH
        ld a,b : cp 24 : ret nz : ld a,c : cp 15 : ret nz                   ; at 0, 0: 24 x 15)
        ld a,(ico_map) : or a : ret z : ld (ov_mu),a : ld (ov_bu),a
        ld hl,ov_tab : ld b,8 * OV_N                                        ; (a new geoscape: the others gone)
1       ld (hl),0 : inc hl : djnz 1B
        ld a,29 : ld (ov_id),a : ld bc,#1878 : jp ov_reg
0       ld a,b : cp 12 : jr nz,0F : ld a,c : cp 2 : ret nz                  ; the buy / sell / hire windows' 4
        ld a,d : cp high #D7E0 : ret nz : ld a,e : cp low #D7E0 : ret nz    ; buttons (xPLUS, 12 x 2: xlix.asm
        ld a,44 : ld (ov_id),a : ld a,h : add a,a : add a,a : add a,a : ld h,a : ld bc,#0C10 : jp ov_reg   ; INIPM)
0       ld a,d : cp high #D3C0 : jr nz,0F : ld a,e : cp low #D3C0 : jr nz,0F  ; the parameters' signs (3 x 12)
        ld a,b : cp 3 : ret nz : ld a,c : cp 12 : ld a,28 : jp z,3F
        ld a,c : cp 2 : ret nz : ld a,45 : jr 01F                                   ; (3 x 2: the time's alone - id 45)
0       ld a,d : cp high #D480 : jr nz,0F : ld a,e : cp low #D480 : jr nz,0F  ; the encyclopedia's weapon (UPARAM: signs
        ld a,b : cp 3 : ret nz : ld a,c : cp 12 : ret nz                    ;  4..9 of xPARAM, 3 x 12): each its own
        ld a,49                                                             ;  overlay (ids 49..54 - the time's over 4)
02      push af : push hl : push de : call 01F : pop de : pop hl : pop af
        inc h : inc h : ld bc,48 : ex de,hl : add hl,bc : ex de,hl : inc a : cp 55 : jr c,02B
        ret
01      ld (ov_id),a : ld a,h : add a,a : add a,a : add a,a : ld h,a : ld bc,#0310 : jp ov_reg
0       ld a,b : cp 4 : jr nz,1F : ld a,c : cp 3 : ret nz
        ld a,d : cp high #CF80 : ret nz : ld a,e : cp low #CF80 : ret nz
        ld a,15 : jp 3F
1       cp 2 : jp nz,11F : ld a,c : cp 2 : ret nz                         ; a button's label (xLABEL + 32 k, 2 x 2): the
        ld a,(ico_map) : or a : ret z                                       ; geoscape's k 4..13 (MENU: at 5, 25), the
        push hl : ld hl,-#D8A0 : add hl,de : ld a,h : cp 4 : jp nc,8F : ld a,l : and 31 : jp nz,8F   ; encyclopedia's
        add hl,hl : add hl,hl : add hl,hl : ld a,h : cp 24 : jr nz,17F : pop hl ; 0..4 (column 29; xlix.asm DTBAR),
        ld a,l : cp 29 : ret nz : ld a,h : cp 9 : ret nz : ld a,36 : jr 12F ; the fighter's screen's k 24 at row 9
17      cp 23 : jp nc,8F : pop hl                                           ;  (xlie.asm: id 66 - BUTTONS2's 12th; the
                                                                            ;  encyclopedia's k 24 elsewhere - not it)
        cp 13 : jr c,14F : jr nz,15F                                        ; (the target menu - xlic.asm TARBUT: k 13
        ld c,a : ld a,l : cp 25 : ld a,c : jr nz,14F                        ;  at column 25, 14 back, 15..22 the
15      sub 13 : ld c,a : cp 2 : jr c,16F                                   ;  targets: ids 55..64; a target not there -
        push hl : ld hl,G_TUFO-2 : ld b,0 : add hl,bc : ld a,(hl) : pop hl  ;  T_UFO.. #FF, its label cleared - 65:
        inc a : ld a,c : jr nz,16F : ld a,10                                ;  the empty button)
16      add a,25 : jr 12F
14      sub 4 : jr z,13F : jr nc,12F : add a,14                             ; (buttons 0..9: k 4..13, 10..13: k 0..3)
13      ld c,a : ld a,l : cp 29 : ld a,c : jr z,12F : or a : ret nz
        ld a,h : cp 5 : ret nz : ld a,l : cp 25 : ret nz : xor a
12      add a,30 : ld (ov_id),a                                             ; (id 30..39: its button, 4 x 4 from
        dec h : dec l : ld a,h : add a,a : add a,a : add a,a : ld h,a : ld bc,#0420 : jp ov_rg1   ; row - 1, col - 1)
11      cp 3 : ret nz : ld a,c : cp 3 : ret nz
        push hl : ld hl,-#D060 : add hl,de : jr nc,8F                        ; (below the signs)
        ld a,-1
2       inc a : ld bc,-72 : add hl,bc : jr c,2B                             ; k = (DE - xSIGN) / 72
        ld bc,72 : add hl,bc : ld b,a : ld a,h : or l : jr nz,8F : ld a,b
        cp 12 : jr nc,8F : add a,16 : pop hl
3       ld (ov_id),a : ld a,h : add a,a : add a,a : add a,a : ld h,a       ; py = row * 8
        ld a,(ov_id) : cp 15 : ld bc,#0418 : jr z,ov_reg : cp 28 : ld bc,#0360 : jr z,ov_reg : ld bc,#0318 : jr ov_reg
8       pop hl : ret
ov_p0   ld a,(ico_ok) : or a : ret z
        ld a,(G_BCOSCR+1) : call ov_bas : ret nz
        call ov_hl
        ld a,b : cp 4 : ret nz : ld a,c : cp 16 : ret nz
        ld a,h : sub 4 : ret c : ld h,a                                     ; (the button: 4 lines up)
        push hl : ld hl,-#CB40 : add hl,de : jr nc,8B
        ld a,l : and 63 : jr nz,8B
        add hl,hl : add hl,hl : ld a,h : cp 15 : jr nc,8B                   ; g = (DE - xWEAPO) / 64
        pop hl : ld (ov_id),a : ld bc,#0418
; HL = (py, cx), BC = (w, h), (ov_id): an overlay there, waiting (the old one at that place replaced; no room:
; the next one in turn)
ov_reg  ld (ov_de),de
        ld a,(infight) : or a : jr z,1F
        ld a,h : add a,c : cp 161 : ret nc                              ; (below line 160: the fight's panel)
1
        ld a,(ov_bh) : cp #90 : jr nz,ov_rg1 : ld a,#FF : ld (BC_CMP),a      ; (into the DSCR above the panel: the
ov_rg1                                                                      ; fighter's screen - tpg.asm bc_t keeps none)
        ld a,(ov_sx) : add a,l : ld l,a
        push ix : push iy : call 0F : pop iy : pop ix : ret
0       ld ix,ov_tab : ld de,8 : push bc : ld b,OV_N : ld c,0
1       ld a,(ix+0) : or a : jr nz,2F : ld a,c : or a : jr nz,4F : push ix : pop iy : inc c : jr 4F
2       ld a,(ix+7) : inc a : jr nz,21F : ld a,c : or a : jr nz,21F         ; (a covered one: its place free too)
        push ix : pop iy : inc c
21      ld a,(ix+1) : cp l : jr nz,4F : ld a,(ix+2) : cp h : jr nz,4F
        push ix : pop iy : ld c,2 : jr 5F                                    ; (the same place)
4       add ix,de : djnz 1B
5       ld a,c : pop bc : or a : jr nz,6F
        ld a,(ov_rr) : inc a : cp OV_N : jr c,51F : xor a                   ; (no room)
51      ld (ov_rr),a : add a,a : add a,a : add a,a : ld e,a : ld d,0 : ld iy,ov_tab : add iy,de
6       ld a,(ov_id) : inc a : ld (iy+0),a : ld (iy+1),l : ld (iy+2),h : ld (iy+3),b : ld (iy+4),c
        ld (iy+7),0 : ld a,(ov_id) : cp 29 : jr nz,0F : ld (iy+7),#80 : ret   ; (the map: merged, no sum)
0       cp 16 : jr c,64F : cp 55 : jr nc,8F : cp 45 : jr nc,7F : cp 30 : jr nc,8F : jr 7F    ; (A: the id)
64      call ov_sum : jr 8F
7       push af : WIN P_W2, PG_ZX+3 : pop af                               ; a sign: its picture's sum (bank 3 in W2;
        ld bc,48 : cp 45 : jr nc,70F                                        ; the game draws it over a filled square)
        ld bc,72 : cp 28 : jr nz,70F : ld bc,288
70      ld hl,(ov_de) : res 6,h : ld de,0
71      push bc : ex de,hl : add hl,hl : jr nc,72F : inc l
72      ld a,(de) : add a,l : ld l,a : jr nc,73F : inc h
73      ex de,hl : inc hl : pop bc : dec bc : ld a,b : or c : jr nz,71B
        WIN P_W2, PG_ZX+2
8       ld (iy+5),e : ld (iy+6),d
        ld a,(ov_id) : cp 30 : ret c : cp 45 : jr c,81F : cp 55 : ret c     ; (the buttons: no ageing; the sum: at
81      ld (iy+7),#C0 : ret
                                                                            ; the first conversion - its DSCR copied)
; (the place on screen 7: cx, the picture's own: cx - (ov_sx))
; the game's picture base (SCOORD's / BCOORD's high byte): screen 7 (#C0: summed in it, W2 = it meanwhile) or the
; game's DSCR (#90: W2's own; copied onto screen 7 later) -> Z, (ov_bh) = its high byte as summed; else NZ
ov_bas  ld (ov_sx),a : cp #90 : jr z,1F : cp #C0 : ret nz : ld a,#80
1       ld (ov_bh),a : xor a : ld (ov_sx),a : ret                           ; (Z; DSCR: copied as it is)
; the game's HL (from the stack: ov_hl's return, ov_s / ov_p0's, AF BC DE, far_x's, ov_*3's) -> HL
ov_hl   ld hl,14 : add hl,sp : ld a,(hl) : inc hl : ld h,(hl) : ld l,a : ret
; IY = an overlay -> DE = the sum there of (ov_bh): #80 - screen 7 (W2 = it meanwhile), #90 - the game's DSCR
ov_sum  ld a,(ov_bh) : cp #80 : jr nz,0F
        WIN P_W2, PG_ZX+7
0       ld de,0 : ld c,(iy+4) : ld h,(iy+2)                                 ; C lines from py
1       push hl : push bc
        ld a,h : rrca : rrca : rrca : and #18 : ld b,a : ld a,h : and 7 : or b : ld b,a
        ld a,(ov_bh) : or b : ld b,a
        ld a,(ov_sx) : neg : add a,(iy+1) : ld l,a
        ld a,h : rlca : rlca : and #E0 : or l : ld l,a : ld h,b
        ld b,(iy+3)
2       ex de,hl : add hl,hl : jr nc,3F : inc l
3       ld a,(de) : add a,l : ld l,a : jr nc,4F : inc h
4       ex de,hl : inc l : djnz 2B
        pop bc : pop hl : inc h : dec c : jr nz,1B
        WIN P_W2, PG_ZX+2
        ret
; a conversion step's end (far_x from ov_fl3): the overlays the back buffer changed under drawn again -> A = 0;
; A = 1: a draw needed with the back's cursor on (brec): ov_fl3 takes it off and calls again
ov_fl   ld a,(fready) : or a : jr nz,0F                              ; (only with the picture complete - to be shown:
        ld a,(bmax+1) : cp #7F : jp nz,ov_mck                        ;  bsync gathers till the flip: done once; or
0       ld a,(ico_ok) : or a : ret z                                 ;  conv_all's end - bmax #7FFF)
        ld a,(LD_ON) : or a : ld a,0 : ret nz                               ; (a location loading)
        ld a,(ov_pp) : or a : call z,ov_par
        ld a,(ega) : or a : ret z
        ld a,(sy_off) : cp 4 : ld a,0 : ret nz
        xor a : ld (ov_spf),a
        push ix : push iy : call 0F : pop iy : pop ix
        ld hl,ov_spf : inc (hl) : dec (hl) : ret z
        ld hl,sp_fl : jp far_m                                              ; (supv.asm: MX - far_m back to UPG: as
0       ld ix,ov_tab : ld b,OV_N                                            ;  ov_fl's caller far_x)
1       push bc
        ld a,(ix+0) : or a : jp z,7F
        cp 30 : jr c,10F
        ld a,(infight) : or a : jr z,12F : ld (ix+0),0 : jp 7F             ; (the map, the buttons: gone in a fight - PLA, PLB its plane)
12      ld a,(ix+0) : cp 30 : jr nz,10F : call ov_map : or a : jp z,7F : pop bc : ret     ; (A = 1: the cursor first)
10      bit 7,(ix+7) : jr nz,11F : inc (ix+7) : ld a,(ix+7) : cp 100 : jr c,11F
        ld (ix+0),0 : jp 7F                                                 ; (not seen for 100 steps: gone)
11      ; its rows' bsync groups
        ld a,(ix+1) : rrca : rrca : rrca : and 3 : call ov_bit : ld c,a
        ld a,(ix+1) : add a,(ix+3) : dec a : rrca : rrca : rrca : and 3 : call ov_bit : add a,a : dec a
        ld e,a : ld a,c : dec a : cpl : and e : ld c,a                      ; C = the groups
        ld a,(ix+2) : rrca : rrca : rrca : and 31 : ld l,a : ld h,high bsync ; (bsync: #0040 + row)
        ld a,(ix+2) : add a,(ix+4) : dec a : rrca : rrca : rrca : and 31 : sub l : inc a : ld b,a
        ld a,l : add a,low bsync : ld l,a : xor a
2       or (hl) : inc l : djnz 2B
        and c : jp z,7F
        ld a,#80 : ld (ov_bh),a : xor a : ld (ov_sx),a : push ix : pop iy : call ov_sum
        ld a,(ix+0) : cp 31 : jr c,30F : bit 6,(ix+7) : jr z,30F
        res 6,(ix+7) : ld (ix+5),e : ld (ix+6),d                            ; (a button's first time: its sum now,
        call ov_cst                                                         ;  its cells' too)
30      ld a,(ix+5) : cp e : jr nz,6F : ld a,(ix+6) : cp d : jr nz,6F
        bit 7,(ix+7) : jr z,31F : ld a,(ix+0) : cp 66 : jr nz,32F           ; (its cells' sums: the first time; the
31      call ov_cst                                                         ;  crew toggle's - as now: its colours are
32                                                                          ;  its state. Not the others': the sum has
                                                                            ;  no attributes - a pressed button (cyan)
                                                                            ;  matches, its cells then would too)
        ld (ix+7),#80                                                       ; (seen: from now on gone when not so)
        ld a,(brec) : or a : jr z,3F                                        ; (the back's cursor shown?)
        pop bc : ld a,1 : ret                                               ; (it off first)
3       call ov_draw : jr 7F
6       bit 7,(ix+7) : jr z,7F                                              ; (screen 7 changed there: a button gone -
        ld a,(ix+0) : cp 31 : jr c,61F : cp 46 : jr c,62F : cp 56 : jr c,61F ;  but its cells still as they were drawn
62      call ov_pmk : jr z,63F                                              ;  again, a window's edge over the rest;
        ld a,(brec) : or a : jr z,64F : call ov_pmr : pop bc : ld a,1 : ret ;  an item / a sign kept - covered by a
64      call ov_draw : call ov_pmr : jr 7F                                  ;  window: drawn again when the window
63      call ov_pmr : ld (ix+0),0 : jr 7F                                   ;  puts its picture back - its cells
61      call ov_pmk : jr z,65F                                              ;  not covered meanwhile drawn again)
        ld a,(brec) : or a : jr z,64B : call ov_pmr : pop bc : ld a,1 : ret
65      call ov_pmr : ld (ix+7),#FF
7       ld de,8 : add ix,de : pop bc : dec b : jp nz,1B
        call tx_fl : or a : ret nz                                          ; (the text layer: text.asm)
        ld a,1 : ld (ov_spf),a : xor a : ret                                ; (then supv.asm's: ov_fl's end)
ov_bit  inc a : ld b,a : ld a,1
1       dec b : ret z : add a,a : jr 1B
; the overlay IX into the back buffer: per line its 4 parts' bytes (from ICPG via ov_buf)
ov_draw xor a : ld (ov_tr),a : ld a,#7F-ICPG : ld (ov_pg),a
        ld a,(ix+0) : dec a : ld l,0 : cp 16 : jr nc,1F
        ld h,a : srl h : rr l : ld e,l : ld d,h : add hl,hl : add hl,de     ; 384 k
        jr 2F
1       cp 55 : jp nc,ov_dbt : cp 45 : jr nc,3F : cp 30 : jp nc,ov_dbt
        sub 16 : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : ld e,l : ld d,h
        add hl,hl : add hl,hl : add hl,hl : add hl,de : ld de,6144 : add hl,de    ; 6144 + 288 k
        jr 2F
3       sub 45 : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl : ld e,l : ld d,h
        add hl,hl : add hl,de : ld de,9600 : add hl,de                     ; (the parameters' signs, then PARAMS2's: 192 k)
2       ld de,#4000 + ICO_A + 2 : add hl,de
20      ld (ov_src),hl
        ld a,(ix+2) : add a,4 : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld e,l : ld d,h
        add hl,hl : add hl,hl : add hl,de : ld e,(ix+1) : ld d,0 : add hl,de : ld (ov_dst),hl   ; (py + 4) * 40 + cx
        ld b,(ix+4)
        ld hl,(ov_pm) : ld a,h : and l : inc a : jp nz,ov_dpm               ; (some cells only: ov_pmk)
        ld a,(ov_tr) : or a : jr z,ov_dd                                    ; (no table: straight from the picture)
3       push bc
        ld a,(ov_pg) : ld bc,P_W1 : out (c),a
        ld hl,(ov_src) : ld de,ov_buf : ld a,(ix+3) : add a,a : add a,a : ld c,a : ld b,0 : ldir : ld (ov_src),hl
        ld a,(ov_tr) : or a : call nz,ov_xl
        ld a,(bf) : or a : ld a,#7F-PS3 : ld e,#7F-PS7 : jr z,4F : ld a,#7F-PS1 : ld e,#7F-PS5   ; (the back one)
4       ld bc,P_W1 : out (c),a : ld a,e : ld b,H_W2 : out (c),a
        ld hl,ov_buf : ld de,(ov_dst) : set 6,d : call 5F                   ; part 0: W1 +0
        set 5,d : call 5F                                                   ; part 1: W1 +#2000
        res 5,d : res 6,d : set 7,d : call 5F                               ; part 2: W2 +0
        set 5,d : call 5F                                                   ; part 3: W2 +#2000
        ld hl,(ov_dst) : ld de,40 : add hl,de : ld (ov_dst),hl
        pop bc : djnz 3B
        ret
5       push de : ld c,(ix+3) : ld b,0 : ldir : pop de : ret
; ov_draw without ov_buf: parts 0, 1 into W1 with the picture's page in W2, then parts 2, 3 into W2 with it in W1
ov_dd   ld a,(bf) : or a : ld a,#7F-PS3 : ld e,#7F-PS7 : jr z,1F : ld a,#7F-PS1 : ld e,#7F-PS5   ; (the back one)
1       ld (ov_p1),a : ld a,e : ld (ov_p2),a
2       push bc
        ld a,(ov_p1) : ld bc,P_W1 : out (c),a : ld a,(ov_pg) : ld b,H_W2 : out (c),a
        ld hl,(ov_src) : ld a,h : add a,#40 : ld h,a                       ; (the picture in W2)
        ld de,(ov_dst) : set 6,d : call 5B                                  ; part 0: W1 +0
        set 5,d : call 5B                                                   ; part 1: W1 +#2000
        ld a,h : sub #40 : ld h,a                                           ; (the picture in W1)
        ld a,(ov_pg) : ld bc,P_W1 : out (c),a : ld a,(ov_p2) : ld b,H_W2 : out (c),a
        res 5,d : res 6,d : set 7,d : call 5B                               ; part 2: W2 +0
        set 5,d : call 5B                                                   ; part 3: W2 +#2000
        ld (ov_src),hl
        ld hl,(ov_dst) : ld de,40 : add hl,de : ld (ov_dst),hl
        pop bc : djnz 2B
        ret
ov_p1   db 0
ov_p2   db 0
; ---- a button partly covered (a window's edge over it): its cells still as the game drew them (each one's sum as
; at its first time - ICPG OV_CS + slot * 16) drawn again, the rest the conversion's (the window's)
OV_CS   equ #3C00                               ; (ICPG past UFO2.ICO: 16 bytes per ov_tab slot)
; IX = an overlay of 4 x 4 cells at most at a row's line 0 (a button, a sign) -> ov_cb: its cells' sums on screen 7 now
; (row * 4 + column; the attribute too), Z; NZ: not such
ov_cs9  or 1 : ret
ov_csm  ld a,(ix+3) : cp 5 : jr nc,ov_cs9 : ld a,(ix+2) : and 7 : jr nz,ov_cs9
        ld a,(ix+4) : ld c,a : and 7 : jr nz,ov_cs9 : ld a,c : cp 33 : jr nc,ov_cs9
        rrca : rrca : rrca : ld c,a                                         ; (C: its rows)
        ld hl,ov_cb : ld b,16
ov_cz   ld (hl),0 : inc hl : djnz ov_cz
        push bc : WIN P_W2, PG_ZX+7 : pop bc
        ld de,ov_cb : ld a,(ix+2)
1       push af : push bc : push de
        ld b,a : rrca : rrca : rrca : and #18 : or #80 : ld h,a             ; (line 0 of the row: y & 7 = 0)
        ld a,b : rlca : rlca : and #E0 : or (ix+1) : ld l,a
        ld a,h : rrca : rrca : rrca : and 3 : or #98 : ld (ov_ap+1),a : ld a,l : ld (ov_ap),a   ; (its attributes)
        ld c,(ix+3)
2       push hl : xor a : ld b,8
3       rlca : add a,(hl) : inc h : djnz 3B
        ld b,a : ld hl,(ov_ap) : ld a,(hl) : and #3F : cp #28 : jr nz,4F : ld a,#30     ; (cyan - a button pressed -
4       add a,b : inc hl : ld (ov_ap),hl                                    ;  as yellow; no bright, flash; the attribute: a window's
        ld (de),a : inc de : pop hl : inc l : dec c : jr nz,2B               ;  empty cells' pixels may be the same)
        pop de : ld hl,4 : add hl,de : ex de,hl
        pop bc : pop af : add a,8 : dec c : jr nz,1B
        WIN P_W2, PG_ZX+2
        xor a : ret                                                         ; (Z: done)
; IX's slot -> HL = its cells' sums in ICPG (at W1 meanwhile)
ov_csl  push ix : pop hl : ld de,ov_tab : or a : sbc hl,de                  ; (slot * 8)
        add hl,hl : ld de,#4000 + OV_CS : add hl,de
        WIN P_W1, ICPG : ret
; (first time) its cells' sums kept
ov_cst  call ov_csm : ret nz
        call ov_csl : ex de,hl : ld hl,ov_cb : ld bc,16 : ldir
        WIN P_W1, PG_ZX+5 : ret
; (screen 7 changed there) -> ov_pm: the cells as kept (bit row * 4 + column); Z: none (or not a button)
ov_pmk  ld hl,0 : ld (ov_pm),hl
        call ov_csm : jp nz,9F
        call ov_csl : ld de,ov_cb : ld b,16
1       ld a,(de) : sub (hl) : sub 1                                        ; (CY: the same)
        push hl : ld hl,(ov_pm) : rr h : rr l : ld (ov_pm),hl : pop hl
        inc hl : inc de : djnz 1B
        ; a window covers a rectangle: a cell inside the covered ones' box is covered too (its sum the same by chance -
        ; an empty cell of the window's colour); E: the box's rows, D: its columns
        ld hl,(ov_pm) : ld a,l : cpl : ld c,a : ld a,h : cpl : ld b,a       ; (BC: the covered cells)
        or c : ld d,a : rrca : rrca : rrca : rrca : or d : and 15 : call 8F : ld d,a
        ld e,0 : ld a,c : and 15 : jr z,1F : set 0,e
1       ld a,c : and #F0 : jr z,2F : set 1,e
2       ld a,b : and 15 : jr z,3F : set 2,e
3       ld a,b : and #F0 : jr z,4F : set 3,e
4       ld a,e : call 8F : ld e,a
        ld a,d : rlca : rlca : rlca : rlca : or d : cpl : ld d,a            ; (D: both nibbles - not the box's columns)
        ld hl,(ov_pm) : ld a,l
        bit 0,e : jr z,5F : or #F0 : and d : or #F0 : and l : ld l,a        ; (row 0: its nibble)
        ld a,l
5       bit 1,e : jr z,6F : or #0F : and d : or #0F : and l : ld l,a
6       ld a,h
        bit 2,e : jr z,7F : or #F0 : and d : or #F0 : and h : ld h,a
        ld a,h
7       bit 3,e : jr z,71F : or #0F : and d : or #0F : and h : ld h,a
71      ld (ov_pm),hl
9       WIN P_W1, PG_ZX+5
        ld hl,(ov_pm) : ld a,h : or l : ret
8       ld h,a : add a,a : or h : ld l,a : add a,a : or l : ld l,a : add a,a : or l : and 15 : ld l,a   ; (A's bits from its lowest
        ld a,h : srl a : or h : ld h,a : srl a : or h : ld h,a : srl a : or h : and l : ret             ;  to its highest)
ov_pmr  ld hl,#FFFF : ld (ov_pm),hl : ret
; ov_draw's lines with some cells only (ov_pm; B lines, ov_src, ov_dst, ov_pg, ov_tr as there)
ov_dpm  ld c,0
1       push bc
        ld a,(ov_pg) : ld bc,P_W1 : out (c),a
        ld a,(ix+3) : add a,a : add a,a : ld c,a : ld b,0                   ; (w * 4 bytes: the 4 parts)
        ld hl,(ov_src) : ld de,ov_buf : ldir : ld (ov_src),hl
        ld a,(ov_tr) : or a : call nz,ov_xl
        ld a,(bf) : or a : ld a,#7F-PS3 : ld e,#7F-PS7 : jr z,2F : ld a,#7F-PS1 : ld e,#7F-PS5   ; (the back one)
2       ld bc,P_W1 : out (c),a : ld a,e : ld b,H_W2 : out (c),a
        pop bc : push bc
        ld a,c : rrca : rrca : rrca : and 3 : ld b,a : ld hl,(ov_pm)          ; (the line's row: its 4 bits)
        cp 2 : ld a,l : jr c,3F : ld a,h
3       bit 0,b : jr z,4F : rrca : rrca : rrca : rrca
4       and 15 : ld (ov_cm),a
        ld hl,ov_buf : ld de,(ov_dst) : set 6,d : call 5F                   ; part 0: W1 +0
        set 5,d : call 5F                                                   ; part 1: W1 +#2000
        res 5,d : res 6,d : set 7,d : call 5F                               ; part 2: W2 +0
        set 5,d : call 5F                                                   ; part 3: W2 +#2000
        ld hl,(ov_dst) : ld de,40 : add hl,de : ld (ov_dst),hl
        pop bc : inc c : dec b : jp nz,1B
        ret
5       push de : ld a,(ov_cm) : ld b,(ix+3)                                ; (a part's bytes, those of ov_cm's cells)
6       rrca : jr nc,7F : ld c,a : ld a,(hl) : ld (de),a : ld a,c
7       inc hl : inc de : djnz 6B
        pop de : ret
ov_cm   db 0
ov_spf  db 0
ov_ap   dw 0
ov_cb   ds 16
ov_pm   dw #FFFF                                ; (ov_draw: the cells to draw; #FFFF all)
; a button (UFO2.ICO's buttons in PLB: 512 bytes each, then the active one's table - unpacked once the map is new);
; screen 7's attribute in its label's cell: paper cyan - active (the table)
ov_dbt  cp 44 : jr nz,0F                                                 ; (the windows' buttons: after the table)
        ld a,(ov_bu) : or a : call nz,ov_bun
        xor a : ld (ov_tr),a : ld a,#7F-PLB : ld (ov_pg),a
        ld hl,#4000 + OV_NB * 512 + 256 : jp 20B
0       cp 55 : jr c,01F : sub 9                                            ; (the target menu's: past the windows')
01      sub 30 : add a,a : ld h,a : ld l,0 : ld de,#4000 : add hl,de : push hl
        ld a,(ov_bu) : or a : call nz,ov_bun
        WIN P_W2, PG_ZX+7
        ld de,#0101 : ld hl,(ov_pm) : ld a,h : and l : inc a : jr z,02F     ; (all of it: its cell 1, 1's colour)
        ld de,0                                                             ; (some cells only: the first one drawn -
03      srl h : rr l : jr c,02F : inc e : ld a,e : cp 4 : jr c,03B : ld e,0 : inc d : jr 03B   ;  1, 1 may be covered)
02      ld a,d : add a,a : add a,a : add a,a : add a,(ix+2) : ld l,a : ld h,0 : add hl,hl : add hl,hl
        ld a,(ix+1) : add a,e : ld e,a : ld d,#98 : add hl,de
        ld a,(hl) : and #3F : sub #28 : jr z,11F                            ; (black on cyan: active)
        sub 8 : jr z,1F                                                     ; (black on yellow)
        sub 8 : jr z,1F                                                     ; (black on white: the target menu's)
        pop hl : ld (ix+0),0 : ret                                          ; (not the geoscape's button now: gone)
11      inc a
1       ld (ov_tr),a : ld a,#7F-PLB : ld (ov_pg),a
        pop hl : jp 20B
ov_bun  xor a : ld (ov_bu),a
        WIN P_W1, PLB
        ld a,(bt_ok) : or a : jr z,1F                                       ; (still there - nothing else used PLB
        ld hl,#4000 + BT_K : ld de,bt_sig : ld b,16                         ;  since: kept)
2       ld a,(de) : cp (hl) : jr nz,1F : inc hl : inc de : djnz 2B
        ret
1       WIN P_W2, SC_P0+3
        ld hl,(#9B00 + 9470) : ld de,#9B00 : add hl,de : ld de,#4000 : call ep_lz
        ld hl,#4000 + BT_K : ld de,bt_sig : ld bc,16 : ldir : ld a,1 : ld (bt_ok),a : ret
BT_K    equ 2 * 512 + 100
bt_sig  equ #FF50                               ; (XPG #FC00..: free - ov_buf; not cleared: a
bt_ok   equ #FF60                               ;  mismatch then, unpacked)
; ov_buf's 16 bytes through the table (PLB #1400: W1)
ov_xl   ld hl,ov_buf : ld b,16 : ld d,high (#4000 + OV_NB * 512)
1       ld e,(hl) : ld a,(de) : ld (hl),a : inc hl : djnz 1B
        ret
ov_bu   db 0                                    ; 1: the buttons to be unpacked into PLB
ov_tr   db 0
ov_pg   db 0
; once: the fight's side panel's parameters (its picture OPG0 / OPG1: x 298..317, y 20 + 20k, 11 lines) <- ICO's
; PARAMS (20 x 11 of each sign from x 2, line 2): the same signs as the fighter's screen's
ov_par  ld a,1 : ld (ov_pp),a
        push ix
        WIN P_W1, ICPG
        ld hl,#4000 + ICO_A + 2 + 6144 + 12 * 288 + 2 * 12 : ld de,20 * 40 : ld b,6
1       push bc : ld b,11
2       push bc : push hl : push de : ld ix,ov_sd : ld b,10
3       ld a,(ix+0) : push hl : add a,l : ld l,a : jr nc,4F : inc h
4       ld c,(hl) : pop hl
        ld a,(ix+1) : push bc : ld bc,P_W2 : out (c),a : pop bc
        push de : ld a,(ix+2) : add a,e : ld e,a : ld a,(ix+3) : adc a,d : ld d,a : ld a,c : ld (de),a : pop de
        inc ix : inc ix : inc ix : inc ix : djnz 3B
        pop de : ld hl,40 : add hl,de : ex de,hl : pop hl : ld bc,12 : add hl,bc : pop bc : djnz 2B
        ld bc,5 * 12 : add hl,bc : ex de,hl : ld bc,9 * 40 : add hl,bc : ex de,hl : pop bc : djnz 1B
        WIN P_W1, PG_ZX+5
        WIN P_W2, PG_ZX+2
        pop ix : ret
; (pairs 149..158: ICO's byte in its line, W2's port value - OPG0 / OPG1 -, the byte's address in W2)
ov_sd   db 6,#6E,#25,#80, 3,#6F,#25,#A0, 9,#6E,#25,#A0, 1,#6F,#26,#80, 7,#6E,#26,#80, 4,#6F,#26,#A0, 10,#6E,#26,#A0, 2,#6F,#27,#80, 8,#6E,#27,#80, 5,#6F,#27,#A0
ov_pp   db 0
ico_map db 0                                    ; 1: UFO2.ICO's world map in page 58 (xtil.asm ico_load)
ov_mu   db 0                                    ; 1: to unpack into PLA first
ico_ok  db 0                                    ; 1: UFO2.ICO loaded (xtil.asm ico_load)
ov_id   db 0
ov_bh   db 0
ov_de   dw 0
ov_sx   db 0
ov_rr   db 0
ov_src  dw 0
ov_dst  dw 0
ov_buf  equ #FF80                               ; (XPG past UFO2.TIL's index, #FC00..: free) a line's 4 parts, 12 bytes each at most
ov_tab  ds 8 * OV_N                            ; id + 1 (0: free), cx, py, w (characters), h (lines), sum (2), #80: seen (else steps)

; ---- the world map (xEARTH at 0, 0: 24 x 120 lines, attribute #69 / #68): the game's own picture's pixels drawn
; from ours (PLA: unpacked from page 58 when the map is drawn - PLA is free outside the fights), the others - the
; game's marks - white (ink) / yellow (paper); cells of other attributes left as converted. IX = its entry -> A = 0;
; 1: the back's cursor first. Gone when row 0 is not the map's (a picture over it; a window leaves its top row).
; Ours: per line 4 x 24 pair bytes (unpacked: 24 x the pairs 0..3; then by the buffer's positions - pairs 0, 2, 1, 3)
MP_B    equ #2D00                                       ; (PLA: ours 120 x 96, the game's picture, a line's result)
MP_O    equ #3840
MP_K    equ 60 * 96 + 40                                ; (16 bytes of ours: still there? mp_sig)
ov_map  WIN P_W2, PG_ZX+7
        ld hl,#9800 : ld bc,24 * 256                       ; (row 0: a window over the map - the encyclopedia, SAVE - starts lower)
1       ld a,(hl) : and #FE : cp #68 : jr nz,2F : inc c
2       inc hl : djnz 1B
        push bc : WIN P_W2, PG_ZX+2 : pop bc
        ld a,c : cp 12 : jr nc,3F : ld (ix+0),0 : xor a : ret
3       call om_gat                                                         ; (the marks from the game's state)
        ld hl,bsync : ld b,15 : xor a
4       or (hl) : inc l : djnz 4B
        and 7 : ld hl,om_ch : or (hl)
        ret z
        ld a,(brec) : or a : ld a,1 : ret nz
        ld a,(ov_mu) : or a : jp z,5F
        xor a : ld (ov_mu),a
        WIN P_W1, PLA
        ld a,(mp_ok) : or a : jr z,54F                                      ; (never unpacked yet)
        ld hl,#4000 + MP_K : ld de,mp_sig : ld b,16                         ; (ours still there - nothing else
53      ld a,(de) : cp (hl) : jr nz,54F : inc hl : inc de : djnz 53B        ;  used PLA since: kept)
        jr 55F
54      WIN P_W2, SC_P0+3
        ld hl,#9B00 + 2 : ld de,#4000 : call ep_lz                          ; ours
        push ix : ld hl,#4000 : ld b,120                                    ; ours: each line by the buffer's
51      push bc : ld ix,#4000 + MP_O : ld b,24                              ; positions (ov_mln: pairs 0, 2, 1, 3
52      ld a,(hl) : ld (ix+0),a : inc hl : ld a,(hl) : ld (ix+48),a : inc hl  ; - 24 bytes each)
        ld a,(hl) : ld (ix+24),a : inc hl : ld a,(hl) : ld (ix+72),a : inc hl : inc ix : djnz 52B
        ld de,-96 : add hl,de : ex de,hl : ld hl,#4000 + MP_O : ld bc,96 : ldir : ex de,hl
        pop bc : djnz 51B : pop ix
        ld hl,#4000 + MP_K : ld de,mp_sig : ld bc,16 : ldir : ld a,1 : ld (mp_ok),a
55
5       push ix : ld c,0                                                    ; rows 0..14
6       ld a,c : add a,low bsync : ld l,a : ld h,high bsync : ld a,(hl) : and 7 : jr z,9F
        ld de,SYN : add hl,de : ld e,(hl)                                   ; (its lines)
        ld a,c : add a,a : add a,a : add a,a : ld b,a                       ; B = y
        ld a,8
7       rrc e : push af : push bc : push de : call c,ov_mlc : pop de : pop bc : inc b : pop af : dec a : jr nz,7B
9       inc c : ld a,c : cp 15 : jr c,6B
        ld a,(om_ch) : or a : call nz,om_upd                                ; (the marks: those changed)
        pop ix : xor a : ret
; line B of the map -> the back buffer, unless it is there already: bsync gathers till the flip, so the lines a step
; marks come again in the next steps - the back buffer's line (part 0: 24 bytes) is checked against what was left there
; (a signature per buffer and line: TXPG #2C00 + bf * 256 + y * 2); the conversion's would differ
ov_mlc  ld a,b : ld (ov_y),a
        call ov_sgc : ret z
        ld a,(ov_y) : ld b,a : call ov_mln
        call ov_sgc : ld (hl),e : inc hl : ld (hl),d
        ld a,(bf) : or a : ld a,#7F-PS7 : jr z,1F : ld a,#7F-PS5                ; (W2: the back buffer's again, as ov_mln left it)
1       ld bc,P_W2 : out (c),a : ret
; W1: the back buffer's part 0, W2: TXPG; DE: line ov_y's signature, HL: its slot; Z: the same as kept
ov_sgc  ld a,(bf) : or a : ld a,#7F-PS3 : jr z,1F : ld a,#7F-PS1
1       ld bc,P_W1 : out (c),a : ld bc,P_W2 : ld a,#7F-TXPG : out (c),a
        ld a,(ov_y) : add a,4 : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld e,l : ld d,h
        add hl,hl : add hl,hl : add hl,de : ld de,#4000 : add hl,de
        ld de,0 : ld b,24
2       ld a,(hl) : add a,e : ld e,a : xor d : rlca : ld d,a : inc hl : djnz 2B
        ld a,(ov_y) : add a,a : ld l,a : ld a,(bf) : add a,#AC : ld h,a
        ld a,(hl) : cp e : ret nz : inc hl : ld a,(hl) : dec hl : cp d : ret
; line B of the map -> the back buffer
ov_mln  ld a,b : ld (ov_y),a
        WIN P_W1, PG_ZX+7                                                  ; screen 7's attributes: the map's cells
        ld a,(ov_y) : and #F8 : ld l,a : ld h,0 : add hl,hl : add hl,hl : ld de,#5800 : add hl,de
        ld de,ov_ba : ld bc,24 : ldir
        ld hl,ov_ba : ld b,24
1       ld a,(hl) : and #FE : sub #68 : ld (hl),a : inc hl : djnz 1B       ; (0: a map cell)
        WIN P_W1, PLA
        ld a,(ov_y) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld e,l : ld d,h : add hl,hl : add hl,de
        add hl,hl : add hl,hl : ld de,#4000 : add hl,de                     ; (ours: y * 96)
        ld de,#4000 + MP_O : ld (ov_ou),de : ld bc,96 : ldir                ; (the line: ours, then the marks on it)
        call om_plt
        ; the positions (24 bytes each: the pairs 0, 2, 1, 3) into the back buffer (the map's cells only)
        ld a,(ov_y) : add a,4 : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld e,l : ld d,h
        add hl,hl : add hl,hl : add hl,de : ld (ov_dst),hl
        ld hl,ov_ba : ld b,24 : xor a                                       ; (0: all the map's cells)
5       or (hl) : inc hl : djnz 5B : ld (ov_k),a : or a : call nz,ov_runs
        ld a,(bf) : or a : ld a,#7F-PS3 : ld e,#7F-PS7 : jr z,51F : ld a,#7F-PS1 : ld e,#7F-PS5    ; (the back one)
51      ld bc,P_W2 : out (c),a : ld a,e : ld (ov_p),a                      ; (W1 stays PLA: positions 0, 1 into
        ld hl,(ov_ou) : ld a,#80 : call 6F : ld a,#A0 : call 6F           ;  W2 #8000, #A000 - the back's parts 0, 2)
        ld a,(ov_p) : ld bc,P_W2 : out (c),a
        ld a,#80 : call 6F : ld a,#A0 : call 6F                             ; (2, 3: parts 1, 3)
        ld a,(bf) : or a : ld a,#7F-PS3 : jr z,52F : ld a,#7F-PS1
52      ld bc,P_W1 : out (c),a : ret                                       ; (W1, W2: the back buffer)
; HL = a position's 24 bytes (PLA at W1) -> W2's (A * 256 + ov_dst): only the map's cells (ov_k: all are; else their
; runs - ov_rl); HL past them
6       ld de,(ov_dst) : add a,d : ld d,a
        ld a,(ov_k) : or a : jr nz,61F
        ld bc,24 : ldir : ret
61      ld (ov_s0),hl : ld (ov_d0),de : ld hl,ov_rl
62      ld a,(hl) : inc hl : ld c,(hl) : inc hl : inc c : dec c : jr z,69F       ; A = its start, C = its length
        push hl
        ld hl,(ov_s0) : ld e,a : ld d,0 : add hl,de : push hl
        ld hl,(ov_d0) : add hl,de : ex de,hl : pop hl : ld b,0 : ldir
        pop hl : jr 62B
69      ld hl,(ov_s0) : ld de,24 : add hl,de : ret
; not to be shown yet: the world map there, its marks changed (blinks) - a flip wanted (bchg: ov_map draws them
; when the back buffer is complete) -> A = 0
ov_mck  ld a,(ega) : ld hl,ico_ok : and (hl) : ret z
        ld a,(LD_ON) : ld hl,infight : or (hl) : ld a,0 : ret nz
        ld hl,ov_tab : ld de,8 : ld b,OV_N
1       ld a,(hl) : cp 30 : jr z,2F : add hl,de : djnz 1B
        xor a : ret
2       call om_gat : ld a,(om_ch) : or a : ret z
        ld (bchg),a : xor a : ret
; ---- the game's marks on the map, ours (not screen 7's): its own fighter, the UFO, our bases, the targets (SHOWD,
; SHOWS, SHOWT: XOR sprites of SPM - their places and shapes; shown while T_D / T_M is 1). om_gat: the list now
; (om_ml: type, x, y, shown; #FF the end) - when it differs from the last one, the lines of both lists' shown marks
; (y - 1 .. y + 4) pending in both buffers (om_pd: 15 rows' line bits each); W1, W2: the back buffer after
om_gat  WIN P_W1, PG_ZX+5 : WIN P_W2, PG_ZX+2
        ld hl,om_ml : ld (om_p),hl
        ld a,(G_TD) : and 1 : ld (om_v),a
        ld a,(G_TINTR) : inc a : jr z,1F
        ld hl,(G_INTR) : xor a : call om_add                                ; (0: our fighter)
1       ld a,(G_TUFO) : inc a : jr z,2F : ld a,(G_UFOV) : or a : jr nz,2F
        ld hl,(G_UFO) : ld a,2 : call om_add                                ; (2: the UFO)
2       ld a,(G_TD+1) : dec a : rrca : rrca : rrca : rrca : and 1 : ld (om_v),a   ; (our bases: half T_M's rate - the game's
        ld hl,G_BASE : ld de,G_XBASE : ld b,8                               ;  T_SW, T_M flips at its 8 k + 1)
21      ld a,(hl) : inc hl : cp 100 : jr nc,22F
        push hl : ex de,hl : ld e,(hl) : inc hl : ld d,(hl) : dec hl : ex de,hl : ld a,1 : call om_add : pop hl
22      inc de : inc de : djnz 21B                                          ; (1: our bases)
        ld a,(G_TM) : and 1 : ld (om_v),a
        ld hl,G_TSHP : ld de,G_SWST : ld b,3
3       ld a,(hl) : inc hl : cp 255 : jr z,31F
        push hl : push de : push bc : ex de,hl : ld e,(hl) : inc hl : ld d,(hl) : ex de,hl   ; (its table: WT)
        add a,a : add a,l : ld l,a : jr nc,$+3 : inc h : ld e,(hl) : inc hl : ld d,(hl) : ex de,hl
        ld a,b : call om_add : pop bc : pop de : pop hl
31      inc de : inc de : inc b : ld a,b : cp 10 : jr c,3B                  ; (3..9: the targets)
        ld a,(LAY_PMP+2) : or a : jr z,32F : rrca : jr c,32F                   ; (the target's crosshair - xlic.asm PMAP's
        ld (om_v),a : ld hl,(LAY_PMP) : ld a,10 : call om_add                 ;  pass B even: its lines on - type 10)
32      ld hl,(om_p) : ld (hl),#FF
        ld bc,P_W1 : ld a,(bf) : or a : ld a,#7F-PS3 : jr z,4F : ld a,#7F-PS1  ; (W1, W2: the back buffer)
4       out (c),a : sub 4 : ld b,H_W2 : out (c),a
        ld hl,om_d0 : ld a,(bf) : or a : jr z,5F : ld hl,om_d1
5       ld (om_dp),hl : ld de,om_ml : xor a : ld (om_ch),a                  ; (the back buffer's marks drawn: the same?)
51      ld a,(hl) : call om_cmp : jr nz,52F
        inc a : ret z
        ld bc,4 : add hl,bc : ex de,hl : add hl,bc : ex de,hl : jr 51B
52      ld a,1 : ld (om_ch),a : ret
; Z: the entries HL, DE the same (A = (HL))
om_cmp  push hl : push de : push bc : ld b,4
        ld a,(de) : cp (hl) : jr nz,2F : inc a : jr z,2F                   ; (both ended)
1       ld a,(de) : cp (hl) : jr nz,2F : inc hl : inc de : djnz 1B
2       pop bc : pop de : pop hl : ld a,(hl) : ret
om_add  push hl : push de : ex de,hl : ld hl,(om_p) : ld (hl),a : inc hl : ld (hl),e : inc hl : ld (hl),d : inc hl
        ld a,(om_v) : ld (hl),a : inc hl : ld (om_p),hl : pop de : pop hl : ret
; the marks on line ov_y -> the line (W1 #4000 + MP_O: by the buffer's positions)
om_plt  ld ix,om_ml
1       ld a,(ix+0) : cp #FF : ret z
        ld a,(ix+3) : or a : jp z,9F
        ld a,(ix+0) : cp 10 : jr nz,11F                                     ; (the crosshair: white lines)
        ld a,#47 : ld (om_cl),a : ld a,#B8 : ld (om_cr),a
        ld a,(ov_y) : cp (ix+2) : jr nz,12F
        ld a,1 : ld b,190
13      call om_px : inc a : djnz 13B : jr 9F
12      or a : jr z,9F : cp 119 : jr nc,9F : ld a,(ix+1) : call om_px : jr 9F
11      ld a,(ov_y) : sub (ix+2) : inc a : cp 6 : jr nc,9F                  ; (its rows: y - 1 .. y + 4)
        add a,a : ld c,a : ld a,(ix+0) : ld b,a : add a,a : add a,b : add a,a : add a,b : add a,a   ; type * 14
        add a,c : ld e,a : ld d,0 : ld hl,om_sh : add hl,de                 ; (its row: edge, shape)
        ld a,(ix+0) : ld b,a : add a,a : add a,b : add a,a : add a,b : add a,a : add a,12
        push hl : ld e,a : ld d,0 : ld hl,om_sh : add hl,de : ld a,(hl) : ld (om_ce),a : inc hl : ld a,(hl) : ld (om_cf),a
        pop hl : ld a,(hl) : or a : jr z,2F
        ld c,a : ld a,(om_ce) : call 3F                                     ; (the edge first)
2       inc hl : ld c,(hl) : ld a,(om_cf) : call 3F
9       ld de,4 : add ix,de : jp 1B
3       ld (om_cl),a : ld b,a : and 7 : rlca : rlca : rlca : ld e,a : ld a,b : and #40 : add a,a : or e : ld (om_cr),a
        ld a,(ix+1) : dec a : ld b,8                                        ; (bit 7: x - 1)
4       rl c : call c,om_px : inc a : djnz 4B
        ret
; pixel A (0..191) of the line: colour (om_cl / om_cr: its left / right bits)
om_px   cp 192 : ret nc
        push af : push bc : push hl
        ld c,a : srl a : ld b,a : and 3 : ld e,a : ld d,0 : ld hl,om_po : add hl,de
        ld a,b : srl a : srl a : add a,(hl) : add a,low (#4000 + MP_O) : ld l,a : ld h,high (#4000 + MP_O)
        ld a,(hl) : bit 0,c : jr nz,1F
        and #B8 : ld b,a : ld a,(om_cl) : jr 2F
1       and #47 : ld b,a : ld a,(om_cr)
2       or b : ld (hl),a
        pop hl : pop bc : pop af : ret
        ASSERT low (#4000 + MP_O) + 95 < 256
om_po   db 0, 48, 24, 72                                ; (pair p's part: its position)
; per type: 6 rows (y - 1 .. y + 4; bit 7: x - 1) of (edge, shape), then their colours (a left pixel's bits)
om_sh
        db #20,#00,#50,#20,#88,#70,#50,#20,#20,#00,#00,#00, #00,#47     ; our fighter: white +, black edge
        db #00,#00,#00,#70,#00,#50,#00,#70,#00,#00,#00,#00, #00,#02     ; a base
        db #00,#00,#00,#50,#00,#20,#00,#50,#00,#00,#00,#00, #47,#42     ; the UFO: bright red x (0.65.1: no edge)
        db #00,#00,#00,#28,#00,#7C,#00,#3C,#00,#00,#00,#00, #00,#02     ; ship
        db #00,#00,#00,#70,#00,#70,#00,#70,#00,#00,#00,#00, #00,#02     ; port
        db #00,#00,#00,#60,#00,#60,#00,#00,#00,#00,#00,#00, #00,#02     ; island
        db #00,#00,#00,#02,#00,#06,#00,#02,#00,#00,#00,#00, #00,#02     ; alien base
        db #00,#00,#00,#30,#00,#48,#00,#48,#00,#30,#00,#00, #00,#02     ; colony
        db #00,#00,#00,#30,#00,#78,#00,#78,#00,#30,#00,#00, #00,#02     ; UFO base
        db #00,#00,#00,#78,#00,#48,#00,#48,#00,#78,#00,#00, #00,#02     ; Tleth
OM_N    equ 18
LAY_PMP equ #3DE0                               ; (W0, build/mods.py: PMAP's crosshair - x, y, its pass B)
OM_BN   equ 10                                  ; (the map's lines drawn in a step at most)
om_ml   equ #FEB0                               ; (XPG #FC00..: ommap.asm's code, then) the marks now: type, x, y,
om_el   equ om_ml+4*OM_N+1                      ;  shown; #FF - the erased ones' x, y (an update); #FF
om_at   equ om_el+2*OM_N+1                      ;  a cell row (24): 0 - the map's
om_d0   db #FF : ds 4*OM_N                             ; the marks as drawn in buffer 0, 1
om_d1   db #FF : ds 4*OM_N
        ASSERT om_at + 24 <= ov_ou
om_dp   dw 0
om_ch   db 0
om_p    dw 0
om_v    db 0
om_md   db 0
om_x0   db 0
om_ly   db 0
om_ar   db 0
om_xa   db 0
om_cy   db 0
om_lp   dw 0
om_lo   dw 0
om_pa   db 0
om_pb   db 0
om_ce   db 0
om_cf   db 0
om_cl   db 0
om_cr   db 0
ov_ou   equ #FF3E
mp_sig  equ #FF40
mp_ok   equ #FF61
; ov_ba's runs of the map's cells (0) -> ov_rl: (start, length) .., (0, 0)
ov_runs ld hl,ov_ba : ld de,ov_rl : ld c,0
1       ld a,c : cp 24 : jr nc,9F
        ld a,(hl) : or a : jr z,2F
        inc hl : inc c : jr 1B
2       ld a,c : ld (de),a : inc de : ld b,0
3       inc b : inc hl : inc c : ld a,c : cp 24 : jr nc,4F : ld a,(hl) : or a : jr z,3B
4       ld a,b : ld (de),a : inc de : jr 1B
9       xor a : ld (de),a : inc de : ld (de),a : ret
ov_s0   equ #FF62                               ; (XPG #FC00..: free)
ov_d0   equ #FF64
ov_rl   equ #FF66                               ; (26)
        ASSERT ov_rl+26 <= ov_buf
ov_y    db 0
ov_p    db 0
ov_k    db 0
ov_ba   ds 24
