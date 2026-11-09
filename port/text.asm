; ---- the text layer, XPG's part: the text map's recorder, COPY / BACK, the switch to TXPG's code (textc.asm)
; TXPG (59): its code at #0000.. (textc.asm's image: img_out), CM_S #2000 (screen 7's cells: the character + 1 its
; PRINT / LETTER put there, 0 none; #2300 + row: 1 = the row has text), CM_D #2400 (the same for the DSCR; COPY / BACK
; move it), GF #2800 (the game's font as the game has it: the check), OF #3000 (ours: UFO2.ICO's "FN", build/mkico.py
; FONT.png; 2 bytes a line, 2 bits a pixel from the left: the class - the cell, the letter, its light, its shadow).
; The recorder: uipage.asm mk_sc (SCOORD's vector) -> tx_rec. The drawing: ov_fl's end -> tx_fl -> textc.asm txf.
TXPG    equ 59
; the game's BACK (uipage.asm mk_sc): screen 7 (W3's page: cur) -> DSCR, then its text map
; (in 27 pieces of 256: interrupts as they were between them - W1 is the game's again then; its stack may be there)
tx_bk   call ou_fl : ld hl,#4000 : ld de,#9000
0       ld a,i : push af : di
        ld a,(cur) : call bk_pg : xor #7F : ld bc,P_W1 : out (c),a         ; (cur: a ZX bank -> its page: ZX view - 7 is 5)
        ld bc,256 : ldir
        ld a,#7F-(PG_ZX+5) : ld bc,P_W1 : out (c),a
        pop af : jp po,1F : ei
1       ld a,h : cp #5B : jr c,0B
        ld a,1
; A = 0: COPY (the text map DSCR -> screen 7), 1: BACK (screen 7 -> DSCR) - uipage.asm mk_cy, mk_sc
tx_cmx  push hl : push de : push bc
        ld hl,#A400 : ld de,#A000 : or a : jr z,1F : ex de,hl
1       ld a,i : push af                        ; (interrupts as they are: int_f touches W3 only - ~33000 T)
        ld bc,P_W2 : ld a,#7F-TXPG : out (c),a
        push hl : push de : ld bc,#0320 : ldir : pop de : pop hl
        ld a,h : sub #10 : ld h,a : ld a,d : sub #10 : ld d,a : ld bc,#0300 : ldir         ; (TA)
        ld a,d : cp #93 : jr nz,3F : ld a,(bwide) : or a : jr nz,3F       ; (COPY, not the wide fight: rows 15..23 the
        ld hl,#A300+15 : ld b,9                                         ;  text layer's - the geoscape's messages the
4       ld (hl),1 : inc l : djnz 4B                                     ;  game put back into the DSCR without PRINT:
                                                                        ;  epg.asm tx_cv recognizes them)
3
        ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a
        pop af : jp po,2F : ei
2       pop bc : pop de : pop hl : ret
; SCROLL done (zxl.asm lay_scre -> wideu.asm scr_u): its lines marked (rows 15..23, columns 0..23); the text map
; moved the same way - rows 15..22 <- 16..23, row 23 <- DSCR's (the new line was printed there), TA too
tx_scr  push de
        ld a,120 : ld bc,72*256+7 : call mk_ln
        ld a,i : push af : di
        ld bc,P_W2 : ld a,#7F-TXPG : out (c),a
        ld hl,#A000+16*32 : ld de,#A000+15*32 : call 1F                ; CM_S
        ld hl,#A400+23*32 : ld bc,24 : ldir
        ld hl,#9000+16*32 : ld de,#9000+15*32 : call 1F                ; TA_S
        ld hl,#9400+23*32 : ld bc,24 : ldir
        ld hl,#A300+15 : ld b,9
