; ------------------------------------------------------------------ geoscape in EGA 320x200: picture + service panel
; On the geoscape (the game calls LAY_GEO from MLOOP) the screen is the EGA view: the ZX picture at x 0..255,
; y 4..195, the service panel at x 256..319 always visible. The fights (LAY_ZXM from SEABAT / BATTL1) run in the
; ATM's ZX screen mode. In the EGA view the game's arrow is not drawn (ARROW returns at once): our own cursor
; sprite (save-under, drawn at the interrupt) shows the mouse; it moves on into the panel past the picture's edge.
; Panel buttons:
;   3D GO   - start the underwater 3D fight now (BATTLE; after a won fight - the question and the location)
;   LOC GO  - start the location battle now (BATTL1)
;   3D ON / 3D OFF - 3D fight at an interception on / off (off: ALEX returns A = 1, CY at once = "UFO damaged")
;   LAZY    - everything researched, money, stores, 10 strong aquanauts (the test mode)
; While our cursor is in the panel the game gets no mouse buttons. A start is done at the next interrupt that comes
; while the game waits in its HALT routine with the geoscape module (XLIC) in memory: the return address is replaced
; by a trampoline (SP = #403E as MLOOP does, bank 7; with no target: T_TYPE = 0, UFO and interceptor types 0).

BT_Y0   equ 8                   ; buttons: y = BT_Y0 + n*BT_STEP, height BT_H (a line of colour, the text, a line), x BT_X..+39
BT_STEP equ 10
BT_H    equ 9
NBT     equ 4
BT_X    equ 268
XMAX    equ 316                 ; our cursor x 2..XMAX (game's x = min(x, #FC))

svc     db 0                    ; 1: our cursor in the panel (x >= 256)
free    db 0                    ; 1: our cursor not where the game's one is (the panel, or outside the game's window)
scx     dw 2                    ; our cursor x (screen)
scy     db 100                  ; our cursor y (screen)
lastx   db 0                    ; the game's cursor as we left it (another value: the game moved it)
lasty   db 0
m_dxy
m_dx    db 0
m_dy    db 0
oldbtn  db 0
pn_ovr  db 0                    ; (wide, A) the cursor over a panel / a tab / the name: our arrow
m_eat   db 0                    ; buttons pressed on our zone (a tab...): kept from the game till released
btn_l   db 0                    ; buttons pressed since the last poll (latched by conv_step)
ui_red  db 1                    ; redraw the panel
pend    db 0                    ; 1 = 3D, 2 = location: start wanted
pend_t  db 0
d3off   db 0                    ; 1: the 3D fight is skipped (ALEX returns "UFO damaged" at once)

        IFNDEF SRCB
; check and hook the game's mouse routine (bank 5 mapped)
hook_mouse
        ld hl,G_MOUSE : ld de,mo_pat : ld b,6
1       ld a,(de) : cp (hl) : ret nz
        inc hl : inc de : djnz 1B
        ld a,#C3 : ld (G_MOUSE),a : ld hl,ui_mouse : ld (G_MOUSE+1),hl : ret
mo_pat  db #2A : dw G_COORD : db #01,#DF,#FB
        ENDIF

; the game's mouse routine (called from the game's code, the game's windows): the work in UPG (ui_mouse_u)
ui_mouse
        ld a,(infight) : or a : jr z,0F         ; the fight (interrupts off): no OUTDSC for 64 polls -> convert
        ld a,(od_cnt) : inc a : ld (od_cnt),a : cp 64 : call nc,od_conv
0       ld a,(d_dirty) : or a : jr z,1F : ld a,(bwide) : or a : call z,d_chk     ; (a saved game: to the disk)
1       ld hl,ui_mouse_u : jp far_g             ; (HL: the game's CONTR keeps its registers)
; HL = a routine in MPG's MX (mx.asm) / XPG (from UPG's code: back with W3 = UPG)
far_t   push af : ld a,TXPG : jr 0F                 ; (textc.asm tx_rec)
far_m   push af : ld a,MPG : jr 0F
far_x   push af : ld a,XPG
0       call map_w3p : pop af
        call 1F
        push af : ld a,UPG : call map_w3p : pop af : ret
1       jp (hl)

; interrupt, game's windows: a wanted start, if the game waits in its HALT with the geoscape module present
ui_int  ld a,(MUS_PV) : ld bc,P_W3 : out (c),a : call MUS_TICK     ; the music (mus.asm)
        ld a,UPG : call map_w3p : call ui_int_u : ld a,(cur) : jp map_w3


; ---- drawing (screen mapped: W1 = page 1, W2 = page 5)
; layout of a line (40 bytes in each of 4 parts): pair p (pixels 2p, 2p+1) is byte p>>2 of part p&3;
; parts: 0 = page 1 +0, 1 = page 5 +0, 2 = page 1 +#2000, 3 = page 5 +#2000; left pixel bits #47, right #B8
y_off   dw 0
; A = y -> (y_off) = y*40
yoff    push hl : push de
        ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        ld (y_off),hl : pop de : pop hl : ret
; A = pair (0..159) -> HL = its byte on line (y_off)
paddr   push de
        ld e,a : srl e : srl e : ld d,0 : ld hl,(y_off) : add hl,de
        and 3 : ld e,a : ld d,0 : push hl : ld hl,pbase : add hl,de : ld a,(hl) : pop hl
        add a,h : ld h,a : pop de : ret
pbase   db #40,#80,#60,#A0
; ---- our cursor: a sprite with the picture under it saved (screen mapped)
CS_W    equ 8
CS_H    equ 11
ct_x    dw 0                    ; where it should be
ct_y    db 0
cs_md   db 0
cs_mode db 0                    ; our cursor's kind (shift2.asm)
; the cursor of the front (shown) buffer; brec: the same of the back buffer (swapped at a flip)
cs_on   equ #3D40                   ; drawn at (cs_x, cs_y)
cs_x    equ #3D41
cs_y    equ #3D43
cs_p0   equ #3D44
cs_buf  equ #3D45                   ; (CS_H * 5)
CSREC   equ 5+CS_H*5
brec    equ cs_on+CSREC             ; (to #3DB8)
; swap the cursor records
swaprec push hl : push de : push bc
        ld hl,cs_on : ld de,brec : ld b,CSREC
1       ld a,(de) : ld c,(hl) : ld (hl),a : ld a,c : ld (de),a : inc hl : inc de : djnz 1B
        pop bc : pop de : pop hl : ret
; the back buffer's cursor off / on (the back buffer stays mapped)
bcur_hide
        call swaprec : call map_back : call cur_hide : jr swaprec
bcur_show
        call swaprec : call map_back : call cur_show : jr swaprec
; the front's cursor off if it has to move (cur_show puts it on again)
cur_move
        ld hl,(cs_x) : ld de,(ct_x) : or a : sbc hl,de : jr nz,cur_hide
        ld a,(cs_y) : ld hl,ct_y : cp (hl) : jr nz,cur_hide
        ld a,(cs_mode) : inc a : ld hl,cs_on : cp (hl) : ret z  ; (cs_on = the kind drawn + 1)
        jr cur_hide
; the game's windows: target position (and kind: cs_mode)
cur_tgt ld hl,cur_tgt_u : jp far_ui
infight db 0
cur_hide
        ld a,(cs_on) : or a : ret z
        xor a : ld (cs_md),a                    ; (cs_on: cursor.asm .fr clears it - the kind drawn there till then)
        jr cs_io
cur_show
        ld a,(cs_on) : or a : ret nz
        ld a,(ct_y) : inc a : ret z
        ld hl,(ct_x) : ld (cs_x),hl : ld a,(ct_y) : ld (cs_y),a
        ld a,1 : ld (cs_md),a : ld a,(cs_mode) : inc a : ld (cs_on),a
cs_io   push hl : ld hl,cs_iof : call far_ui : pop hl : ret


; the 3D fight's entry (ALEX #BCE6: LD HL,#C900 replaced by JP zx_alex)

; YES_NO (#5CAE, Z = yes): keys Y / N as the game, and the mouse: left = yes, right = no (after all buttons are up)
zx_yn   xor a : call kb_mode                                     ; (the keys as a ZX matrix: Y / N)
0       call yn_w                                                ; the question is on screen 7
        ld bc,#FADF : in a,(c) : cpl : and 3 : jr nz,0B          ; buttons still down
1       call yn_w
        ld bc,#DFFE : in a,(c) : and #10 : ret z                 ; Y
        ld b,#7F : in a,(c) : cpl : and 8 : ret nz               ; N
        ld bc,#FADF : in a,(c) : cpl : and 3 : jr z,1B
        ld e,a
2       in a,(c) : cpl : and 3 : jr nz,2B                       ; wait until released
        ld a,e : and 2 : ret                                     ; left: Z (yes), right: NZ (no)
; YES_NO's wait: a frame (the music's ticks, int_h at the HALT: the keyboard controller's ZX mode), then the screen
yn_w    ei : halt : jp conv_all
        IFNDEF SRCB
; hook YES_NO, if it is this version's
hook_yn ld hl,G_YN : ld de,yn_pat : ld b,10
1       ld a,(de) : cp (hl) : ret nz
        inc hl : inc de : djnz 1B
        ld a,#C3 : ld (G_YN),a : ld hl,zx_yn : ld (G_YN+1),hl : ret
yn_pat  db #01,#FE,#DF,#ED,#78,#E6,#10,#C8,#06,#7F
        ENDIF

mo_de   dw 0
pushc   db 0
; Z: the geoscape module (XLIC) is in memory (game's windows)

