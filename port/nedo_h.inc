; NedoOS: the kernel's calls, the task's low memory (from NedoOS src/_sdk/sysdefs.asm, sys_h.asm, kernel userkrnl.asm)
; the task owns #0080..#FFFF; #0000..#007F is the kernel's (RST stubs, the interrupt at #0038, the windows' pages)
; - a call: C = function, CALL 5; the A parameter goes in A' (EX AF,AF' first); all registers but SP may be spoilt
; - the windows #4000 / #8000 / #C000: the kernel puts back (curpg4000 / 8000 / C000) after each interrupt and call:
;   a window is changed only with its curpg written first (SETPG4000 / 8000 / C000 = RST #18 / #20 / #28: A = page,
;   BC spoilt; or our WSET: the same with the port's address known - Evo BaseConf)
; - the interrupt: IM 1, #0038 (the task's own handler: in a chain - the 3 bytes there swapped with a JP)
NBDOS           equ #0005
COMMANDLINE     equ #0080
curpg4000       equ #0044
curpg8000       equ #004A
curpgc000       equ #0050
user_scr0_low   equ #0017                       ; screen 0: #4000.. of EGA (the ZX-ATM "page 1"), its pair (page 5)
user_scr0_high  equ #0035
user_scr1_low   equ #0036                       ; screen 1 (pages 3, 7)
user_scr1_high  equ #0037
; Evo BaseConf (NedoOS atm=3 build): the windows' ports, 256 pages (value = #FF - page)
MP4000          equ #77F7
MP8000          equ #B7F7
MPC000          equ #F7F7

CMD_PRCHAR      equ #05
CMD_SETDTA      equ #1A
CMD_OPENHANDLE  equ #43
CMD_CREATEHANDLE equ #44
CMD_CLOSEHANDLE equ #45
CMD_READHANDLE  equ #48
CMD_WRITEHANDLE equ #49
CMD_SEEKHANDLE  equ #4A
CMD_CHDIR       equ #5A
CMD_GETPATH     equ #5E
CMD_GETGFX      equ #C7
CMD_GETMEMPORTS equ #CA
CMD_GETCONFIG   equ #CC
CMD_HIDEFROMPARENT equ #D1
CMD_SETMUSIC    equ #D5
CMD_SETBORDER   equ #D8
CMD_GETFILESIZE equ #DA
CMD_GETKEYMATRIX equ #F0
CMD_GETTIMER    equ #F1
CMD_YIELD       equ #F2
CMD_CLS         equ #F6
CMD_SETGFX      equ #F9
CMD_SETPAL      equ #FA
CMD_GETMAINPAGES equ #FB
CMD_NEWPAGE     equ #FC
CMD_DELPAGE     equ #FD
CMD_SETSCREEN   equ #FE

key_esc         equ 27
key_redraw      equ 31

        MACRO NOS func                          ; a call without A
        ld c,func : call NBDOS
        ENDM
        MACRO NOSA func                         ; a call with A (it goes in A')
        ld c,func : ex af,af' : call NBDOS
        ENDM
        MACRO NQUIT                             ; HL = result
        rst 0
        ENDM
        MACRO NGETKEY                           ; A = key, C = key (no language), DE = mouse (y, x), L = buttons, NZ = no focus
        rst #08
        ENDM
        MACRO NPRCHAR                           ; A = char (text mode); spoils all
        rst #10
        ENDM
        MACRO NSETPG4
        rst #18
        ENDM
        MACRO NSETPG8
        rst #20
        ENDM
        MACRO NSETPGC
        rst #28
        ENDM
        MACRO NYIELD
        ld c,CMD_YIELD : call NBDOS
        ENDM
        MACRO PAL_HK                            ; HL = the palette's 16 values put now (DI) -> n_pal (nedo.asm n_shw3);
        push hl : push de : ex de,hl            ;  A spoilt
        ld a,3 : in a,(#BE) : ld hl,n_shw3 : call n_p3
        pop de : pop hl
        ENDM
        MACRO PAL_HKS                           ; PAL_HK on #3F60's stack (textc.asm xp_rmp's: the game's may be in W3 -
        ld (.sp+1),sp : ld sp,#3F60             ;  n_p3 puts page 3 there); DI
        PAL_HK
.sp     ld sp,0
        ENDM
