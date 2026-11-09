; ------------------------------------------------------------------ the EGA view: ZX bank 7 -> 320x200x16, two buffers
; Buffers: A = pages 1, 5 (#7FFD D3 = 0), B = pages 3, 7 (D3 = 1); W1 = the lower page, W2 = the upper one.
; A line has 4 parts of 40 bytes (part 0: W1 +0, 1: W2 +0, 2: W1 +#2000, 3: W2 +#2000); ZX byte cx of line y is
; byte y*40 + cx in each part (picture at x 0..255, y 4..195; the panel at x 256..319).
; The game marks what it changed (drow / dlin: groups of 8 columns and lines of each character row); the marked
; group-lines are compared with the shadow (SHP / SHA) and converted into the back (hidden) buffer:
;  - 1..2 bytes changed: byte by byte (.chg: LUT[pair][attribute]);
;  - more: the whole group-line from tables of the attribute (page TPG: 15 slots of 4 x 256 bytes = the output
;    byte of each part for each pixel byte), written with PUSH (8 bytes of a part = 4 x PUSH BC).
; What changed in the back buffer (bsync) is copied into the other buffer after the flip (psync, row by row before
; anything else is converted into that row). The back buffer is shown (#7FFD at the next interrupt) when nothing is
; marked and nothing is to be copied any more (or, changes going on, agef frames after the last flip - not after a
; whole-screen change: fast).
BUDGET  equ 400                 ; (old)
N_IDLE  equ 1                   ; passes at most
B_IDLE  equ 110                ; work per interrupt: the game idle (a unit ~ 1000 T, measured)
B_FAST  equ 1500                ; after a whole-screen change, until it is shown
fast    db 0
B_BUSY  equ 45                  ; the game busy
bmax    dw B_BUSY
bhalf   dw B_BUSY/2
TPG     equ 53                  ; attribute tables (13 slots), their code at #F400 (tpg.asm)
UPG     equ 54                  ; the panel's code (DISP #C000)
XPG     equ 63                  ; more of it (xpg.asm, DISP #C000; far_x)
NSLOT   equ 13
crow    db 0
cs_tg   db 0
bf      db 0                    ; 1: B is shown
fready  db 0                    ; 1: the back buffer is complete (with the cursor): show it at the next interrupt
bchg    db 0                    ; 1: the back buffer changed
agef    equ #3DEC               ; (mx.asm hk_mx: 20 frames from the first change, the fight 25 from the flip)
age     db 0                    ; the frame (ifr) of the last flip / of the last step with nothing changed (mx.asm hk_mx)
; (window 0's page zero #0040..#00FF and #3D40..#3DFF: arrays cleared at the start, not in the COM)
SYN     equ 25                  ; rows of the copy grid (24 used in state B: y 4 + 8 r; 25 in state A: y 8 r)
        IFDEF NEDOOS
SYB     equ #3E00               ; (NedoOS: #0040.. is the kernel's; CP/M's IM2 table's place)
        ELSE
SYB     equ #0040
        ENDIF
bsync   equ SYB                 ; (2 x SYN) changed in the back buffer: groups, lines (at + SYN)
psync   equ SYB+#32             ; (2 x SYN) to copy from the front into the back buffer (bsync..dlin together: scr_init)
drow    equ SYB+#64             ; (24) marked: groups of the row (bit 0: columns 0..7)
dlin    equ SYB+#7C             ; (24) marked: lines of the row (must follow drow)
sy_off  db 4                    ; the grid's first line: 4 (state B, the geoscape), 0 (state A)
sy_n    db 24                   ; its rows: 24, 25
drnext  db 0
drn_a   equ cs_pad                      ; (state A's: cs_ei's slot's last byte, zxl.asm)
budget  dw 0
tnext   db 0                    ; the next slot to use
nslot   db NSLOT                ; slots in use (8 in the wide fight: 8..12 = its field's shadow)
cdone   db 0                    ; 1: conv_marks did all the marked rows

; ---- mapping
; W1, W2 = buffer A (A = 0) or B, W3 = ZX bank 7
map_buf call mb_12 : ld a,7 : jp map_w3
; A = 0 / 1: buffer A / B -> W1, W2 only (W3 kept: sync_row is called from TPG's code too - tpg.asm bc_cv)
mb_12   or a : jr nz,1F
        WIN P_W1, PS1
        WIN P_W2, PS5
        ret
1       WIN P_W1, PS3
        WIN P_W2, PS7
        ret
map_front
scr_map ld a,(bf) : jr map_buf
map_back
        ld a,(bf) : xor 1 : jr map_buf
scr_unmap
        WIN P_W1, PG_ZX+5
        WIN P_W2, PG_ZX+2
        ld a,(cur) : jp map_w3
; W3 = page A (keeps all but A)
; map_w3p: in window 0's page zero (mus.asm lowb: W3V kept)
; HL = code in the panel page: call it with W3 = UPG, then W3 = ZX bank 7
far_ui  push af : ld a,UPG : call map_w3p : pop af
        call 1F
        push af : ld a,7 : call map_w3 : pop af : ret
1       jp (hl)

; ---- show the back buffer; then the old front is the back one: its cursor off, what changed is to be copied
do_flip ld a,(bf) : xor 1 : ld (bf),a
        rlca : rlca : rlca : SHOWSCR
        call swaprec
        ld hl,bsync : ld de,psync : ld b,2*SYN
1       ld a,(de) : or (hl) : ld (de),a : ld (hl),0 : inc hl : inc de : djnz 1B
        xor a : ld (bchg),a : ld (fready),a : ld (fast),a : ld a,(ifr) : ld (age),a
        jp bcur_hide
; Z: nothing is marked / nothing to copy
marks_left
        ld hl,drow : ld b,24 : jr 1F
psync_left
        ld hl,psync : ld b,SYN
1       xor a
2       or (hl) : inc hl : djnz 2B
        or a : ret

; ---- copying the marked group-lines of row A from the front into the back buffer (the back one stays mapped)
sr_r    db 0
sr_g    db 0
sr_l    db 0
sync_row
        ld (sr_r),a
        ld hl,psync : add a,l : ld l,a : jr nc,1F : inc h
1       ld a,(hl) : ld (hl),0 : or a : ret z
        ld (sr_g),a
        ld de,SYN : add hl,de : ld a,(hl) : ld (hl),0 : ld (sr_l),a
        ld a,(sr_g) : call bits : ld c,a : ld a,(sr_l) : call bits : ld b,a : xor a
4       add a,c : djnz 4B                       ; group-lines
        add a,a : ld c,a : ld b,0 : ld hl,(budget) : add hl,bc : inc hl : ld (budget),hl
        ld a,(bf) : or a : jr nz,2F
        WIN P_W1, PS1                            ; A shown: A -> B
        WIN P_W2, PS3
        call sr_pass
        WIN P_W1, PS5
        WIN P_W2, PS7
        jr 3F
2       WIN P_W1, PS3                            ; B shown: B -> A
        WIN P_W2, PS1
        call sr_pass
        WIN P_W1, PS7
        WIN P_W2, PS5
3       call sr_pass
        ld a,(bf) : xor 1 : call mb_12          ; the back buffer (W3 as it was: bc_cv returns into TPG's page)
        ; the front's cursor is in what was copied: its background over it
        ld a,(cs_on) : or a : ret z
        ld a,(cs_y) : ld (sr_y),a
        ld ix,cs_buf : ld c,CS_H
4       ld a,(sy_off) : ld b,a : ld a,(sr_y) : sub b : jr c,6F : cp 200 : jr nc,6F
        ld b,a : rrca : rrca : rrca : and #1F : ld hl,sr_r : cp (hl) : jr nz,6F    ; not this row
        ld a,b : and 7 : call gbit : ld hl,sr_l : and (hl) : jr z,6F                ; this line not copied
        ld a,(sr_y) : call yoff
        push bc
        ld a,(cs_p0) : ld c,a : ld b,5 : push ix
5       ld a,c : cp 160 : jr nc,7F
        rrca : rrca : rrca : rrca : rrca : and 7 : call gbit : ld hl,sr_g : and (hl) : jr z,7F   ; column's group
        ld a,c : call paddr : ld a,(ix+0) : ld (hl),a
7       inc c : inc ix : djnz 5B
        pop ix : pop bc
6       ld de,5 : add ix,de : ld hl,sr_y : inc (hl)
        dec c : jr nz,4B
        ret
sr_y    db 0
; parts +0 and +#2000 of the group-lines of row (sr_r), W1 -> W2
sr_pass ld a,(sr_l) : ld (sr_lm),a
        ld a,(sy_off) : ld b,a : ld a,(sr_r) : add a,a : add a,a : add a,a : add a,b : ld (sr_yy),a
        ld b,8
1       ld hl,sr_lm : rrc (hl) : jr nc,3F
        push bc
        ld a,(sr_yy) : ld l,a : ld h,0 : add hl,hl : add hl,hl : add hl,hl : ld d,h : ld e,l : add hl,hl : add hl,hl : add hl,de
        ld a,(sr_g) : ld c,a : ld b,5
2       rrc c : call c,cpg
        ld de,8 : add hl,de : djnz 2B
        pop bc
3       ld hl,sr_yy : inc (hl)
        djnz 1B
        ret
sr_lm   db 0
sr_yy   db 0
; HL = offset: 8 bytes W1 -> W2 at +0 and at +#2000 (HL, DE, BC kept)
cpg     push hl : push de : push bc
        push hl
        ld a,h : add a,#40 : ld h,a : add a,#40 : ld d,a : ld e,l
        DUP 8
        ldi
        EDUP
        pop hl
        ld a,h : add a,#60 : ld h,a : add a,#40 : ld d,a : ld e,l
        DUP 8
        ldi
        EDUP
        pop bc : pop de : pop hl : ret
; A -> the number of its bits (not 0)
bits    push bc : ld b,8 : ld c,0
1       rrca : jr nc,2F : inc c
2       djnz 1B
        ld a,c : pop bc : or a : ret nz : inc a : ret
; pending copies first (within the budget)
sync_some
        ld c,0
1       ld a,(sy_off) : or a : jr z,4F          ; (state A: no screen-7 rows, no cache)
        ld a,c : add a,low sc_rowf : ld l,a : ld h,high sc_rowf : ld a,(hl) : or a : jr nz,2F     ; (cache first)
        ld hl,drow : ld a,c : add a,l : ld l,a : jr nc,3F : inc h
3       ld a,(hl) : cp #0F : jr nz,4F : ld de,24 : add hl,de : ld a,(hl) : inc a : jr z,2F   ; whole: written later
4       ld a,c : push bc : call sync_row : pop bc
2        ld hl,(budget) : ld de,(bhalf) : or a : sbc hl,de : ret nc
        inc c : ld a,(sy_n) : ld b,a : ld a,c : cp b : jr c,1B
        ret

; ---- clear both buffers, the shadow = everything changed

; ---- the interrupt's part
conv_step
        ld bc,#FADF : in a,(c) : cpl : and 7 : ld c,a : ld a,(oldbtn) : cpl : and c : ld hl,btn_l : or (hl) : ld (hl),a  ; (new presses only; (a click while the game waits)
        ; how much: the game waiting in a HALT (the byte before the return address) -> more passes; busy -> a part
        ld hl,(i_sp) : ld e,(hl) : inc hl : ld d,(hl) : dec de : ld a,(de)
        ld hl,B_BUSY : cp #76 : jr nz,1F : ld hl,B_IDLE
1       ld a,(fast) : or a : jr z,2F : ld hl,B_FAST     ; a whole-screen change: the game waits for it
2       ld (bmax),hl : srl h : rr l : ld (bhalf),hl
.again  call cur_tgt                            ; where our cursor should be (bank 5 still mapped)
        ld a,(fready) : or a : jr z,0F : call do_flip    ; at the start of a frame
0
        call map_front : call cur_move          ; the front's cursor (on again at the end)
        call map_back
        xor a : ld (budget),a : ld (budget+1),a
        ld a,(sh_pend) : or a : jr z,3F
        ld a,(sh_go) : or a : jr z,.end         ; a scroll pending: only OUTDSC's conversion
        call sh_do
3       call sync_some
        call conv_marks
        ld a,(bchg) : or a : jr z,.pan
        call psync_left : jr nz,.pan            ; the back buffer is not complete yet
        ld a,(cdone) : or a : jr nz,1F
        ld a,(fast) : or a : jr nz,.pan          ; (a whole-screen change: shown complete only)
        ld a,(ifr) : ld hl,age : sub (hl) : ld hl,agef : cp (hl) : jr c,.pan  ; (else at most agef frames: mx.asm hk_mx)
1       call bcur_show                          ; complete: the cursor there too, shown at the next interrupt
        ld a,1 : ld (fready),a
        jr .end
.pan    call pan2
        ld a,(cap_pend) : or a : jr z,.end      ; the capture: after CAPQ steps without a whole-screen change
        dec a : jr z,1F : ld (cap_pend),a : jr .end
1       call sc_capw : ld a,(cap_pend) : or a : call nz,sc_capw
.end    call pn_fl
        call map_front : call cur_show
        call scr_unmap
        ld a,(bwide) : or a : ret z            ; the wide fight's state B: screen 7's panel and column compared
        ld a,(sy_off) : or a : ret z
        ld hl,pscan_u : jp far_g
; state A: the field rows with marks (fe_row) in turn from drnext, within the budget
conv_mA xor a : ld (cdone),a
        ld a,(drn_a) : ld c,a : ld b,FDN
5       ld a,c : cp FDN : jr c,6F : ld c,0
6       push bc
        ld a,c : ld hl,fe_row : add a,l : ld l,a : jr nc,7F : inc h
7       ld a,(hl) : or a : ld a,c : call nz,conv_rw
        pop bc : inc c
        ld hl,(budget) : ld de,(bmax) : or a : sbc hl,de : jr nc,9F
        djnz 5B
        ld a,1 : ld (cdone),a
9       ld a,c : ld (drn_a),a : ret             ; (its own: up to FDN - state B's drnext stays below 24, else
; the panel into both buffers                   ; drow + c's dlin passes #00D4: map_w3 overwritten) (the back one has no cursor now)
pan2    ld a,(bwide) : or a : ret nz           ; (the wide fight: no panel)
        ld a,(ui_red) : or a : ret z
        xor a : ld (ui_red),a
        call map_back : ld hl,ui_draw0 : call far_ui
        call map_front : call cur_hide : ld hl,ui_draw0 : jp far_ui
; the marked rows (in turn from drnext, within the budget), then one row of the slow scan
conv_marks
        ld a,(sy_off) : or a : jr z,conv_mA     ; (state A: the field's rows)
        xor a : ld (cdone),a
        ld a,(drnext) : ld c,a : ld b,24
5       push bc
        ld a,c : ld hl,drow : add a,l : ld l,a : jr nc,6F : inc h
6       ld a,(hl) : or a : jr nz,9F
        ld a,(bwide) : or a : jr z,7F           ; the wide fight's field marks (state A)
        ld a,(bst) : or a : jr nz,7F
        push hl : ld de,fe_row-drow : add hl,de : ld a,(hl) : pop hl : or a : jr z,7F
9       ld a,c : call held : jr c,7F
        ld a,(hl)
        ld (cmask),a : ld (hl),0
        ld de,24 : add hl,de : ld a,(hl) : ld (lmask),a : ld (hl),0   ; (dlin)
        inc a : jr nz,1F : ld a,(cmask) : cp #0F : jr nz,1F : ld (full),a     ; the whole row: all out, no copy
1       ld a,c : call conv_rs
7       pop bc
        inc c : ld a,c : cp 24 : jr c,8F : ld c,0
8       ld hl,(budget) : ld de,(bmax) : or a : sbc hl,de : jr nc,9F      ; enough for this frame
        djnz 5B
        ld a,1 : ld (cdone),a                   ; all the marks done (new ones are for the next picture)
9       ld a,c : ld (drnext),a
        ld a,(cdone) : or a : ret z             ; the slow scan: only with the marks done, every 2nd time
        ld a,(bwide) : or a : ret nz            ; (not in the wide fight: no shadow there)
        ld hl,cs_tg : inc (hl) : bit 0,(hl) : ret z
        ld a,#0F : ld (cmask),a : ld a,#FF : ld (lmask),a
        ld a,(crow) : call held : call nc,conv_rs
        ld a,(crow) : inc a : cp 24 : jr c,2F : xor a
2       ld (crow),a
        ret
; row A: its pending copy first, then converted
; one group (bit G) of the line: HL = source, DE = shadow at its start -> at its end
        MACRO CGRP G
        ld a,(cmask) : and G : jr z,13F         ; not marked
        ld a,(frc) : and G : jr nz,12F          ; its attribute changed: all out
        call c_cnt : jr z,13F                   ; the same
        cp 3 : jr nc,12F
        call c_few
        ld a,(lgrp) : or G : ld (lgrp),a        ; (for the other buffer too)
        jr 14F
12      call c_all
        ld a,(fmask) : or G : ld (fmask),a
        jr 14F
13      ld a,l : add a,8 : ld l,a : ld a,e : add a,8 : ld e,a
14
        ENDM
; how many of the 8 bytes (HL source, DE shadow) changed -> A (Z: none; HL, DE kept)
; 1..2 changed (C): byte by byte -> HL, DE at the end
; all 8 into the shadow (output after the line's groups) -> HL, DE at the end
crw     xor a : ld (full),a : pop af : jp conv_rw      ; (the wide fight: its pending copy there)
conv_rs push af : ld a,(bwide) : or a : jr nz,crw
        pop af : push af
        ld hl,sc_rowf : add a,l : ld l,a : jr nc,1F : inc h
1       ld a,(hl) : or a : jr z,2F : ld (hl),0
        pop af : push af : call sc_try          ; groups found in the screen cache: out of cmask
        ld a,(cmask) : or a : jr z,4F
        cp #0F : jr z,2F
        xor a : ld (full),a                     ; (some found: the rest as usual)
        jr 2F
4       ld (full),a : pop af : ret              ; (all from the cache)
2       ld a,(full) : or a : jr nz,3F
        pop af : push af : call sync_row : pop af : jp conv_row
3       pop af : push af                        ; the whole row is written: its pending copy is not needed
        ld hl,psync : add a,l : ld l,a : jr nc,5F : inc h
5       ld (hl),0 : ld de,SYN : add hl,de : ld (hl),0
        pop af : jp conv_row
; A = character row r, (cmask), (lmask)
cr      db 0
cl      db 0
lm      db 0
lbit    db 0
lgrp    db 0
lmask   db #FF                  ; lines of the row to convert (bit 0: line 0)
full    db 0                    ; #0F: the next conv_rs writes the whole row (no copy, no compare)
frc     db 0                    ; row: groups with a changed attribute
cmask   db #0F                  ; groups of 8 columns to convert (bit 0: columns 0..7)
src     dw 0
shd     dw 0
dst     dw 0
arow    dw 0
rt_src  dw 0

rt_ok   db 0                    ; 1: row_tabs done for this row
fmask   db 0                    ; line: groups to output from the tables
; in TPG (page 53, only its code uses them)
col_hk  equ #FE00               ; row: col_h + part (4 x 32)
col_h   equ #FE80               ; (32) row: high byte of the attribute tables of each column
guni    equ #FEA0               ; (4) row: 1 = the group has one attribute (3: ink = paper too - tpg.asm rt_sol)
gtyp    equ #FEA4               ; (4)
gsv     equ #FEA8               ; (2)

; ---- the screen cache (sc.asm, page UPG)
CAPQ    equ 50
cap_pend db 0                   ; a restore was done: the next complete picture goes into the cache
sc_rowf equ #3F20               ; (24) rows of a whole-screen change: first looked for in the cache (free: IM2 table ends #3F00)
; A = row: its groups found in the cache done, out of cmask (W1, W2 = back again)
; after a whole-screen change: its rows into the cache one by one (the back buffer and the shadow agree on a row
; with nothing to copy into it; the back has no cursor when no flip is ready)
cap_r   db 0
