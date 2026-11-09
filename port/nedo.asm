; ------------------------------------------------------------------ NedoOS (Evo BaseConf): the task's layer (-DNEDOOS)
; The CP/M port runs as it is, but:
; - pages: the kernel is asked for exactly the pages whose numbers the CP/M code writes (#7F - p: Evo's physical
;   128 + p) - so all its page arithmetic stays; the screens are the real ones: (#7F - p) | #80 for p = 1, 3, 5, 7
;   (SCRV); the windows' ports #x7F7 (P_W1..P_W3)
; - the kernel puts the windows back from curpg4000 / 8000 / C000 after each interrupt and call: on_int (the chain
;   at #0038) and n_bdos write them first from the windows' read back (Evo: ports #01BE..#03BE)
; - IM 1: on_int -> the kernel's handler -> n_cont -> (n_vec): CP/M's IM2 vector's place (LD_INT, then #3D3D)
; - #0000..#007F untouched (but #0038's 3 bytes: back at the exit); #0080..#00D3: n_sync, on_int, n_cont (nlow);
;   CP/M's page zero arrays bsync..dlin -> #3E00 (its IM2 table's place), int_f.. -> #3E94 (lowa)
; - BDOS: n_bdos in page 3 (#F000, CP/M's BDOS's place: the code calls it with W3 = page 3): FCB calls passed on,
;   9 / 2 printed (text mode), 6 = OS_GETKEY, 25 / 37 = 0
; - the files: padded to 128 bytes (as on CP/M: NedoOS's FREAD gives A = 128 XOR the bytes read)
NB_A    equ #F000                               ; n_bdos (page 3)
NB_STK  equ #FFF0                               ; the start's stack top (page 3)
NB_DSTK equ #FEF0                               ; ovl.asm d_cpm's stack (page 3: past nf_tab)
N_ISTK  equ #3F00                               ; on_int's stack (W0: past mus.asm's lowa; 10 bytes)

; ---- page zero's part (n_start puts it at #0080, after the command line is read)
nlow_img
        DISP #0080
; #0038: JP on_int (the kernel's 3 bytes there: PUSH AF, BC, DE - done here); first the windows #4000.. as they are
; now -> curpg4000 / 8000 / C000 (the kernel puts them back from there); its handler comes back to n_cont
on_int  ld (n_isp),sp
on_stk  ld sp,N_ISTK                                    ; (the game's stack: only the CPU's PC on it, as with CP/M's IM 2 -
        push af                                 ;  data lies right below it: the geoscape's modules at #4000..)
        ld a,1 : in a,(#BE) : ld (curpg4000),a
        ld a,2 : in a,(#BE) : ld (curpg8000),a
        ld a,3 : in a,(#BE) : ld (curpgc000),a
        call n_pnd                              ; (SHOWSCR's screen to the kernel first: it puts its #FD at the end;
        pop af                                  ;  the focus: n_spd3 - the pause)
        push hl
on_ret  ld hl,n_cont : ex (sp),hl               ; (the kernel's RET: n_cont - or the pause, n_pz3: n_spd3 sets it)
        push af : push bc : push de : jp #003B
n_cont  di : ld sp,(n_isp)                ; (as CP/M's IM2: interrupts off, only the PC pushed - nothing more on
        db #C3                                  ;  the game's stack: its fights keep data right below SP)
n_vec   dw n_iret                               ; (JP's operand: the vector)
n_isp   dw 0
n_iret  ei : ret
n_spend db 0                                    ; SHOWSCR's #FD value (fd_user | screen * 8) not yet given the kernel
n_pnd   push hl : ld hl,n_spd3 : call n_p3 : pop hl : ret
; HL = a routine in page 3 (nb_img: the kernel's calls), A its argument: called with W3 = page 3, W3 back after
; (its value read back, kept on the stack: from on_int too); the routine's AF kept
n_p3    push bc
        ld c,a                                  ; (the argument)
        ld a,3 : in a,(#BE) : ld b,a : push bc
        ld bc,P_W3 : ld a,#7F-3 : out (c),a
        pop bc : push bc : ld a,c
        call 1F
n_p3t   pop bc
        push af : ld a,b : ld bc,P_W3 : out (c),a : pop af
        pop bc : ret
1       jp (hl)
nlow_end
        ASSERT nlow_end <= LOWB
        ENT
nlow_img_end

; ---- the start (in the COM past init_end; once): the pages, the windows, the chain; then CP/M's start
n_start di
        ld sp,NB_STK                            ; (NedoOS: SP = 0 - page 3's top; the COM's images below #3F00 stay)
        ; the command line (ASCIIZ: "ufo2 args") -> n_cl as CP/M's (length, the arguments)
        ld hl,COMMANDLINE : ld de,n_cl+1 : ld c,0
1       ld a,(hl) : or a : jr z,4F : cp ' ' : jr z,2F : inc hl : jr 1B    ; (the program's name)
2       ld a,(hl) : or a : jr z,4F : ld (de),a : inc hl : inc de : inc c : ld a,c : cp 126 : jr c,2B
4       xor a : ld (de),a : ld a,c : ld (n_cl),a
        ld hl,nb_img : ld de,NB_A : ld bc,nb_img_end-nb_img : ldir             ; (W3: carried into page 3 below)
        call n_cdir                                                             ; (from the command line: before nlow)
        ld hl,nlow_img : ld de,#0080 : ld bc,nlow_img_end-nlow_img : ldir      ; (the command line read: its place)
        ld hl,nf_tab : ld de,nf_tab+1 : ld bc,NF_N*38-1 : ld (hl),0 : ldir
        call n_alloc                            ; (the pages: nb_img's - the COM's tail is short)
        ; the windows' contents (the COM, the stack) -> pages 4, 2, 3 (#7B, #7D, #7C); then those in the windows
        ld bc,P_W3 : ld a,#7F-4 : out (c),a     ; (no stack here: W3 is its page)
        ld hl,#4000 : ld de,#C000 : ld bc,#4000 : ldir
        ld bc,P_W3 : ld a,(n_mp+3) : out (c),a
        ld bc,P_W1 : ld a,#7F-3 : out (c),a
        ld hl,#C000 : ld de,#4000 : ld bc,#4000 : ldir
        ld bc,P_W1 : ld a,#7F-2 : out (c),a
        ld hl,#8000 : ld de,#4000 : ld bc,#4000 : ldir
        ld a,#7F-4 : ld (curpg4000),a : ld bc,P_W1 : out (c),a
        ld a,#7F-2 : ld (curpg8000),a : ld bc,P_W2 : out (c),a     ; (this code: the same bytes there)
        ld a,#7F-3 : ld (curpgc000),a : ld bc,P_W3 : out (c),a
        ld hl,n_mp+1 : ld b,3
5       ld e,(hl) : inc hl : push hl : push bc : NOS CMD_DELPAGE : pop bc : pop hl : djnz 5B
        di
        ; #0038 -> on_int
        ld hl,#0038 : ld de,n_o38 : ld bc,3 : ldir
        ld a,#C3 : ld (#0038),a : ld hl,on_int : ld (#0039),hl
        jp start_n                              ; (interrupts off: till the images are out - img_out; on_int's stack
                                                ;  is in their place)                              ; CP/M's start
n_dpath equ #F800                               ; (the start's only: W3's page then - #F800.. free in it; n_doc's
                                                ;  BIOS table there later)
n_mp    ds 4                                    ; the kernel's pages at the start (#0000, #4000, #8000, #C000)
n_code_end                                      ; (n_mp: here - read while W3 is another page)
; ---- page 3's part (#F000): BDOS, the messages, the exit
nb_img
        DISP NB_A
; BDOS (CP/M's numbers): C = function, DE; out: A = L, H = 0. The others' registers (IX, IY, the alternate set) kept
n_bdos  ld a,c
        cp 9 : jp z,n_pr9
        cp 2 : jp z,n_pr2
        cp 6 : jp z,n_in6
        cp 25 : jr z,.zero
        cp 37 : jr z,.zero
        push ix : push iy : exx : push bc : push de : push hl : exx : ex af,af' : push af : ex af,af'
        ld a,c : cp 15 : jr z,.open : cp 22 : jr z,.open : cp 16 : jr z,.close
        call n_sync : call 5
.ret    ex af,af' : pop af : ex af,af' : exx : pop hl : pop de : pop bc : exx : pop iy : pop ix
        ld l,a : ld h,0 : ret
.zero   xor a : ld l,a : ld h,a : ret
; open / make (CP/M doesn't close files read - NedoOS keeps a FatFs object for each open FCB, 8 at most, and QUIT
; doesn't give them back): the same FCB's former file closed first (its copy kept at its open), the new one's copy kept
.open   push bc : push de : call nf_find : call nc,nf_cls : pop de : pop bc
        push de : call n_sync : call 5 : pop de
        push af : inc a : jr z,1F                       ; (not opened)
        call nf_find : jr nc,2F                         ; (its entry: the one closed above)
        call nf_free : jr c,1F                          ; (no free entry: not kept)
2       ld (hl),e : inc hl : ld (hl),d : inc hl : ex de,hl : ld bc,36 : ldir
1       pop af : jr .ret
.close  push de : call n_sync : call 5 : pop de
        push af : call nf_find : jr c,1F : dec hl : ld (hl),0 : dec hl : ld (hl),0
1       pop af : jr .ret
; DE = FCB -> HL = its entry's copy (CY: none)
nf_find ld hl,nf_tab : ld b,NF_N
1       ld a,(hl) : cp e : inc hl : jr nz,2F : ld a,(hl) : cp d : jr nz,2F
        inc hl : or a : ret
2       push de : ld de,37 : add hl,de : pop de : djnz 1B
        scf : ret
; -> HL = a free entry (CY: none)
nf_free ld hl,nf_tab : ld b,NF_N
1       ld a,(hl) : inc hl : or (hl) : dec hl : ret z
        push de : ld de,38 : add hl,de : pop de : djnz 1B
        scf : ret
; HL = an entry's copy: that file closed, the entry free
nf_cls  ex de,hl : push de : ld c,16 : call n_sync : call 5 : pop hl
        dec hl : ld (hl),0 : dec hl : ld (hl),0 : ret
NF_N    equ 10
nf_tab  equ NB_A+#A00                           ; (NF_N x 38: the FCB's address, its copy at its open: 36 bytes;
                                                ;  not in the COM - cleared at the start)
; 9: the string DE.."$" (ESC first: CP/M's ESC M0 - the EGA screen now)
n_pr9   ld a,(de) : cp 27 : jp z,n_ega
1       ld a,(de) : cp '$' : ret z
        push de : call n_ch : pop de : inc de : jr 1B
n_pr2   ld a,e
; A -> the text screen (taken first; not once the EGA screen is ours)
n_ch    push af : ld a,(n_txt) : cp 2 : jr z,9F : or a : call z,n_text
        pop af
        push ix : push iy : exx : push bc : push de : push hl : exx : ex af,af' : push af : ex af,af'
        call n_sync : NPRCHAR
        ex af,af' : pop af : ex af,af' : exx : pop hl : pop de : pop bc : exx : pop iy : pop ix : ret
9       pop af : ret
n_text  ld a,1 : ld (n_txt),a
        ld e,6 : call n_os : ld e,7 : ld c,CMD_CLS : jp n_os1
; 6 (E = #FF): a key or 0
n_in6   push ix : push iy : exx : push bc : push de : push hl : exx : ex af,af' : push af : ex af,af'
        call n_sync : NGETKEY : jr z,1F : xor a           ; (NZ: no focus)
1       cp key_redraw : jr nz,2F : xor a
2       ex af,af' : pop af : ex af,af' : exx : pop hl : pop de : pop bc : exx : pop iy : pop ix
        ld l,a : ld h,0 : ret
; E -> OS_SETGFX; n_os1: C = function (registers but SP spoilt; the windows synced)
n_os    ld c,CMD_SETGFX
n_os1   push ix : push iy : exx : push bc : push de : push hl : exx : ex af,af' : push af : ex af,af'
        call n_sync : call 5
        ex af,af' : pop af : ex af,af' : exx : pop hl : pop de : pop bc : exx : pop iy : pop ix : ret
; the EGA screen: 320x200, its pages kept (+#80), the palette (CP/M's ESC M0's), screen 0 shown
; the windows #4000.. as they are now -> curpg4000 / 8000 / C000 (AF kept): before each call of the kernel
n_sync  push af
        ld a,1 : in a,(#BE) : ld (curpg4000),a
        ld a,2 : in a,(#BE) : ld (curpg8000),a
        ld a,3 : in a,(#BE) : ld (curpgc000),a
        pop af : ret
n_ega   ld a,2 : ld (n_txt),a
        xor a : ld (n_gm),a
        ld e,#80 : call n_os
        ld de,n_pal : ld c,CMD_SETPAL : call n_os1
        ld e,0 : ld c,CMD_SETSCREEN : jp n_os1
n_txt   db 0                                    ; 0: no screen of ours, 1: text, 2: EGA
; (n_p3) A = #FD77's value (VM_EGA / VM_ZX / VM_TXT) -> OS_SETGFX, when it changes (+#80: the screen's pages kept)
n_vm3   push af : push bc : push de : push hl
        and 7 : ld hl,n_gm : cp (hl) : jr z,1F
        ld (hl),a : cp 6 : jr z,2F : or #80
2       ld e,a : call n_os
1       pop hl : pop de : pop bc : pop af : ret
n_gm    db #FF                                  ; the mode set (#FF: none yet)
; (n_p3 from on_int, each interrupt: the windows' pages in curpg4000.. already) n_spend -> OS_SETSCREEN; the focus
; (user_scr0_low: #FE, the screen's page, ours - else the kernel's copy of it: another task's screen shown, its
; pages ours now - disablescrpgs_setc000) lost: the game paused - n_pzf; its interrupt's state kept: the stack (only
; the PC on it), the registers; W3 -> page 3, the kernel's RET -> n_pz3 (a HALT loop: its own stack, the interrupts
; through n_iret); the focus back: the palette (n_pal: the game's last, pal_hk) to the kernel, the game's W3, stack,
; n_vec back, the kernel's RET -> n_cont (the game's handler: as after the interrupt). Not while d_cpm (n_vec =
; n_iret: the kernel writes) or before the game's handler. DE kept (AF, BC, HL: n_pnd, n_p3)
n_spd3  ld hl,n_icnt : inc (hl)                 ; (the interrupts we got: a count)
        IFDEF NTIMDBG
        ld (n_tsp),sp : ld sp,NB_STK-#40
        push af : push bc : push de : push ix : push iy : exx : push bc : push de : push hl : exx : ex af,af' : push af : ex af,af'
        ld a,(curpgc000) : push af
        ld c,CMD_GETTIMER : call n_sync : call 5
        ld a,(n_tlast) : ld b,a : ld a,l : ld (n_tlast),a : sub b : dec a : ld hl,n_tlost : add a,(hl) : ld (hl),a
        pop af : ld (curpgc000),a
        ex af,af' : pop af : ex af,af' : exx : pop hl : pop de : pop bc : exx : pop iy : pop ix : pop de : pop bc : pop af
        ld sp,(n_tsp)
        ENDIF
        ld a,(n_pzf) : or a : jr nz,.pz
        ld a,(n_spend) : or a : call nz,.scr
        ld a,(curpgc000) : ld (n_gw3),a : ld a,#7F-3 : ld (curpgc000),a  ; (the kernel's RET -> n_post: W3 = page 3)
        ld hl,n_post : ld (on_ret+1),hl : ret
.pz     ld hl,n_cont : ld (on_ret+1),hl
        call n_foc : ret nz                     ; (paused, no focus yet)
        ld hl,(n_isp) : ld a,(hl) : inc hl : ld h,(hl) : ld l,a : push de : ld de,-n_pzh : add hl,de : pop de
        ld a,h : or a : ret nz : ld a,l : cp 3 : ret nc         ; (not in n_pzh's HALT: the next interrupt)
        ld (n_s3sp),sp : ld sp,NB_STK-#40
        call .push
        ld de,n_pal : ld c,CMD_SETPAL : call n_sync : call 5
        xor a : ld (n_pzf),a
        ld hl,(n_zvec) : ld (n_vec),hl
        ld hl,(n_zisp) : ld (n_isp),hl
        ld a,(n_zw3) : ld (curpgc000),a
        jr .pop
; SHOWSCR's screen -> OS_SETSCREEN (its own stack)
.scr    ld (n_s3sp),sp : ld sp,NB_STK-#40
        call .push
        ld a,(curpgc000) : push af
        ld a,(n_spend) : and 8 : rrca : rrca : rrca : ld e,a : ld c,CMD_SETSCREEN
        call n_sync : call 5
        xor a : ld (n_spend),a
        pop af : ld (curpgc000),a
.pop    pop af : ex af,af' : exx : pop hl : pop de : pop bc : exx
        pop iy : pop ix : pop hl : pop de : pop bc : pop af
        ld sp,(n_s3sp) : ret
.push   ex (sp),hl : ld (.ret+1),hl : pop hl
        push af : push bc : push de : push hl : push ix : push iy
        exx : push bc : push de : push hl : exx : ex af,af' : push af
.ret    jp 0
; the kernel's RET here after each interrupt of ours (n_spd3: W3 = page 3; AF, BC, DE, HL - the game's; SP = on_int's
; stack): the focus lost (just now: the kernel's switch in this interrupt - not a frame of the game's drawing more on
; the other task's screen) - the pause (n_pz3); else W3 back (n_gw3) through n_p3's end, n_cont (the game's handler)
n_post  di
        push af : push hl
        call n_foc : jr z,.go
        ld hl,(n_vec) : ld a,l : cp low n_iret : jr nz,1F : ld a,h : cp high n_iret : jr z,.go
1       ld hl,(n_vec) : ld (n_zvec),hl : ld hl,n_iret : ld (n_vec),hl
        ld hl,(n_isp) : ld (n_zisp),hl
        ld a,(n_gw3) : ld (n_zw3),a
        ld a,1 : ld (n_pzf),a
        push bc
        ld bc,#FFFD : ld a,7 : out (c),a : ld b,#BF : ld a,#3F : out (c),a
        ld a,8 : ld bc,#FFFD : out (c),a : ld b,#BF : xor a : out (c),a
        ld a,9 : ld b,#FF : out (c),a : ld b,#BF : xor a : out (c),a
        ld a,10 : ld b,#FF : out (c),a : ld b,#BF : xor a : out (c),a
        pop bc
        pop hl : pop af : jp n_pz3
.go     pop hl : pop af
        push hl : ld hl,n_cont : ex (sp),hl
        push bc
        ld (n_sa),a : ld a,(n_gw3) : push af : ld a,(n_sa)     ; (B = the game's W3 at n_p3t's POP BC)
        jp n_p3t
n_gw3   db 0
n_sa    db 0
n_icnt  db 0
n_tlast db 0
n_tlost db 0
n_tsp   dw 0
; the pause: the kernel's RET here (W3 = page 3; AF, BC, DE, HL, IX, IY, the alternate set: the game's - kept)
; - OS_YIELD (no time of ours while another task has the focus) till the focus is back; then the registers (all
; but SP: the game's) in a HALT loop - n_spd3 goes on from its HALT only (the registers there: the game's)
n_pz3   di : ld sp,NB_DSTK
        push hl : ld hl,n_cont : ld (on_ret+1),hl : pop hl
        push af : push bc : push de : push hl : push ix : push iy
        exx : push bc : push de : push hl : exx : ex af,af' : push af : ex af,af'
1       ei : ld c,CMD_YIELD : call n_os1
        call n_foc : jr nz,1B
        di
        ex af,af' : pop af : ex af,af' : exx : pop hl : pop de : pop bc : exx
        pop iy : pop ix : pop hl : pop de : pop bc : pop af
n_pzh   ei : halt : jr n_pzh
; (n_p3: pal_hk, DI) DE = the 16 values the game puts into the palette (ATM's), A = its W3's page -> n_pal (as
; OS_SETPAL's: each byte twice); DE >= #C000: read through W2 (the page put there: no stack used meanwhile)
n_shw3  bit 7,d : jr z,1F : bit 6,d : jr z,1F
        res 6,d : ld (n_zpg),a : ld a,2 : in a,(#BE) : ld (n_zw2),a
        ld a,(n_zpg) : ld bc,P_W2 : out (c),a
1       ld hl,n_pal : ld b,16
2       ld a,(de) : ld (hl),a : inc hl : ld (hl),a : inc hl : inc de : djnz 2B
        ld a,(n_zw2) : or a : ret z             ; (W2 not changed)
        ld bc,P_W2 : out (c),a : xor a : ld (n_zw2),a : ret
n_zpg   db 0
n_zw2   db 0
; ---- the instruction / ABOUT.TXT (mnu.asm mm_doc, n_p3; the interrupts on): UFO2DOC.OVL (build/mkdocovl.py: ATM
; CP/M's UFO2DOC.COM - SEADOC - for NedoOS) at #0100..#10FF, in place of the game's code: W0 #0100..#3FFF kept in
; page DOC_WS, W1 / W2 its own pages (DOC_P1, DOC_P2: not loaded yet at the menu's time); its hook (mnu.asm dh_*,
; its way back sb_ret) at DH_A / SB_A as on CP/M; the BIOS it calls - a table at #F800 here (CONST, CONIN: OS_GETKEY;
; CONOUT: nothing - n_doc sets the 640x200 mode); the interrupts: on_int on #9FF0 (W0's #3F00 is its text now),
; n_vec = mnu.asm dm_ih (A <> 0: the menu's music plays on) or its EI : RET (#02F5) - the pause goes on. DE = the text's name (11 bytes, W2: the menu's page). Back (its
; ESC / end: sb_ret -> n_dret): its files closed, W0, W1, W2, n_vec back; A = 0: no UFO2DOC.OVL
DOC_WS  equ 44
DOC_P1  equ 45
DOC_P2  equ 46
n_doc   di
        ld (n_dsp),sp : ld sp,NB_DSTK
        ld hl,#02F5 : or a : jr z,1F : ld hl,DM_A               ; (A: the menu's music on - mnu.asm dm_ih)
1       ld (n_dih),hl
        ld (n_dtn),de : xor a : ld (n_dok),a
        ld a,1 : in a,(#BE) : ld (n_dw1),a
        ld a,2 : in a,(#BE) : ld (n_dw2),a
        ld hl,(n_vec) : ld (n_dvec),hl : ld hl,n_iret : ld (n_vec),hl
        ld bc,P_W1 : ld a,#7F-DOC_P2 : out (c),a                ; (W1: its W2's page - the hook, its stub)
        ld hl,dh_img : ld de,DH_A-#4000 : ld bc,DH_N : ldir
        ld hl,sb_img : ld de,SB_A-#4000 : ld bc,SB_N : ldir
        ld hl,dm_img : ld de,DM_A-#4000 : ld bc,DM_N : ldir     ; (the menu's music meanwhile: mnu.asm dm_ih)
        ld hl,(n_dtn) : ld de,sb_tn-#4000 : ld bc,11 : ldir
        ld a,(dfcb) : ld (sb_drv-#4000),a
        ld bc,P_W1 : ld a,#7F-DOC_WS : out (c),a                ; W0 kept
        ld hl,#0100 : ld de,#4100 : ld bc,#3F00 : ldir
        ld bc,P_W1 : ld a,#7F-DOC_P1 : out (c),a
        ld bc,P_W2 : ld a,#7F-DOC_P2 : out (c),a
        ld hl,#9FF0 : ld (on_stk+1),hl
        ld hl,n_dfcb+12 : ld b,24
1       ld (hl),0 : inc hl : djnz 1B
        ld de,n_dfcb : ld c,15 : call n_bdos : inc a : jp z,n_dbk     ; (no UFO2DOC.OVL)
        ld de,#0100
2       push de : ld c,26 : call n_bdos : ld de,n_dfcb : ld c,20 : call n_bdos : pop de
        or a : jr nz,3F
        ld hl,128 : add hl,de : ex de,hl : ld a,d : cp #11 : jr c,2B
3       ld de,n_dfcb : ld c,16 : call n_bdos
        ld a,1 : ld (n_dok),a
        ld hl,n_btab : ld de,#F800 : ld bc,n_btab_e-n_btab : ldir
        xor a : ld (n_dkb),a
        ld a,2 : call n_vm3                                     ; (640x200: ATM's 2 - OS_SETGFX's "MC")
        ld e,0 : ld c,CMD_SETSCREEN : call n_os1
        call dh_set
        ld hl,(n_dih) : ld (n_vec),hl
        ld sp,#9EF0 : ei : jp #0100
n_dret  di : ld sp,NB_DSTK
        ld de,#05EF : call n_dcl : ld de,#9E00 : call n_dcl : ld de,dh_fcb : call n_dcl
n_dbk   di
        ld bc,P_W1 : ld a,#7F-DOC_WS : out (c),a
        ld hl,#4100 : ld de,#0100 : ld bc,#3F00 : ldir
        ld a,(n_dw1) : ld bc,P_W1 : out (c),a
        ld a,(n_dw2) : ld bc,P_W2 : out (c),a
        ld hl,N_ISTK : ld (on_stk+1),hl
        ld hl,(n_dvec) : ld (n_vec),hl
        ld a,(n_dok) : ld sp,(n_dsp) : ret
n_dcl   call nf_find : ret c : jp nf_cls
; its BIOS (ATM CP/M's: WBOOT #F800 - (#0001) -, CONST, CONIN, CONOUT, .., #F812: as CONST)
n_btab  jp n_dret
        jp n_bcst
        jp n_bcin
        ret : nop : nop
        ret : nop : nop
        ret : nop : nop
        jp n_bcst
n_btab_e
n_bcst  ld a,(n_dkb) : or a : jr nz,1F
        ld e,#FF : ld c,6 : call n_bdos : ld (n_dkb),a : or a : ret z
1       ld a,#FF : or a : ret
n_bcin  call n_bcst : jr nz,1F
        ei : halt : jr n_bcin
1       ld a,(n_dkb) : push af : xor a : ld (n_dkb),a : pop af : ret
n_dfcb  db 0,"UFO2DOC OVL" : ds 24
n_dsp   dw 0
n_dtn   dw 0
n_dvec  dw 0
n_dw1   db 0
n_dw2   db 0
n_dok   db 0
n_dih   dw 0
n_dkb   db 0
; (n_start) the game's files: in the folder ufo2 next to UFO2.COM (the program's name's path + "ufo2"; none: as before -
        ; the current folder)
n_cdir  ld hl,COMMANDLINE : ld de,n_dpath : ld bc,n_dpath
1       ld a,(hl) : or a : jr z,2F : cp ' ' : jr z,2F
        ld (de),a : inc hl : inc de
        cp '/' : jr z,3F : cp #5C : jr z,3F : cp ':' : jr nz,1B
3       ld b,d : ld c,e : jr 1B                         ; (BC: past the path's last separator)
2       ld hl,n_dsub : ld d,b : ld e,c : ld bc,5 : ldir
        ld de,n_dpath : NOS CMD_CHDIR : ret
n_dsub  db "ufo2",0
; (n_start, from the COM's W3 page here) the pages: NEWPAGE till all of n_want are there; the others back (DELPAGE)
n_alloc
        NOS CMD_GETMAINPAGES : ld a,e : ld (n_mp+1),a : ld a,h : ld (n_mp+2),a : ld a,l : ld (n_mp+3),a
        ld hl,n_xtra : ld (n_xp),hl
.np     NOS CMD_NEWPAGE : or a : jr nz,.nmem
        ld a,e : cp #40 : jr c,.nx : cp #80 : jr nc,.nx
        ld c,a : ld a,#7F : sub c : ld c,a : ld b,0 : ld hl,n_want : add hl,bc  ; (#7F - page = the ATM page)
        ld a,(hl) : or a : jr z,.nx
        ld (hl),0
        ld hl,n_left : dec (hl) : jr nz,.np
        jr .ndone
.nx     ld hl,(n_xp) : ld (hl),e : inc hl : ld (n_xp),hl : jr .np
.nmem   call .free : ld de,m_nmem : call n_msg : jp n_fail
.ndone  jp .free
; DELPAGE the extra pages (n_xtra .. n_xp)
.free   ld hl,(n_xp) : ld de,n_xtra : or a : sbc hl,de : ret z
        add hl,de : dec hl : ld (n_xp),hl
        ld e,(hl) : NOS CMD_DELPAGE : jr .free
; Z: the focus ours (or no EGA screen yet: user_scr0_low = pgkillable before OS_SETGFX)
n_foc   ld a,(n_txt) : cp 2 : jr z,1F : xor a : ret
1       ld a,(user_scr0_low) : cp #FE : ret
n_pzf   db 0                                    ; 1: paused
n_zvec  dw 0                                    ; the game's n_vec, stack (its interrupt's), W3 - the pause's
n_zisp  dw 0
n_zw3   db 0
n_s3sp  dw 0
n_pal   dw #FFFF,#FEFE,#FDFD,#FCFC,#EFEF,#EEEE,#EDED,#ECEC     ; (pl_tab's: Evo's low bits = the same byte)
        dw #FFFF,#DEDE,#BDBD,#9C9C,#6F6F,#4E4E,#2D2D,#0C0C
; a message (DE.."$"), the start's failure: a key (when the text is on screen), then back to NC
n_msg   ld c,9 : jp n_bdos
n_fail  ld a,(n_txt) : cp 1 : jr nz,n_quit
1       ld c,CMD_YIELD : call n_os1
        ld e,#FF : ld c,6 : call n_bdos : or a : jr z,1B
; back to NC: the AY quiet, #0038 back, QUIT (the kernel gives our pages back, the focus to NC)
n_quit  di
        ld bc,#FFFD : ld a,7 : out (c),a : ld b,#BF : ld a,#3F : out (c),a
        ld a,8 : ld bc,#FFFD : out (c),a : ld b,#BF : xor a : out (c),a
        ld a,9 : ld b,#FF : out (c),a : ld b,#BF : xor a : out (c),a
        ld a,10 : ld b,#FF : out (c),a : ld b,#BF : xor a : out (c),a
        ld hl,n_o38 : ld de,#0038 : ld bc,3 : ldir
        call n_sync : ei
        ld hl,nf_tab : ld b,NF_N                ; the files still open: closed
1       ld a,(hl) : inc hl : or (hl) : inc hl : jr z,2F
        push hl : push bc : ex de,hl : ld c,16 : call 5 : pop bc : pop hl
2       ld de,36 : add hl,de : djnz 1B
        ld hl,0 : NQUIT
n_o38   ds 3                                    ; #0038's 3 bytes (the kernel's)
nb_end
        ASSERT nb_end <= #F800                  ; (n_doc's BIOS table: #F800..)
        ASSERT nb_end <= nf_tab
        ASSERT nf_tab+NF_N*38 <= NB_STK-#100
        ENT
nb_img_end
n_cl    ds 128                                  ; the command line as CP/M's (a_dbg)
n_xp    dw 0
n_left  db 59                                   ; the pages wanted: 2, 3, 4, 8..63
n_want  db 0,0,1,1,1,0,0,0                      ; (by the ATM page: 1 = wanted)
        ds 56,1
m_nmem  db 13,10,"UFO2: 1 MB of free memory needed (pages #40..#7D)",13,10,"$"
n_xtra  ds 200                                  ; the pages not wanted (given back)

