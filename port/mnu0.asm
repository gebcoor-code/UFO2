; mnu0.asm - (0.61.0) the start menu's loader (the start's code, W0): UFO2.MNU's first records are the menu's code
; (mnu.asm, assembled for MNM_A: "MN" + its size's low byte - this build's), the rest its pictures (build/mkmnu.py).
; No UFO2.MNU (or another build's), "UFO2 DEBUG": no menu - the loading at once, as before.
MNM_A   equ #B000                       ; (the code images' part of the TPA: copied out by img_out already; not
                                        ;  STAGE..#8FFF - UFO2.IMG -, not mz.asm's #9000..#AFFF)
smenu   db 0                            ; 1: "UFO2 MENU" (the instruction's way back - mnu.asm sb_ret): no title first
f_mnu   db "UFO2    MNU"
st_mnu  ld a,(sdbg) : or a : ret nz
        ld hl,f_mnu : ld de,MNM_A : ld b,MNM_R : call mf_rd : ret nc
        ld hl,(MNM_A) : ld de,"NM" : or a : sbc hl,de : ret nz
        ld a,(MNM_A+2) : cp low MNM_N : ret nz
        jp MNM_A+3
; (0.63.0) the menu's "1": the original's intro (UFO2.INT - build/mkint.py; mnu.asm mm_int loads its banks: bank n
; in page INTB+n, bank 5 in page 5 - ATM's ZX screen; CP/M's page 5 kept in INT_SV) run in place: W1 = page 5, W2 =
; bank 2, W3 = the bank its MEME (the only OUT (#7FFD)) asks - JP mi_mem in it; IM 2 its own (I = #71); its end
; (Enter): IM 1, EI, RET - #0038 EI : RET meanwhile. Here in W0: the windows 1..3 are its.
INTB    equ 32
INT_SV  equ 40
MI_GO   equ #705A                       ; (XBEGIN's ST1_; mkint.py checks them)
MI_MEME equ #75C7
mi_run  di
        IFDEF NEDOOS                            ; (NedoOS: #0038 the chain's - the game's handler off: n_vec)
        ld hl,(n_vec) : ld (mi_38),hl : ld hl,n_iret : ld (n_vec),hl
        ELSE
        ld hl,(#0038) : ld (mi_38),hl : ld hl,#C9FB : ld (#0038),hl
        ENDIF
        WIN P_W1, PS5
        WIN P_W2, INTB+2
        WIN P_W3, INTB
        ld a,#C3 : ld (MI_MEME),a : ld hl,mi_mem : ld (MI_MEME+1),hl
        ld a,VM_ZX : call vmode : xor a : SHOWSCR
        IFDEF NEDOOS                            ; (the kernel's OS_SETGFX: put by its interrupt - not with the
        ld bc,#FD77 : ld a,VM_ZX : out (c),a    ;  intro's own IM 2)
        ENDIF
        call MI_GO
        di
        IFDEF NEDOOS
        im 1 : ld hl,(mi_38) : ld (n_vec),hl
        ELSE
        ld hl,(mi_38) : ld (#0038),hl
        ld a,(cpm_i) : ld i,a : im 2 : ld a,(cpm_im1) : or a : jr z,1F : im 1
        ENDIF
1       WIN P_W1, 4                            ; (CP/M's windows: ovl.asm zx_exit's)
        WIN P_W2, 2
        WIN P_W3, 3
        ld a,3 : SHOWSCR
        ret
        IFDEF NEDOOS                            ; (bank 5: the screen's page - PS5)
mi_mem  push bc : push af : and 7 : cp 5 : ld b,PS5 : jr z,1F : add a,INTB : ld b,a
1       ld a,b
        ELSE
mi_mem  push bc : push af : and 7 : cp 5 : jr z,1F : add a,INTB
        ENDIF
1       ld b,a : ld a,#7F : sub b : ld bc,P_W3 : out (c),a
        pop af : and 7 : or 16 : pop bc : ret
mi_38   dw 0
