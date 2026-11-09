; ------------------------------------------------------------------ the coloured locations (UFO2.TIL: build/mktil.py)
; The fight's field in colour (every location: its 96 tiles found in UFO2.TIL by xexp.asm tl_exp at the first sprite): a colour
; plane (PLA: EGA parts 0, 2; PLB: 1, 3 - laid out as the screen's buffers, 40 x 200: the field's bytes 2..41, lines
; 32..231) the hooks draw the tiles into as the game draws them into BDSC (ob_spr -> PL_SPR), moved with the field's
; scrolls (pl_shf).
; The tiles: TLPG (codes 0..TL1-1), TLPG2 (TL1..TL2-1), TLPG3 (the rest), each with the same header at #4000 (W1 while
; used): the code,
; tl_nm (xt_load's), tl_rng (tl_exp's), the tiles from TLR (256 bytes each: 2 columns x 32 lines x the EGA bytes of
; parts 0, 2, 1, 3; slot 9 = none). Most lines the game draws are none in a column (the tiles' corners, walls' air):
; only tl_rng's lines are drawn.
TLPG    equ 30
TLPG2   equ 31
TLPG3   equ 62                          ; (the old C plane's page)
TIPG    equ 32+11                       ; UFO2.TIL's index (#2000..#3BFF: was XPG's #E000..; 0.55.2): dpages[11] - the
                                        ; DAT's freed span (the game's encyclopedia pictures, not loaded; ram_init.asm pg1m)
PLA     equ 28
PLB     equ 29
TL1     equ 31
TL2     equ 63
TLM     equ 33                          ; the most tiles in a page (TLR .. tl_opq)
TLR     equ #4800
tl_rng  equ #4500                       ; a tile's (this page's) columns: the first line with pixels, the last + 1
t40     equ tl_rng+#C0                  ; (32 + 32) n * 40, n < 32: its low bytes, then its high ones (xt_hdr)
        ASSERT 4*TLM <= #C0 && low t40 == #C0
t_gm    equ tl_rng+#88                  ; (42) x + 1 -> the groups of bytes x - 1 .. x + 1 (0..39) - xpnt.asm pl_mk
        ASSERT 4*TLM <= #88 && t_gm+42 <= t40
