; ------------------------------------------------------------------ UFO2.DAT in RAM: the start only (after code_end)
pg1m    db 32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50
m_ram   db 13,10,"$"
m_nram  db 13,10,"UFO2.DAT incomplete",13,10,"$"

; 1M? (512K: page 48 an alias of page 16)
d_probe di
        ld a,16 : call map_w2 : ld a,(#8000) : ld (pr_a),a : ld a,#A5 : ld (#8000),a
        ld a,48 : call map_w2 : ld a,(#8000) : ld (pr_b),a : ld a,#5A : ld (#8000),a
        ld a,16 : call map_w2 : ld a,(#8000) : cp #5A : push af
        ld a,(pr_a) : ld (#8000),a
        pop af : jr z,1F
        ld a,48 : call map_w2 : ld a,(pr_b) : ld (#8000),a
        ld a,1 : ld (mem1m),a
        ld hl,pg1m : ld de,dpages : ld bc,NPG : ldir
1
        ld a,2 : call map_w2 : ei : ret
pr_a    db 0
pr_b    db 0

; v72: UFO2.DAT is a stream of packed blocks (build/mkdat.py; lz_blk: title.asm)
; the disk image: 19 blocks (the tracks the game reads, 4 to a page) -> dpages[0..18]
m_nopnl db 13,10,"UFO2.DAT incomplete (panels)",13,10,"$"
d_preload
        ld hl,dpages : ld b,NPG
1       push bc : push hl
        call dot : call lz_blk
        pop hl : ld a,(hl) : push hl : call st_put
        pop hl : inc hl : pop bc : djnz 1B
        ld a,(nbad) : or a : jr nz,2F
        ld a,1 : ld (d_ram),a
        ld de,m_ram : ld c,9 : jp BDOS
2       ld de,m_nram : ld c,9 : jp BDOS
; the fight's panels -> pages OPG0.. (16K each)
p_load  ld a,OPG0 : ld b,(PN2_PNL+127)/128
1       push bc : push af
        call dot : call lz_blk
        pop af : push af : call st_put
        pop af : inc a : pop bc : djnz 1B
        ld a,(nbad) : or a : ret z
        ld de,m_nopnl : ld c,9 : call BDOS : EXIT0
; obj.asm + MX (build/mkdat.py: the stream's last block) -> MPG #C000, #C000 + MX_O (W3's addresses)
; and TLPG's hooks' part (xpnt.asm) -> XPA
mx_load call dot : call lz_blk
        di : ld a,MPG : call map_w2
        ld hl,STAGE : ld de,#8000 : ld bc,OBJ_N : ldir                  ; (obj.asm's code at #C000)
        ld de,#8000+MX_O : ld bc,MX_N : ldir
        jp xp_load
; STAGE .. DE (lz_blk's end) -> page A at #0000
st_put  push af : ex de,hl : ld de,STAGE : or a : sbc hl,de : ld b,h : ld c,l : pop af
        di : call map_w2
        ld hl,STAGE : ld de,#8000 : ldir
        ld a,2 : call map_w2 : ei : ret


; CP/M's interrupt mode: #0038 -> im_hit for one interrupt (IM 1 comes there; IM 2 goes through CP/M's table)
im_det  ld a,i : ret po                         ; (interrupts off in CP/M: leave it as IM 2)
        di
        ld hl,(#0038) : ld (im_sv),hl : ld a,(#003A) : ld (im_sv+2),a
        ld a,#C3 : ld (#0038),a : ld hl,im_hit : ld (#0039),hl
        ei : halt : halt
        di
        ld hl,(im_sv) : ld (#0038),hl : ld a,(im_sv+2) : ld (#003A),a
        ei : ret
im_hit  push af : push hl
        ld a,1 : ld (cpm_im1),a
        ld hl,(im_sv) : ld (#0038),hl : ld a,(im_sv+2) : ld (#003A),a
        pop hl : pop af : jp #0038
im_sv   ds 3