2       ld (hl),1 : inc l : djnz 2B                                     ; (the rows' flags)
        ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a
        pop af : pop de : ret po : ei : ret
1       ld b,8
3       push bc : ld bc,24 : ldir : ld bc,8 : add hl,bc : ex de,hl : add hl,bc : ex de,hl : pop bc : djnz 3B
        ret
; BACK in the wide fight, state A: the field (BDSC) into screen 7 first - the window the game opens next is drawn
; over it there (state B shows screen 7) and BACK saves it (ou_line's work, once - no longer each OUTDSC)
ou_fl   ld a,(bwide) : or a : ret z : ld a,(bst) : or a : ret nz
        ld a,(PL_USE) : or a : ret nz           ; (the colour plane: screen 7's field never shown)
        ld a,i : push af : di
        ld a,(cur) : call bk_pg : xor #7F : ld bc,P_W2 : out (c),a        ; screen 7 at W2
        ld hl,BDSC+2+32*44 : ld c,8                                    ; (screen line C 8..135 <- field line C + 24)
1       ld a,c : and #C0 : rrca : rrca : rrca : ld d,a : ld a,c : and 7 : or d : or #80 : ld d,a
        ld a,c : and #38 : rlca : rlca : inc a : ld e,a                ; (column 1)
        push bc : ld bc,28 : ldir : ld bc,16 : add hl,bc : pop bc
        inc c : ld a,c : cp 136 : jr c,1B
        ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a
        pop af : ret po : ei : ret
; the field's rows (1..16) of the text map emptied: CM_S, TA_S, the rows' flags (wideu.asm ld_end: the popups gone)
tx_fcl  push hl : push de : push bc
        ld a,i : push af : di
        ld bc,P_W2 : ld a,#7F-TXPG : out (c),a
        ld hl,#A020 : ld de,#A021 : ld bc,16*32-1 : ld (hl),0 : ldir
        ld hl,#9020 : ld de,#9021 : ld bc,16*32-1 : ld (hl),0 : ldir
        ld hl,#A301 : ld de,#A302 : ld bc,15 : ld (hl),0 : ldir
        ld bc,P_W2 : ld a,#7F-(PG_ZX+2) : out (c),a
        pop af : jp po,1F : ei
1       pop bc : pop de : pop hl : ret
; the drawing (ico.asm ov_fl's end; A back: 1 = the back buffer's cursor off first): TXPG's code in W3 (map_w3p
; returns into TXPG at tx_sw + 5: textc.asm's landing - call txf, back to XPG here at tx_sw + 14)
; panel.asm pn2_nconv (E = the slot): textc.asm nm_cv - the fighter's name in our font
        ASSERT $ <= #DF90
        ds #DF90-$                              ; (xe_far at a fixed place: EPG's landing past it - epg.asm)
; HL = a routine in EPG (epg.asm): called with W3 = EPG, its A and flags back
xe_far  ld a,EPG : call map_w3p
        ds 9                                    ; (EPG: call xe_jp : push af : ld a,XPG : call map_w3p)
        pop af : ret
        ASSERT $ <= #DFA4
        ds #DFA4-$                              ; (tx_nm at a fixed place, past TXPG's code: textc.asm nm_end)
tx_nm   ld a,TXPG : call map_w3p
        ds 8                                    ; (TXPG: call nm_cv : ld a,XPG : call map_w3p)
        ret
        display "text end ",$
        ASSERT $ <= #DFD0
        ENT                                     ; (the landings' part apart: no padding in the image)
xpg_img_m
        DISP #DFD0
; panel.asm pn_bclr: textc.asm xp_rmp - the field's colours into the standard palette's slots
tx_rm   ld a,TXPG : call map_w3p
        ds 8                                    ; (TXPG: call xp_rmp : ld a,XPG : call map_w3p)
        ret
        ASSERT $ <= #DFE0
        ds #DFE0-$                              ; (tx_sw at a fixed place: TXPG keeps its landing free, textc.asm)
tx_fl   ld a,(tx_on) : or a : ret z
tx_sw   ld a,TXPG : call map_w3p
        ds 9                                    ; (TXPG: call txf : push af : ld a,XPG : call map_w3p)
        pop af : ret
tx_on   db 0                                    ; 1: TXPG has our font (xtil.asm ico_load)
