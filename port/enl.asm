; ---- the encyclopedia's pictures from the disk (0.54.25: UFO2.ENC - build/mkenc.py's "E2" - is no longer kept in
; memory: a picture is read from it each time its article's picture is opened; the last one stays in its buffer).
; Page SC_P0's tail (#1B00.., free there; zxl.asm img_out puts both images in): en_get runs in W2 (#9B00, from
; enc.asm ep_prep: XPG in W3); CP/M is called through ovl.asm d_cpm, whose routine must be in W0: the reader (ens_img)
; is brought into the shadow SHP for it, the shadow's bytes kept meanwhile in this page (EN_SAV) and put back.
; UFO2.ENC (0.60.1): on the current drive, then A:, B:, C: (all drives reset after: another disk may be put in for it,
; the game's put back after). Not there (or no disk access): the message's picture (build/mkmsg.py: encmsg.bin) instead.
EN_BP   equ 8                                   ; dpages[EN_BP]: the picture's buffer (the DAT's freed span: mkdat.py)
EN_W2   equ #9B00                               ; (page SC_P0 +#1B00)
ENS_W2  equ #BC00                               ; (W2) the reader's image in this page
EN_SAV  equ #BE00                               ; (W2) the shadow's bytes meanwhile
enl_img
        DISP EN_W2
; A = the picture (0..59) -> A = its data's page, HL = the address (W2): plane's LZ, colours' LZ
en_get  ld hl,en_last : cp (hl) : jr z,8F                       ; (in the buffer already)
        ld (hl),#FF : ld (en_n),a
        ld a,(d_ok) : or a : jr z,9F
        ld hl,SHP : ld de,EN_SAV : ld bc,ENS_N : ldir           ; the shadow's bytes kept
        ld hl,ENS_W2 : ld de,SHP : ld bc,ENS_N : ldir           ; the reader in
        ld a,(en_n) : ld (es_n),a
        ld a,(bf) : ld (en_bf),a : or a : call nz,en_ab         ; (B shown: A shows it meanwhile)
        call es_go
        ld a,(en_bf) : or a : call nz,en_ba
        ld a,(es_ok) : push af
        ld hl,EN_SAV : ld de,SHP : ld bc,ENS_N : ldir           ; the shadow back
        pop af : or a : jr z,9F
        ld a,(en_n) : ld (en_last),a