tl_nm   equ #4600                       ; an EGA byte -> the plane's bits it keeps (its none pixels)
                                        ; (#4700: the hooks' second part - xpnt.asm)
tl_opq  equ #6900                       ; a tile's (this page's) columns: the first line of its opaque band (all 4 bytes
                                        ; without none pixels), its last + 1 (tl_exp's)
TLN     equ 96
PL_SP   equ #3F7E                       ; (W0: PL_SPR's stack below it, the game's SP kept there; tl_exp's: #3F60)

; (the image: xtil_i.asm - past the start's ibuf; img_out puts it into TLPG, TLPG2: xt_hdr)

; at the start (img_out: xt_hdr) the header (and tl_nm) into TLPG, TLPG2; after xs_load UFO2.TIL: XPG's part
; (56 records, through STAGE) -> TIPG #2000..#3BFF, page 2's (60) -> #A000 (page 2 = W2 now), page 4's (128) -> STAGE.
; None: pl_ok 0, no colour plane.
CLPG    equ 4
; (img_out, DI: the header into TLPG, TLPG2)
xt_hdr  ld a,TLPG : call 1F : call 3F
        ld a,TLPG2 : call 1F : call 3F
        ld a,TLPG3 : call 1F : call 3F
        WIN P_W3, 3 : ret
xt_load ld a,#80 : ld (mz_b),a                  ; (mz.asm: packed; its buffers #8000..#9FFF - TIL's part at #A000)
        ld hl,f_til : ld de,STAGE : ld b,56 : call mz_rd : ret nc
        ld a,b : or a : ret nz
        di : ld a,TIPG : call map_w2
        ld hl,STAGE : ld de,#A000 : ld bc,56*128 : ldir
        ld a,2 : call map_w2 : ei
        ld de,#A000 : ld b,60 : call mz_more : ld a,b : or a : ret nz
        ld de,STAGE : ld b,128 : call mz_more : ld a,b : or a : ret nz
        di
        ld a,TLPG : call map_w2 : ld a,1 : ld (pl_ok-#4000+#8000),a
        ld a,TLPG2 : call map_w2 : ld a,1 : ld (pl_ok-#4000+#8000),a
        ld a,TLPG3 : call map_w2 : ld a,1 : ld (pl_ok-#4000+#8000),a
        ld a,2 : call map_w2 : ei : ret
; tl_nm (W3): a byte's pixels of slot 9 (left: bits 0-2, 6 = %001, 1; right: 3-5, 7) kept from the plane
3       ld hl,t40+#8000 : ld de,0                               ; t40
30      ld (hl),e : set 5,l : ld (hl),d : res 5,l
        push hl : ld hl,40 : add hl,de : ex de,hl : pop hl
        inc l : ld a,l : cp low t40+32 : jr nz,30B
        ld hl,t_gm+#8000 : ld c,-1                              ; t_gm: C = x
35      ld a,c : dec a : jp p,36F : xor a                       ; (max (x - 1, 0))
36      call 37F : ld e,a
        ld a,c : inc a : cp 40 : jr c,38F : ld a,39             ; (min (x + 1, 39))
38      call 37F : add a,a : sub e                              ; (2 ^ (its group + 1) - 2 ^ the first's)
        ld (hl),a : inc hl : inc c : ld a,c : cp 41 : jr nz,35B
        ld hl,tl_nm+#8000 : ld c,0
31      ld b,0 : ld a,c : and #47 : cp #41 : jr nz,32F : ld b,#47
32      ld a,c : and #B8 : cp #88 : ld a,b : jr nz,33F : or #B8
33      ld (hl),a
        inc l : inc c : jr nz,31B
        ret
37      rrca : rrca : rrca : and 7 : inc a : ld b,a : ld a,1    ; A = a byte -> 2 ^ its group
371     dec b : ret z : add a,a : jr 371B
1       ld b,a : ld a,#7F : sub b : ld bc,P_W3 : out (c),a                ; (W3: the image is in W2's range)
        ld hl,xtil_img : ld de,#C000 : ld bc,xtil_img_end-xtil_img : ldir
        ld hl,xpb_img : ld de,XPB+#8000 : ld bc,xpb_img_end-xpb_img : ldir
        ret                                                     ; (TLPG's hooks' part: ram_init.asm mx_load)
f_til   db "UFO2    TIL"
; UFO2.PNL beside UFO2.COM (build/mkpnl.py: the panels with build/data/ico's PANEL.png): over UFO2.DAT's ones - a
; header record (pn_hdr: this build's layout), then PN2_PNL records as p_load's pages; anything else: not used
f_pnl   db "UFO2    PNL"
pn_hdr  db "PNL1" : dw PN2_PNL, PN2_AW, PN2_AR, PN2_AA
pn_fload
        ld hl,f_pnl : ld de,STAGE : ld b,1 : call mf_rd : ret nc
        ld a,b : or a : ret nz
        ld hl,STAGE : ld de,pn_hdr : ld b,12
1       ld a,(de) : cp (hl) : ret nz : inc hl : inc de : djnz 1B
        ld de,mfcb : ld c,35 : call BDOS                                ; (its size: the header + PN2_PNL)
        ld hl,(mfcb+33) : ld de,PN2_PNL+1 : or a : sbc hl,de : ret nz : ld a,(mfcb+35) : or a : ret nz
        ld a,OPG0 : ld (pf_pg),a : ld hl,PN2_PNL
2       ld a,h : or a : ld b,128 : jr nz,3F : ld a,l : cp 128 : jr nc,3F : ld b,l
3       push hl : push bc : ld de,STAGE : call mf_more : ld a,b : pop bc : pop hl : or a : ret nz
        push hl : push bc : ld h,b : ld l,0 : srl h : rr l : ld b,h : ld c,l    ; (B * 128 bytes)
        di : ld a,(pf_pg) : call map_w2 : ld hl,STAGE : ld de,#8000 : ldir : ld a,2 : call map_w2 : ei
        ld hl,pf_pg : inc (hl) : pop bc : pop hl
        ld e,b : ld d,0 : or a : sbc hl,de : ld a,h : or l : jr nz,2B
        ret
pf_pg   db 0
; (ram_init.asm mx_load: DI, HL = STAGE's part past MX) TLPG's hooks' part (xpnt.asm) -> XPA
xp_load ld a,TLPG : call map_w2
        ld de,XPA+#4000 : ld bc,XP_N : ldir
        ld de,tl_nm+256+#4000 : ld bc,XP2_N : ldir
        ld a,2 : call map_w2 : ei : ret
; the text layer's page (xpg.asm text.asm TXPG): the maps empty, the game's font (bank 5) as GF (ours, OF: ico_load)
tx_init di
        ld a,PG_ZX+5 : call map_w2 : ld hl,G_FONT-#4000+#8000 : ld de,STAGE : ld bc,1024 : ldir
        ld a,TXPG : call map_w2
        ld hl,#A000 : ld de,#A001 : ld bc,#0800-1 : ld (hl),0 : ldir
        ld hl,#9000 : ld de,#9001 : ld bc,#0800-1 : ld (hl),0 : ldir           ; (TA_S, TA_D)
        ld hl,#8780 : ld de,#8781 : ld bc,#0880-1 : ld (hl),0 : ldir           ; (TV, SP)
        ld hl,STAGE : ld de,#A800 : ld bc,1024 : ldir
        ld hl,#AC00 : ld de,#AC01 : ld bc,#01FF : ld (hl),0 : ldir          ; (ico.asm ov_sgc's signatures)
        ld a,MPG : call map_w3p : call og_gen                           ; (mx.asm)
        ld hl,tx_rbi : ld de,TX_RB-#4000 : ld bc,1024 : ldir : ld a,3 : call map_w3p     ; (textr.asm: epg.asm's TX_RB)
        ld a,TXPG : call map_w3p : call tc_spa : ld a,3 : call map_w3p  ; (textc.asm: TX_SP for all characters now)
        ld a,2 : call map_w2 : ei : ret
; BC bytes HL -> DE as LDIR, faster (16 LDI a step; the start's code: zxl.asm, xspr.asm too)
fcopy   ld a,c : and 15 : jr z,2F
1       ldi : dec a : jr nz,1B
2       ld a,b : or c : ret z
3       DUP 16
        ldi
        EDUP
        jp pe,3B : ret
; UFO2.ICO (build/mkico.py: "I2", the buttons, the signs, the parameters' - ico.asm; 91 records) -> page ICPG #0800 (past the
; panels' atlas); its second part ("WM": the world map, LZ; 74 records at most) -> page 58 #1B00 (sc.asm's slot 1);
; the panels' cells taken from it too: the weapons' (24 x 17 of the button from x 4, line 4; both states), the
; ranks' (16 x 20 of the sign from x 4, line 2), the armours' (16 x 18 from x 4, line 3). None: as the game's.
ICO_LEN equ 2 + 16 * 384 + 12 * 288 + 96 * 12 + 64 * 12
        ASSERT (ICO_LEN + 127) / 128 == 91                             ; (then the map's part: 74 records)
ico_load
        call pn_fload                                                   ; (UFO2.PNL first: the items go into its atlas)
        ld a,#80 : ld (mz_b),a
        ld hl,f_ico : ld de,STAGE : ld b,91 : call mz_rd : ret nc            ; (mz.asm: packed)
        ld hl,(STAGE) : ld de,"3I" : or a : sbc hl,de : ret nz          ; ("I3": 0.54.13 - BUTTONS2's 12th; "I2" 0.54.5)
        di
        ld a,ICPG : call map_w2 : ld hl,STAGE : ld de,#8000 + ICO_A : ld bc,ICO_LEN : ldir
        ld a,XPG : call map_w2 : ld a,1 : ld (ico_ok-#4000),a            ; (XPG in W2 meanwhile)
        ld a,APG + PN2_AW / 16384 : call map_w2
        ld de,#8000 + PN2_AW % 16384 + 14 + 1 : ld c,0                 ; (gun * 2 + chosen; line 1, pair 1)
1       ld a,c : and 1 : ld (ico_sel),a
        ld a,c : srl a : ld h,a : ld l,0 : srl h : rr l : push de : ld e,l : ld d,h : add hl,hl : add hl,de : pop de
        push bc : ld bc,STAGE + 2 + 4 * 16 : add hl,bc : ld b,17
2       push bc : push hl : push de : ld a,(ico_sel) : or a : jr nz,8F : ld b,12 : ld ix,ico_pw : call 5F
8       pop de : pop hl
        ld bc,16 : add hl,bc : ex de,hl : ld bc,14 : add hl,bc : ex de,hl : pop bc : djnz 2B
        ex de,hl : ld bc,392 - 17 * 14 : add hl,bc : ex de,hl
        pop bc : inc c : ld a,c : cp 32 : jr c,1B
        ld a,APG + PN2_AR / 16384 : call map_w2
        ld hl,STAGE + 2 + 6144 + 2 * 12 : ld de,#8000 + PN2_AR % 16384 : ld bc,8 * 256 + 20 : call 3F
        ld a,APG + PN2_AA / 16384 : call map_w2
        ld hl,STAGE + 2 + 6144 + 8 * 288 + 3 * 12 : ld de,#8000 + PN2_AA % 16384 : ld bc,4 * 256 + 18 : call 3F
        ld a,2 : call map_w2 : ei
        ld de,STAGE : ld b,74 : call mz_more                            ; the world map ("WM", LZ: ico.asm ov_map)
        ld hl,(STAGE) : ld de,"MW" : or a : sbc hl,de : ret nz
        di : ld a,SC_P0+3 : call map_w2 : ld hl,STAGE : ld de,#9B00 : ld bc,9472 : ldir
        ld a,XPG : call map_w2 : ld a,1 : ld (ico_map-#4000),a
        ld a,2 : call map_w2 : ei
        ld de,STAGE : ld b,33 : call mz_more                            ; the text's font ("FN": text.asm) -> TXPG #3000
        ld hl,(STAGE) : ld de,"NF" : or a : sbc hl,de : ret nz
        di : ld a,TXPG : call map_w2 : ld hl,STAGE + 2 : ld de,#B000 : ld bc,2048+16 : ldir   ; (OF, its hand-drawn bits: og_gen - not #3A00..: epg.asm)
        ld a,XPG : call map_w2 : ld a,1 : ld (tx_on-#4000),a
        ld a,2 : call map_w2 : ei : ret
; B signs (HL: the first one's first line, 288 apart), C lines each -> DE (8 bytes a line, on)
3       push bc : push hl : ld b,c
4       push bc : push hl : ld b,8 : ld ix,ico_ps : call 5F : pop hl : ld bc,12 : add hl,bc : pop bc : djnz 4B
        pop hl : ld bc,288 : add hl,bc : pop bc : djnz 3B
        ret
; B bytes: (HL + (IX)) -> DE..
5       ld a,(ix+0) : inc ix : push hl : add a,l : ld l,a : jr nc,6F : inc h
6       ld a,(hl) : pop hl : ld (de),a : inc de : djnz 5B
        ret
; (the chosen gun's cell: no picture of UFO2.ICO - all yellow, made so: tools/mkpanel2.py)
ico_sel db 0
; a pair's place in a line of the 4 parts (pair 4c + q: part 0, 2, 1, 3 for q 0, 1, 2, 3; w bytes each): pairs 2..
ico_pw  db 1*4+0, 3*4+0, 0*4+1, 2*4+1, 1*4+1, 3*4+1, 0*4+2, 2*4+2, 1*4+2, 3*4+2, 0*4+3, 2*4+3     ; (w 4: 2..13)
ico_ps  db 1*3+0, 3*3+0, 0*3+1, 2*3+1, 1*3+1, 3*3+1, 0*3+2, 2*3+2                            ; (w 3: 2..9)
f_ico   db "UFO2    ICO"
        ASSERT $ <= ibuf                        ; (the start's record buffer: the code here is still needed)
