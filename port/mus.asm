; ------------------------------------------------------------------ music (PT3, Vortex Tracker II player, S.V.Bulba)
; Files beside UFO2.DAT: INTRO.PT3 (loading), WORLDMAP.PT3 (the map), EARTH.PT3 (the menu), UNDERWAT.PT3 (a location
; fight), INTERCPT.PT3 (the 3D fight). The image: the player + its variables at #C000, the modules in slots S0 / S1 /
; S2; two pages: MUSPA (S0 the map, S1 the menu, S2 the fight), MUSPB (S0 the intro, S1 the 3D fight).
; While loading: the image in CP/M's page 3 (its TPA #C000..#DBFF), the intro (S0) played from CP/M's own interrupt
; (its IM2 vector at I*256+#FF -> LD_INT, then CP/M's handler). In the game: ui_int (int_h, W0) maps the page MUS_PV and
; calls MUS_TICK; in the fights (interrupts on since v75: NedoOS's UFO-2 by Alone Coder showed the way - the sprites
; without SP) int_f (W0's page zero): only the music, W3 put back from W3V; in the game's HALT: int_h as before.
MUSPA   equ 24
MUSPB   equ 25
M_S0    equ #CA40               ; 4K
M_S1    equ #DA40               ; 4K
M_S2    equ #EA40               ; 4.5K
M_INTRO equ M_S0
LSTK    equ #DBF0               ; LD_INT's stack (page 3, below BDOS)
MUS_OFF equ #3DF0               ; W0 (cleared at the start): 1 = the music off (the icon)
DBG     equ #3DF1               ;   1: "UFO2 DEBUG" (the service buttons)
LZ_ON   equ #3DF2               ;   1: LAZY done
W3V     equ #3DF3               ;   window 3's port value now (map_w3 / map_w3p keep it)
MUS_TRK equ #3DF4               ;   the music wanted: 0 the map, 1 the menu, 2 a fight, 3 the 3D fight, 4 none,
                                ;   5 a fight's, once its field is shown (ui_mouse_u)
MUS_PV  equ #3DF5               ;   the music's page (port value)
FADE    equ #3DF8               ;   the music's attenuation 0..15 (the fade: MUS_TICK, the player's ATTN)
PL_USE  equ #3DF9               ;   1: this fight's field from the colour plane (xtil.asm)
LD_ON   equ #3DFA               ;   1: a location loading (uipage.asm ld_beg .. wideu.asm outd_u): the screen black,
                                ;   "Loading...", no conversion, no cursor
BC_CMP  equ #3DFB               ;   a fight's state B: screen 7's cells of this attribute kept (state A's field under a
                                ;   popup): FW_C from state A (ld_end), #FF once the fighter's screen is drawn (ico.asm)
FW_C    equ #3DF7               ;   the fight's field attribute (the game's COLOR, wideu.asm)
MO_RT   equ #3DEA               ;   (2) the game's poll: CONTR's caller (ui_mouse_u; x_hot: BMOV's only)
; (#3DEC: scr.asm agef)
POLLN   equ #3DED               ;   the game's polls (uimouse.asm ui_mouse_u: +1 each)
PM_REL  equ #3DEF               ;   1: the buttons seen released (uimouse.asm ui_mouse_u; build/mods.py SELPM: - / + held)
fm_w3   equ #3DEE               ;   (field.asm fmark) W3V at its start: obj.asm ob_ex puts it back
HK_L1   equ #3DF6               ;   the fight's quick keys pressed since the last poll: 1..4 (bits 0..3; xpg.asm x_hot)
HK_L2   equ #3DFF               ;   Q W E R T (bits 0..4)
BPOP    equ #3DFC               ;   1: state B as a popup over state A (mx.asm wn_det): only screen 7's rows WN_R0..WN_R1
WN_R0   equ #3DFD               ;   (1..16) converted, their cells but the field's and columns 0, 29..31; state A's
WN_R1   equ #3DFE               ;   panels, palette stay

mus_img
        DISP #C000
MUS_TICK
        ex af,af' : push af : ex af,af'         ; (the player uses AF')
        ; the wanted: B = its m_cur value (0: none), HL -> its trk_tab row
        ld b,0
        ld a,(MUS_OFF) : or a : jr nz,1F
        ld a,(MUS_TRK) : cp 4 : jr nc,1F
        ld c,a : add a,a : add a,a : add a,c : ld e,a : ld d,0 : ld hl,trk_tab : add hl,de
        inc hl : ld a,(m_have) : and (hl) : dec hl : jr z,1F
        ld b,c : inc b
1       ld a,(m_cur) : or a : jr z,2F
        cp b : jr nz,.fout                      ; this page plays another (or the wanted is elsewhere): out first
        ld a,(hl) : push hl : ld hl,m_pg : cp (hl) : pop hl : jr nz,.fout
        jr .play
.fout   ld a,(FADE) : add a,2 : cp 15 : jr c,3F
        call .mone : jr .x                      ; faded out: silent (m_cur 0)
3       ld (FADE),a : call pt3.PLAY : jr .x
2       ld a,b : or a : jr z,.mute              ; nothing wanted
        ld a,(hl) : ld c,a : ld a,(m_pg) : cp c : jr z,.mine
        ld a,#7F : sub c : ld (MUS_PV),a        ; the other page has it: from the next interrupt
        call .mone : jr .x
.mine   ld a,b : ld (m_cur),a
        inc hl : inc hl : ld e,(hl) : inc hl : ld d,(hl) : ex de,hl : call pt3.INIT    ; (FADE 15: in from silence)
.play   xor a : ld (m_mute),a
        ld a,(FADE) : or a : jr z,4F : dec a : ld (FADE),a      ; fading in
4       call pt3.PLAY : jr .x
.mute   call .mone
.x      ex af,af' : pop af : ex af,af' : ret
.mone   ld a,15 : ld (FADE),a
        ld a,(m_mute) : or a : ret nz
        inc a : ld (m_mute),a : xor a : ld (m_cur),a : jp pt3.MUTE
trk_tab db MUSPA, 1 : dw M_S0 : db 0            ; the map
        db MUSPA, 2 : dw M_S1 : db 0            ; the menu
        db MUSPA, 4 : dw M_S2 : db 0            ; a fight
        db MUSPB, 8 : dw M_S1 : db 0            ; the 3D fight
; from int_f (W0, a fight / the 3D fight; this page in W3, SP = int_f's nest with BC, AF): on its own stack here
; (the game's may be anywhere: at BATRET it is #4034 down to the module table at #4000 - deep pushes there broke the
; geoscape's modules); the game at one of its two HALTs (E_I's, DELAY's): no music here, int_h does it all (int_y);
; else the music (int_x). Both put W3 back (W3V) in W0 and leave from there.
MSTK    equ #FFF0                       ; (both music pages: free past their modules)
MUS_F   ld sp,MSTK
        push de : push hl : push ix : push iy
        exx : push bc : push de : push hl : exx
        ld hl,(if_sp) : ld e,(hl) : inc hl : ld d,(hl)          ; the interrupted PC
        ld hl,G_EIDI : or a : sbc hl,de : jr z,3F       ; the game's two HALTs only: a byte #76 before PC elsewhere
        ld hl,G_DLDI : or a : sbc hl,de : jr nz,1F      ; (an operand) is no HALT
3       dec de : ld a,(de) : cp #76 : jr nz,1F          ; (and its HALT there: our code at that address in another
        ld hl,int_y : jr 2F                             ; page - PL_SPR's at G_DLDI #409D - is not the game's)
1       ld hl,ifr : inc (hl)                    ; (a frame for x_kb: int_h counts its own)
        ld a,(ega) : or a : jr z,4F             ; (the geoscape: a click while a conversion runs latched too - scr.asm
        ld bc,#FADF : in a,(c) : cpl : and 7 : ld c,a : ld a,(oldbtn) : cpl : and c : ld hl,btn_l : or (hl) : ld (hl),a   ;  conv_step's)
4       call MUS_TICK
        ld hl,int_x
2       ld (f_jp+1),hl
        exx : pop hl : pop de : pop bc : exx
        pop iy : pop ix : pop hl : pop de
        ld sp,if_nest-4
        ld a,(W3V) : ld bc,P_W3
f_jp    jp 0
; while loading: from CP/M's IM2 vector
LD_INT  ld (ld_sp),sp : ld sp,LSTK
        push af : push bc : push de : push hl : push ix : push iy : ex af,af' : push af : exx : push bc : push de : push hl
        call pt3.PLAY
        pop hl : pop de : pop bc : exx : pop af : ex af,af' : pop iy : pop ix : pop hl : pop de : pop bc : pop af
        ld sp,(ld_sp)
ld_jp   jp 0                                    ; CP/M's handler
ld_sp   dw 0
m_pg    db 0                                    ; this page (MUSPA / MUSPB)
m_have  db 0                                    ; the modules there: bits as trk_tab's
m_cur   db 0                                    ; the track set up + 1
m_mute  db 0
m_ldf   db 0                                    ; the intro's fade (t_wait); then FADE in W0
        MODULE pt3
        include "pt3/pt3raw.asm"
        ENDMODULE
mus_cend
        ASSERT mus_cend <= M_S0
        display "music code end ", mus_cend
        ENT
mus_img_end

; ---- window 0's page zero (not in the COM: low_out puts them there at the start)
        IFDEF NEDOOS
LOWA    equ #3E94                               ; (past the arrays bsync..dlin; installed at the start's end)
        ELSE
LOWA    equ #0008
        ENDIF
lowa_img
        DISP LOWA
; a fight's / the 3D fight's interrupt (IM2 #3D3D -> here): the music only (W3 = its page, back from W3V); in the
; game's HALT on to int_h
int_f   ld (if_sp),sp : ld sp,if_nest       ; (the game's stack untouched past the CPU's own push)
        push af : push bc
        ld bc,P_W3 : ld a,(MUS_PV) : out (c),a
        jp MUS_F                                ; (back at int_x / int_y: A, BC = W3's port)
int_x   out (c),a : pop bc : pop af : ld sp,(if_sp) : ei : reti
int_y   out (c),a : pop bc : pop af : ld sp,(if_sp) : jp int_h
if_sp   dw 0
        ds 4
if_nest
        IFDEF NEDOOS                            ; (NedoOS: page zero's #0080.. is the chain's - mus_geo here)
mus_geo push hl : ld hl,int_f : ld (#3D3E),hl : pop hl
        xor a : ld (MUS_TRK),a : ld (G_EIDI),a : ld (G_DLDI),a : ei : ret
        ENDIF
lowa_end
        IFDEF NEDOOS
        ASSERT lowa_end <= N_ISTK-16            ; (nedo.asm on_int's stack past it)
        ELSE
        ASSERT lowa_end <= #0040              ; (#0038: im_det's, at the start only, before low_out)
        ENDIF
        ENT
lowa_img_end
        IFDEF NEDOOS
LOWB    equ #00EE                               ; (#0080..#00ED: nedo.asm's chain)
        ELSE
LOWB    equ #00D4
        ENDIF
lowb_img
        DISP LOWB
; A = ZX bank / page -> window 3 (W3V: its port value)
map_w3  call bk_pg
map_w3p push bc : ld b,a : ld a,#7F : sub b
w3_v    ld (W3V),a : ld bc,P_W3 : out (c),a : pop bc : ret      ; (A = the port value, BC pushed: obj.asm ob_ex)
; the geoscape (LAY_GEO): int_f too (interrupts on as in the fights: the music's ticks; int_h at the game's HALTs)
        IFNDEF NEDOOS
mus_geo push hl : ld hl,int_f : ld (#3D3E),hl : pop hl
        xor a : ld (MUS_TRK),a : ld (G_EIDI),a : ld (G_DLDI),a : ei : ret
        ENDIF
lowb_end
        ASSERT lowb_end <= #0100
        ENT
lowb_img_end
low_out
        IFNDEF NEDOOS
        ld hl,lowa_img : ld de,LOWA : ld bc,lowa_img_end-lowa_img : ldir
        ENDIF
        ld hl,lowb_img : ld de,LOWB : ld bc,lowb_img_end-lowb_img : ldir : ret

; ---- the start: the player -> page 3 (W3), INTRO.PT3 -> S0, CP/M's vector -> LD_INT
f_intro db "INTRO   PT3"
f_map   db "WORLDMAPPT3"
f_earth db "EARTH   PT3"
f_sea   db "UNDERWATPT3"
f_icpt  db "INTERCPTPT3"
mus_hk  db 0
; HL -> CP/M's IM2 vector (its I * 256 + #FF); NedoOS: the chain's (nedo.asm n_vec)
        MACRO CPMV
        IFDEF NEDOOS
        ld hl,n_vec
        ELSE
        ld a,(cpm_i) : ld h,a : ld l,#FF
        ENDIF
        ENDM
mfcb    ds 36
mus_ld  ld hl,mus_img : ld de,#C000 : ld bc,mus_img_end-mus_img : ldir
        ld a,(cpm_im1) : or a : ret nz          ; (CP/M in IM 1: no vector to hook)
        ld hl,f_intro : ld de,M_INTRO : ld b,32 : call mf_rd : ret nc
        ld hl,M_INTRO : call pt3.INIT
        ld a,1 : ld (mus_rd),a : ret            ; (played from PRESS ANY KEY on: mus_hk)
mus_rd  db 0
; the intro on: CP/M's IM2 vector -> LD_INT (t_wait)
mus_hok ld a,(mus_rd) : or a : ret z
        ld a,(mus_hk) : or a : ret nz           ; (on already: the start's menu)
        di
        CPMV
        ld e,(hl) : inc hl : ld d,(hl) : ld (ld_jp+1),de
        ld de,LD_INT : ld (hl),d : dec hl : ld (hl),e
        ld a,1 : ld (mus_hk),a
        ei : ret
; the intro off again (the start's menu left: the loading goes on - t_wait puts it on again)
mus_unh ld a,(mus_hk) : or a : ret z
        di : CPMV : ld de,(ld_jp+1) : ld (hl),e : inc hl : ld (hl),d
        xor a : ld (mus_hk),a : ei : jp pt3.MUTE
; the end of the loading: CP/M's vector back; page MUSPA: the image + WORLDMAP / EARTH / UNDERWAT (S0..S2),
; page MUSPB: the image (+ the intro in S0) + INTERCPT (S1)
mus_go  di
        ld hl,FADE : ld (pt3.ATTNV+1),hl        ; (the image copied below: the game's fade)
        ld a,(mus_hk) : or a : jr z,1F
        CPMV : ld de,(ld_jp+1) : ld (hl),e : inc hl : ld (hl),d
        xor a : ld (mus_hk),a
1       ei : call pt3.MUTE
        xor a : ld (m_cur),a : ld (m_mute),a
        ld hl,f_map : ld de,STAGE : ld b,32 : call mf_rd : ld a,0 : rla : ld c,a
        push bc : ld hl,f_earth : ld de,STAGE+#1000 : ld b,32 : call mf_rd : pop bc : jr nc,2F : set 1,c
2       push bc : ld hl,f_sea : ld de,STAGE+#2000 : ld b,36 : call mf_rd : pop bc : jr nc,3F : set 2,c
3       push bc : ld hl,f_icpt : ld de,STAGE+#3200 : ld b,28 : call mf_rd : pop bc : jr nc,4F : set 3,c
4       ld a,c : ld (m_have),a
        ld a,MUSPA : ld (m_pg),a
        di
        ld a,MUSPA : call map_w2
        ld hl,#C000 : ld de,#8000 : ld bc,M_S0-#C000 : ldir                ; the player
        ld hl,STAGE : ld de,#8000+M_S0-#C000 : ld bc,#3200 : ldir          ; S0, S1 (4K), S2 (4.5K)
        ld a,2 : call map_w2 : ei
        ld a,MUSPB : ld (m_pg),a
        di
        ld a,MUSPB : call map_w2
        ld hl,#C000 : ld de,#8000 : ld bc,M_S1-#C000 : ldir                ; the player, the intro
        ld hl,STAGE+#3200 : ld de,#8000+M_S1-#C000 : ld bc,#E00 : ldir     ; S1 (the 3D fight's: 3.5K at most)
        ld a,2 : call map_w2 : ei : ret
; HL = the file's name (11), DE = where, B = records at most -> CY: read (something)
mf_rd   push de : push bc
        ld de,mfcb+1 : ld bc,11 : ldir
        ld hl,mfcb+12 : ld b,24
1       ld (hl),0 : inc hl : djnz 1B
        ld a,(dfcb) : ld (mfcb),a
        ld de,mfcb : ld c,15 : call BDOS
        pop bc : pop de : inc a : jr nz,2F
        or a : ret                              ; (no file: NC)
mf_more                                         ; (DE, B: the same file's next records)
2       push bc : push de : ld c,26 : call BDOS
        ld de,mfcb : ld c,20 : call BDOS
        pop de : pop bc : or a : jr nz,3F
        ld hl,128 : add hl,de : ex de,hl : djnz 2B
3       scf : ret