8       ld a,(dpages+EN_BP) : ld hl,#8000 : ret
9       ld a,SC_P0 : ld hl,en_msg : ret
; d_cpm shows buffer A while CP/M works (its BIOS: #7FFD = 3; page 3 is CP/M's then): with B shown, A - the back
; buffer, half made - would be seen meanwhile. en_ab: A (pages 1, 5: #0000..#1F3F, #2000..#3F3F) kept in
; dpages[EN_BP+1], [EN_BP+2] (the DAT's freed span), B's (3, 7) copied into it; en_ba: A back
en_ab   call en_di
        ld bc,PS1*256+EN_K1 : call en_cpk : ld bc,PS5*256+EN_K2 : call en_cpk
        ld bc,PS3*256+PS1 : call en_cp : ld bc,PS7*256+PS5 : call en_cp
        jr en_ei
en_ba   call en_di
        ld bc,EN_K1*256+PS1 : call en_cpk2 : ld bc,EN_K2*256+PS5 : call en_cpk2
en_ei   ld a,XPG : call map_w3p
        WIN P_W1, PG_ZX+5
        ld a,(en_if) : or a : ret z : ei : ret
en_di   ld a,i : di : ld a,0 : jp po,1F : inc a
1       ld (en_if),a : ret
en_cpk  ld a,c : call en_dp : ld c,a : jr en_cp        ; B -> dpages[C]
en_cpk2 ld a,b : call en_dp : ld b,a : jr en_cp        ; dpages[B] -> C
en_dp   push hl : ld hl,dpages : add a,l : ld l,a : jr nc,1F : inc h
1       ld a,(hl) : pop hl : ret
; B -> C (W1 the source, W3 the destination; DI): its two 8000 bytes
en_cp   ld a,#7F : sub b : push bc : ld bc,P_W1 : out (c),a : pop bc
        ld a,#7F : sub c : ld bc,P_W3 : out (c),a
        ld hl,#4000 : ld de,#C000 : ld bc,#1F40 : ldir
        ld hl,#6000 : ld de,#E000 : ld bc,#1F40 : ldir : ret
EN_K1   equ EN_BP+1
EN_K2   equ EN_BP+2
en_bf   db 0
en_if   db 0
en_last db #FF
en_n    db 0
en_msg  incbin "encmsg.bin"
; ---- (0.57.0; here: the page's free tail - not the encyclopedia's) xexp.asm tl_exp's tile (te_t, its index te_md in
; UFO2.TIL; W1 = TIPG, W3 = MPG, W2 = this page): its shape as the author's sheets have it - pixels added / taken off
; (mktil.py's patch table past the 8 ids' parts: "SP", P, per patched tile its index, K, K x (offset, byte)); then the
; game's vSIZE of the tile (#AF80 + code: its first line with pixels - the lines it draws, its height for the sight:
; XLIB.A80 LCOUNT, made at the fight's start - before this) from it. W1 = TIPG again after.
; a byte of an EGA tile (HL; DE the floor's): its pixel of colour "none" whose mask bit (C: lb - the left one, rb)
; is on takes the floor's
        MACRO MGB lb, rb
        ld a,(hl) : and #47 : cp #41 : jr nz,91F
        ld a,c : and lb : jr z,91F
        ld a,(de) : and #47 : ld b,a : ld a,(hl) : and #B8 : or b : ld (hl),a
91      ld a,(hl) : and #B8 : cp #88 : jr nz,92F
        ld a,c : and rb : jr z,92F
        ld a,(de) : and #B8 : ld b,a : ld a,(hl) : and #47 : or b : ld (hl),a
92      inc l : inc e
        ENDM
te_pt   call te_pp                                      ; (0.59.0: then its mask's lines 16..31 kept - te_flr)
; the tile's (te_t's) masks of lines 16..31 -> TMK + code * 32 (line by line: column 0, column 1)
te_mk   ld a,(te_k) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld de,TMK : add hl,de : ex de,hl
        ld hl,te_t+64 : ld b,32
1       ld a,(hl) : ld (de),a : inc de : inc hl : inc hl : djnz 1B : ret
te_pp   ld hl,(TEW) : ld b,h : ld c,l : add hl,hl : add hl,bc : ex de,hl          ; DE = 3 N
        ld hl,(TEW) : ld bc,7 : add hl,bc : srl h : rr l : srl h : rr l : srl h : rr l
        ld b,h : ld c,l : add hl,hl : add hl,bc : add hl,de : ld de,TEW+2 : add hl,de   ; + 3 NG: the table
        ld a,(hl) : cp 'S' : ret nz : inc hl : ld a,(hl) : cp 'P' : ret nz : inc hl
        ld b,(hl) : inc hl : inc b
1       dec b : ret z
        ld e,(hl) : inc hl : ld d,(hl) : inc hl : ld c,(hl) : inc hl
        push hl : ld hl,(te_md) : or a : sbc hl,de : pop hl : jr z,2F
        ld e,c : ld d,0 : add hl,de : add hl,de : jr 1B
2       ld b,c
3       ld e,(hl) : inc hl : ld a,(hl) : inc hl
        push hl : ld hl,te_t : ld d,0 : add hl,de : ld (hl),a : pop hl : djnz 3B
        ld hl,te_t : ld de,4 : ld bc,31*256                     ; (LCOUNT's: 31 lines at most)
4       ld a,(hl) : inc hl : inc hl : or (hl) : dec hl : dec hl : jr nz,5F
        add hl,de : inc c : djnz 4B
5       ld a,(te_k) : or #80 : ld e,a : ld d,#6F                ; (vSIZE + code: bank 2's #2F80.. at W1)
        ld a,c : push af
        WIN P_W1, PG_ZX+2
        pop af : ld (de),a
        WIN P_W1, TIPG
        ret
; ---- (0.58.0) the floor under the player's ship: XM0's tiles 3..15 stand in the field's cells instead of its floor -
; nothing is drawn under them. The location's floor tile (the commonest code 16..95 next to them - left, right - in
; the floors #E000.., #F000.. of the game's bank at #C000, cur) is put under their none pixels of lines 16..31 (their EGA tiles in TLPG), their tl_rng
; from line 16 at most down to 32. tl_exp's end (W2 = this page; W1 the caller's after it)
TFB     equ #B800                                       ; (this page's tail: the counts 2 x 96; the floor's EGA at +#100)
TMK     equ #AC00                                       ; (96 x 32: the tiles' masks of lines 16..31 - te_mk)
; (0.66.1) the floor: neighbours of not 10, 11, 15 - flat, floor-level (10 - the white plate: the ship's floor, the UFO's 2nd floor, beds...) - a
; block's floor (rock, a platform) under them was junk; the neighbours of the 1st floor only (the 2nd's plates stood
; beside anything)
; (0.66.9) not baked into their EGA tiles any more (one tile on both floors: the 2nd floor's wings got it in the air) -
; pf_flo (obj.asm): xpnt.asm pl_fl draws it under them on the 1st floor only
te_flr  ld a,#FF : ld (pf_flo),a
        call 30F
        ld hl,#7001 : ld de,4094                                ; (the 1st floor: #F000..#FFFF)
1       ld a,(hl) : and #7F : call 3F : jr nz,2F                ; (a ship's cell: its left, right neighbours counted)
        dec hl : call 15F : inc hl : inc hl : call 15F : dec hl
2       inc hl : dec de : ld a,d : or e : jr nz,1B
        call 40F : jr z,20F                                     ; (no floor next to the ship)
        ld a,c : ld (pf_flo),a
        ; (0.59.0) every other tile (16..95): the location's floor (the commonest code 16..95 of the 1st floor) under
        ; its pixels of colour "none" in lines 16..31 that are its own (the mask: TMK) - the author's transparent joints
20      call 30F
        ld hl,#7000 : ld de,4096                                ; (the 1st floor: #F000 - the game's GS1 #F0)
21      call 15F : inc hl : dec de : ld a,d : or e : jr nz,21B
        call 40F : jr z,29F
        ld a,c : ld (fl_f),a : call 50F
        ld a,16
22      push af : ld hl,fl_f : cp (hl) : call nz,60F : pop af : inc a : cp 96 : jr c,22B
29      ld hl,TMK : ld de,TMK+1 : ld bc,96*32-1 : ld (hl),0 : ldir         ; (clean for the next fight's)
        ret
; the counts none; the game's bank at #C000 (cur) at W1 - its #E000 (the 2nd floor) at #6000, #F000 (the 1st) at #7000
30      ld hl,TFB : ld de,TFB+1 : ld bc,191 : ld (hl),0 : ldir
        ld a,(cur) : call bk_pg : neg : add a,#7F : ld bc,P_W1 : out (c),a : ret
; the commonest code 16..95 -> C (Z: none)
40      ld hl,TFB+32 : ld de,0 : ld bc,80*256 : ld a,16 : ex af,af'             ; DE the most, C its code
4       push bc : ld c,(hl) : inc hl : ld b,(hl) : inc hl
        push hl : ld h,b : ld l,c : or a : sbc hl,de : pop hl : jr c,5F : jr z,5F
        ld d,b : ld e,c : pop bc : ex af,af' : ld c,a : ex af,af' : jr 6F
5       pop bc
6       ex af,af' : inc a : ex af,af' : djnz 4B
        ld a,d : or e : ret
; code C's EGA tile -> TFB + #100
50      ld a,c : call 70F
        ld de,TFB+#100 : ld bc,256 : ldir : ret
; code A -> its page at W1, H = its tile's high byte there (L = 0)
70      cp TL1 : ld b,TLPG : jr c,71F : sub TL1 : ld b,TLPG2 : cp TL2-TL1 : jr c,71F : sub TL2-TL1 : ld b,TLPG3
71      add a,high TLR : ld h,a : ld l,0
        ld a,#7F : sub b : ld bc,P_W1 : out (c),a : ret
15      ld a,(hl) : and #7F : cp 16 : ret c : cp 96 : ret nc
        push hl : add a,a : ld l,a : ld h,high TFB : inc (hl) : jr nz,16F : inc hl : inc (hl)
16      pop hl : ret
; code A (16..95): the floor under its own "none" pixels of lines 16..31 (TMK's mask bits)
60      push af : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : add hl,hl : add hl,hl
        ld de,TMK : add hl,de : push hl : pop ix : pop af
        call 70B
        ld l,64 : ld de,TFB+#100+64 : call 61F                  ; (column 0)
        ld bc,-31 : add ix,bc
        ld l,128+64 : ld e,low (TFB+#100+128+64)                ; (column 1)
61      ld b,16
62      push bc : ld c,(ix+0) : inc ix : inc ix
        MGB #80, #40 : MGB #08, #04 : MGB #20, #10 : MGB #02, #01
        pop bc : dec b : jp nz,62B : ret
; Z: code A - a ship's tile (3..15, not 10, 11, 15)
3       cp 3 : jr c,31F : cp 16 : jr nc,31F : cp 10 : jr z,31F : cp 11 : jr z,31F : cp 15 : jr z,31F
        cp a : ret
31      or 1 : ret
fl_f    db 0
        ASSERT TFB+#200 <= ENS_W2 && $ <= TMK && TMK+96*32 <= TFB
enl_end
        ASSERT enl_end <= ENS_W2
        ENT
enl_img_end

; ---- the reader (in the shadow SHP while it runs; W0): UFO2.ENC's picture es_n -> dpages[EN_BP] from #8000;
; es_ok = 1: read
ens_img
        DISP SHP
es_go   ld hl,es_run : call d_cpm                               ; (from en_get: W2 = SC_P0, W3 = XPG)
        ld a,SC_P0 : call map_w2 : ld a,XPG : jp map_w3p        ; (d_cpm leaves the game's)
; UFO2.ENC: on the current drive (CP/M's), then A:, B:, C: (those there are: BIOS select, as d_open); not found -
; es_ok = 0 (the message instead). All drives are reset at the end (BDOS 37: UFO2.DAT's and the ones tried among them):
; logged in again at their next use - the disk in one may be another one by then
        IFDEF NEDOOS                                            ; (NedoOS: the game's folder only - no BIOS to
es_run  xor a : ld (es_fcb),a                                  ;  select drives with)
        ld hl,es_fcb+12 : ld b,24
1       ld (hl),0 : inc hl : djnz 1B
        jp es_one
        ELSE
es_run  ld c,25 : call BDOS : ld (es_cd),a
        ld hl,(1) : ld de,24 : add hl,de : ld (.sel+1),hl : ld (.sl2+1),hl
        ld hl,es_dl
5       ld a,(hl) : cp #FF : jr z,es_rst
        inc hl : push hl
        ld (es_fcb),a : or a : jr z,6F
        dec a : ld c,a : ld a,(es_cd) : cp c : jr z,7F          ; the current one: tried already
        ld e,0
.sel    call 0
        push hl
        ld a,(es_cd) : ld c,a : ld e,1
.sl2    call 0                                                  ; CP/M's drive selected again
        pop hl
        ld a,h : or l : jr z,7F                                 ; (no such drive)
6       ld hl,es_fcb+12 : ld b,24
8       ld (hl),0 : inc hl : djnz 8B
        call es_one
        ld a,(es_ok) : or a : jr z,7F
        pop hl : jr es_rst
7       pop hl : jr 5B
es_rst  ld de,#FFFF : ld c,37 : jp BDOS
        ENDIF
; UFO2.ENC on es_fcb's drive: its picture es_n read -> es_ok = 1
es_one  ld de,es_fcb : ld c,15 : call BDOS : inc a : ret z      ; (no UFO2.ENC)
        ld de,dkbuf : ld c,26 : call BDOS
        ld hl,0 : call es_rd : ret nz
        ld hl,(dkbuf) : ld de,"2E" : or a : sbc hl,de : ret nz  ; ("E2")
        ld a,(es_n) : add a,a : ld e,a : ld d,0 : ld hl,dkbuf+2 : add hl,de
        ld e,(hl) : inc hl : ld d,(hl) : inc hl : ld a,(hl) : inc hl : ld h,(hl) : ld l,a   ; DE: its first record, HL: the next's
        or a : sbc hl,de : ret z : ret c
        ld a,h : or a : ret nz : ld a,l : cp 129 : ret nc       ; (16K at most)
        ld (es_k),a : ex de,hl : ld de,#8000 : ld (es_ad),de
1       push hl : call es_rd : jr nz,2F
        di : ld a,(dpages+EN_BP) : call map_w2
        ld hl,dkbuf : ld de,(es_ad) : ld bc,128 : ldir : ld (es_ad),de
        ld a,2 : call map_w2 : ei
        pop hl : inc hl
        ld a,(es_k) : dec a : ld (es_k),a : jr nz,1B
        ld a,1 : ld (es_ok),a : ret
2       pop hl : ret
; HL = the record -> dkbuf; NZ: not read
es_rd   ld (es_fcb+33),hl : xor a : ld (es_fcb+35),a
        ld de,es_fcb : ld c,33 : call BDOS : or a : ret
es_n    db 0
es_ok   db 0
es_k    db 0
es_ad   dw 0
es_cd   db 0
es_dl   db 0,1,2,3,#FF                                         ; current, A:, B:, C:
es_fcb  db 0,"UFO2    ENC" : ds 24
ens_end
        ENT
ens_img_end
ENS_N   equ ens_img_end-ens_img
        ASSERT ENS_N <= EN_SAV-ENS_W2 && EN_SAV+ENS_N <= #C000
