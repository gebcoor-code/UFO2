; UFO2.COM: ZX Spectrum 128 layer for ATM Turbo 2+ CP/M: runs a 128K snapshot (in UFO2.DAT) of "НЛО-2"
; - ZX banks 0..7 -> ATM RAM pages 8..15 (window #C000 via #FFF7); #4000 = bank 5, #8000 = bank 2
; - the game's OUT (#7FFD) sites are patched into CALL zx_mem (found by pattern in the snapshot)
; - the ZX screen in bank 7 is converted into the 320x200 16-colour screen (pages 1 and 5), 256x192 in the middle,
;   a few character rows per interrupt, only what changed
; - our code, tables, the shadow copy of the screen and the interrupt table live in window 0 (#0100..#3FFF)
        device zxspectrum128
        org #100
        jp start
        ; vectors for the game built from the sources (build/mods.py)
        jp zx_dread                             ; #0103 D_READ
        jp zx_dwrite                            ; #0106 D_WRITE
        jp ui_mouse                             ; #0109 MOUSE
        jp zx_yn                                ; #010C YES_NO
        jp zx_alexq                             ; #010F ALEX: 3D off -> return "UFO damaged"
        jp zx_view                              ; #0112 VIEWSR end
        jp lay_geo                              ; #0115 MLOOP: the geoscape (EGA 320x200 with the panel)
        jp lay_zxm                              ; #0118 SEABAT, BATTL1: the fights (ZX screen mode)
ega     db 0                                    ; #011B 1: EGA view (the game's ARROW draws nothing then)
        call mkv                                ; #011C HL = an address on screen 7 was computed (SCOORD...)
        call mkv                                ; #011F the whole screen 7 changed (mk_cy -> mk_all)
        call mkv                                ; #0122 PUTATR: rows H .. H+C-1 (if screen 7's attributes)
        jp mk_ln                                ; #0125 lines A .. A+B-1 changed, groups C
        call mkv                                ; #0128 SCOORD: HL = address (one character)
        call mkv                                ; #012B PUTSIM done: rows H.., columns L.., B x C
        call mkv                                ; #012E PUTSPR done: line H, x L, B bytes x C lines
        call mkv                                ; #0131 PUTSCR done: line H, column L, B bytes x C lines
        jp lay_scrl                             ; #0134 SCROLL: the text window moved one line up
        jp lay_scre                             ; #0137 SCROLL: done
        jp lay_band                             ; #013A MRK1: band DSCR (HL) -> SCR, lines A.., B lines
        jp lay_fd2                              ; #013D MS2: HL = DSCR, B lines x 2 bytes
        jp lay_fd1                              ; #0140 LS2, RS2: HL, B lines x 1 byte
        jp lay_fdc                              ; #0143 CURHER: HL, B bytes x C lines
        jp lay_fall                             ; #0146 scrolls: all the field
        jp lay_fpad                             ; #0149 POFF: DE = DSCR, 64 lines x 2 bytes
        jp lay_outd                             ; #014C OUTDSC (after MEM7)
        jp lay_prog                             ; #014F the fight's RAM SAVE / LOAD: progress (D = attribute, B = 32..1)
tuinf   db 0                                    ; #0152 1: a fight from LOC GO - time units not spent
        jp mk_off                               ; #0153 OFFS: screen 7 cleared (marked; converted later)
        jp lay_xyhl                             ; #0156 XYHL (wide field): E = half-row, D = column -> HL
bxy     dw 0                                    ; #0159 BMOV (wide field): the map cursor's cell (BX, BY)
        jp lay_bat                              ; #015B BATTL1: a location fight starts (the wide field)
rxe     db 31                                   ; #015E ROTATE: the map cursor's right scroll edge (BX)
        jp lay_name                             ; #015F PNAM: a name's word in DSCR's row 0
        jp lay_namp                             ; #0162 COMBAT: all the crew's names (PNAM for each)
        jp lay_dsk                              ; #0165 the fight's SAVE (A = 0) / LOAD (A = 1): UFO2.BTL
bd_c1   db #FF                                  ; #0168 the last two bands MRK1 compared (each frame both: the old
bd_c2   db #FF                                  ;   and the new place); #FFFF from the game's ONOFL: a menu line inverted
        ASSERT bxy == #0159

        IFDEF NEDOOS
        include "nedo_h.inc"
BDOS    equ n_bdos
        IFNDEF NSTAGE
NSTAGE  equ 9                                   ; (the stages while porting: N1 stops at PRESS ANY KEY)
        ENDIF
        ELSE
BDOS    equ 5
        ENDIF
        IFDEF NEDOOS
CMDL    equ n_cl                                ; the command line (CP/M's: length, text)
        ELSE
CMDL    equ #0080
        ENDIF
; the screens' pages (as page numbers: #7F - PSn = the port's value): NedoOS - Evo's 1, 3, 5, 7 (#FF - page)
        IFDEF NEDOOS
PS1     equ #81
PS3     equ #83
PS5     equ #85
PS7     equ #87
        ELSE
PS1     equ 1
PS3     equ 3
PS5     equ 5
PS7     equ 7
        ENDIF
; #7FFD = A (bit 3: screen 7 / buffer B shown; BC spoilt): NedoOS - OS_SETSCREEN and its #FD value at once
        MACRO SHOWSCR
        IFDEF NEDOOS                            ; (no stack: int_f's is 4 bytes - OS_SETSCREEN at the next interrupt)
        ld b,a : and 8 : or #47 : out (#FD),a : ld (n_spend),a : ld a,b      ; (BC spoilt, as CP/M's)
        ELSE
        ld bc,#7FFD : out (c),a
        ENDIF
        ENDM
; a screen page's port value (#7F - page): NedoOS - the real screen pages (#FF - page: Evo's 1, 3, 5, 7)
        MACRO SCRV
        IFDEF NEDOOS
        or #80
        ENDIF
        ENDM
; the start's failure (after its message): CP/M - RST 0; NedoOS - a key, then back to NC
        MACRO EXIT0
        IFDEF NEDOOS
        jp n_fail
        ELSE
        rst 0
        ENDIF
        ENDM
        IFDEF SRCB
        include "gaddr_src.inc"
        ELSE
        include "gaddr_rel.inc"
        ENDIF
PG_ZX   equ 8                   ; ATM page of ZX bank 0
STAGE   equ #4000               ; 16K staging buffer while loading (CP/M page 4)
; the windows' ports: ATM #3FF7.. (6-bit pages); NedoOS on Evo BaseConf: #37F7.. (8-bit pages, see nedo.asm)
        IFDEF NEDOOS
P_W1    equ #77F7
P_W2    equ #B7F7
P_W3    equ #F7F7
        ELSE
P_W1    equ #7FF7
P_W2    equ #BFF7
P_W3    equ #FFF7
        ENDIF
H_W1    equ high P_W1
H_W2    equ high P_W2
H_W3    equ high P_W3
        MACRO WIN port, page
        ld bc,port : ld a,#7F-(page) : out (c),a
        ENDM

rbuf    equ #3900                               ; record buffer (128; LUT #3500..#38FF, SHA from #39A0)
ibuf    equ #3F00                               ; record buffer while starting (the code images reach past rbuf)
npatch  db 0
gh      dw 0
; patches for STAGE (pattern -> replacement of the same length):
;  LD BC,#7FFD : OUT (C),A                -> CALL zx_mem : NOP : NOP
;  LD BC,#7FFD : XOR A : OUT (C),A : CALL 0 (exit of the game) -> JP zx_exit
;  LD A,#3F : LD I,A (around the disk code)  -> LD A,#3E (our table stays)
;  LD A,#41 : LD I,A (the game's start)      -> LD A,#3E
;  3D fight (LESHA #B000): the end of VIEWSR (shadow -> screen 7) JP PT128 -> JP zx_view
;  XIOD (disk overlay at #7580): D_READ #7C72, D_WRITE #7C4A -> JP zx_dread / zx_dwrite, TR000 -> RET
ptab    db 5, #01,#FD,#7F,#ED,#79 : db #CD : dw zx_mem : db 0,0
        db 9, #01,#FD,#7F,#AF,#ED,#79,#CD,#00,#00 : db #C3 : dw zx_exit : db 0,0,0,0,0,0
        db 4, #3E,#3F,#ED,#47 : db #3E,#3E,#ED,#47
        db 4, #3E,#41,#ED,#47 : db #3E,#3E,#ED,#47
        IFNDEF SRCB
        db 7, #F3,#CD,#82,#7B,#CD,#1F,#41 : db #C3 : dw zx_dread : db 0,0,0,0          ; XIOD D_READ
        db 8, #F3,#CD,#82,#7B,#E5,#C5,#0E,#5F : db #C3 : dw zx_dwrite : db 0,0,0,0,0   ; XIOD D_WRITE
        db 5, #F3,#DD,#21,#5F,#2F : db #C9,#DD,#21,#5F,#2F                            ; XIOD TR000 (head to track 0)
        db 9, #C2,#58,#B5,0,0,0,#C3,#5F,#46 : db #C2,#58,#B5,0,0,0,#C3 : dw zx_view    ; 3D fight: VIEWSR end
        db 10, #21,#00,#C9,#11,#01,#C9,#75,#01,#B1,#17 : db #C3 : dw zx_alex : db #11,#01,#C9,#75,#01,#B1,#17  ; ALEX
        ENDIF
        db 0
ptab_e
patch   ld hl,STAGE : ld (p_st),hl : ld hl,#4000 : ld (p_len),hl
; patch (p_len) bytes from (p_st)
patch_rng
        ld ix,(ptab_p)                          ; (ptab; debug LOC GO: its copy + L_L2's in rbuf - xpg.asm dbg_loc)
1       ld a,(ix+0) : or a : ret z
        ld (pt_n),a
        ld hl,(p_st) : ld bc,(p_len)
2       ld a,(ix+1) : cpir : jp nz,.next        ; first byte not found any more: next pattern
        dec hl : push bc : push hl
        ld a,(pt_n) : ld b,a : push ix : pop de : inc de
3       ld a,(de) : cp (hl) : jr nz,4F
        inc de : inc hl : djnz 3B
        pop hl : push hl : ex de,hl                     ; (DE: the replacement - past the pattern)
        ld a,(pt_n) : ld c,a : ld b,0 : ldir
        ld a,(npatch) : inc a : ld (npatch),a
4       pop hl : pop bc : inc hl
        ld a,b : or c : jr nz,2B
.next   ld a,(pt_n) : add a,a : inc a : ld e,a : ld d,0 : add ix,de
        jr 1B
pt_n    db 0
p_st    dw 0
p_len   dw 0

; the game's decompressor DELPC (HL source, DE destination) unpacks overlays with OUT (#7FFD) inside:
; its first instruction jumps here; we do its start, call the rest, then patch what it wrote
dl_ok   db 0
d_hl    dw 0                                    ; (dsk's)
d_sp    dw 0
        ds #020D-$
; (the game's DI meanwhile - its loads take seconds: the AY's channels off first, no note held; the music's next tick
; puts them back)
zx_delpc
        ld (p_st),de
        ld bc,#FFFD : ld a,7 : out (c),a : ld b,#BF : ld a,#3F : out (c),a  ; (A, BC: its start sets them)
        push de : ld de,DLPCB : ld bc,4 : ldir : pop de      ; = the replaced start
        call xpD0
        push af : push bc : push de : push hl : push ix
        ld hl,(p_st) : ex de,hl : or a : sbc hl,de : ld (p_len),hl  ; DE (end) - start
        call patch_rng
        pop ix : pop hl : pop de : pop bc : pop af
        ret
; check the decompressor of this version, then hook it

; ------------------------------------------------------------------ disk (XIOD) through a CP/M file
; UFO2.DAT = the release disk (TRD order: logical track = cylinder*2 + side, 16 sectors of 256) without the
; parts the game never reads: tracks 0..15 (saved game at track 4, table at 5), then tracks 55..127 (data files)
; D_READ / D_WRITE: E = sector 1..16, D = track, B = sectors, HL = address; out: DE, HL advanced, B = 0, CY = 0
d_ok    db 0
d_op    db 0
d_cnt   db 0
d_de    dw 0
; find UFO2.DAT: the current drive, then B:, A:, C:, D: (only drives the BIOS has: SELDSK HL <> 0); CY = found

zx_dwrite
        ld a,34 : jr dsk
zx_dread
        ld a,33
dsk     di
        ld (d_op),a
        ld (d_sp),sp : ld sp,#3FC0
        ld (d_de),de : ld (d_hl),hl : ld a,b : ld (d_cnt),a
        ld a,d : cp 4 : jr nz,0F : ld a,e : dec a : jr nz,0F : ld a,(d_op) : cp 33 : call z,d_load
0
        ld a,(d_cnt) : or a : jr z,.done
.sec    call ram_sec
        ld hl,(d_hl) : inc h : ld (d_hl),hl
        ld de,(d_de) : inc e : ld a,e : cp 17 : jr c,1F
        ld e,1 : inc d
1       ld (d_de),de
        ld a,(d_cnt) : dec a : ld (d_cnt),a : jr nz,.sec
.done   ld de,(d_de) : ld hl,(d_hl) : ld b,0
        ld sp,(d_sp)
        xor a : ret


; a conversion step with interrupts on (int_h's own, od_conv's: they may take frames): the music's ticks go on
; through int_f meanwhile (W3 as W3V says: the conversion maps W3 only through map_w3p; TPG's line_out with its SP
; fills keeps them off itself)
cs_ei   ld de,conv_step
cs_ed   ld hl,(#3D3E) : push hl                 ; (DE = the conversion's routine: conv_all's conv_marks too)
        ld hl,int_f : ld (#3D3E),hl
        ei : call 1F : di
        pop hl : ld (#3D3E),hl : ret
1       ex de,hl : jp (hl)
cs_pad  ds 26-(cs_pad-cs_ei)                    ; (zx_mem stays at #02CA: the game's patched CALLs in UFO2.BTL point there)
        ASSERT zx_mem == #02CA
        ASSERT zx_delpc == #020D                ; (JP zx_delpc in the game's DELPC: in UFO2.BTL too)

; ------------------------------------------------------------------ ZX memory
; the game's OUT (#7FFD),A: A bits 0-2 = bank at #C000 (bit 3 screen 7 is always shown here, bit 4 ROM: ignored)
zx_mem  push af : and 7 : ld (cur),a : call map_w3 : pop af
        ld bc,#7FFD : ret
; A = ZX bank -> window 3
; map_w3: in window 0's page zero (mus.asm lowb)
; A = ZX bank -> A = ATM page (bank 7, the screen: page 15 while loading / in the EGA view, page 5 = shown in ZX mode)
bk_pg   push hl : ld hl,bpage : add a,l : ld l,a : jr nc,1F : inc h
1       ld a,(hl) : pop hl : ret
bpage   db 8,9,10,11,12,13,14,15

; ---- video: ATM's own ZX screen mode (page 5) while playing; the EGA view (320x200 with the panel) on demand
; port #FD77 (A9 = 0: shadow ports stay open, A8 = 1 mapper on): D7 = 1, D5 = 1 INT, D3 = 1 turbo, D2..D0 = mode
VM_ZX   equ #AB                         ; %011: ZX 256x192
VM_EGA  equ #A8                         ; %000: EGA 320x200
VM_TXT  equ #AE                         ; %110: text 80x25 (CP/M's)
        IFDEF NEDOOS
vmode   push hl : ld hl,n_vm3 : call n_p3 : pop hl : ret        ; (OS_SETGFX: the kernel sets #BD77 each interrupt)
        ELSE
vmode   ld bc,#FD77 : out (c),a : ret
        ENDIF
; copy page D -> page E (via W2 / W3; caller restores them), DI
; bank 7 -> page 5, ZX mode (own stack, interrupts as they were)
; bank 7 -> page 15, EGA view: converted picture + the panel
; back to ZX mode from the EGA view
cur     db 0
; CP/M's pages 3 (W3) and 7 back from 51, 52 (the second screen buffer was there); W3 = page 3 at the end
PG_S3   equ 51
PG_S7   equ 52
PG_S5   equ 22                  ; CP/M's page 5 (its BIOS's RAM: #4000 when ROM2 = 1) and 1, after ESC M0
PG_S1   equ 23
; the game: the geoscape starts (MLOOP) - the EGA view; a fight starts - ZX screen mode (registers kept)
lay_geo push af : call mus_geo : ld a,(bwide) : or a : call nz,bat_off
        xor a : ld (cap_pend),a : ld a,(infight) : or a : jr z,0F : xor a : ld (tuinf),a   ; back from a fight
0       xor a : ld (s_hold),a : ld (infight),a : call kb_mode
        ld a,(ega) : or a : call z,ega_on
        pop af : ret
; XT/AT keyboard controller (i8031) mode A: 0 = ZX keyboard matrix, 2 = CP/M codes (sequence #55, #08, mode via A8-A15)
kb_t    db 25
kb_mode
        IFDEF NEDOOS                            ; (Evo: no ATM keyboard controller)
        ret
        ELSE
        push bc : ld c,a
        ld a,#55 : in a,(#FE)
        ld a,#08 : in a,(#FE)
        ld a,c : in a,(#FE)
        pop bc : ret
        ENDIF

; the game exits (LD BC,#7FFD : XOR A : OUT (C),A : CALL 0): back to CP/M

; the game's handler: (I*256 + #FF)

; ------------------------------------------------------------------ interrupt: a part of the screen, then the game's handler
; (#3FC0..#3FFF: free for the game's stack - with our hooks it may go a little below #4000 in the fights)
int_h   ld (i_sp),sp : ld sp,#3FC0
        push af : push bc : push de : push hl : push ix
        ld hl,ifr : inc (hl)                    ; (frames: x_kb)
        ld hl,bd_t : dec (hl) : jr nz,2F : ld (hl),16     ; MRK1's bands: compared again every 16 frames
        ld hl,#FFFF : ld (bd_c1),hl
2       ld hl,kb_t : dec (hl) : jr nz,1F        ; the keyboard controller: ZX matrix again every 25 frames
        ld (hl),25 : xor a : call kb_mode       ; (with its "ATM mode" the mouse stopped in the fights)
1
        call ui_int                             ; (the music first: at the frame's start, done before the next one)
        ld a,(ega) : or a : call nz,cs_ei
        pop ix : pop hl : pop de : pop bc : pop af
        ld sp,(i_sp)
        push hl : ld hl,(gh) : ex (sp),hl : ret          ; jp (gh) keeping HL
i_sp    dw 0
ifr     db 0

; the 3D fight runs with interrupts off: after each copy of its picture to screen 7, convert the whole screen
; 3D off: the fight is "won" at once (A = 1, CY: the UFO is damaged) - return from ALEX itself
; the whole screen now (for code that runs with interrupts off): own stack, DI meanwhile, registers kept
conv_all
        ld a,(ega) : or a : ret z               ; ZX mode: the hardware shows screen 7
        ld (v_sp),sp : ld sp,#3FB0
        push af : push bc : push de : push hl : push ix
        ld a,i : push af : di
        ld a,(pend) : or a : jr z,3F
        xor a : ld (pend),a : inc a : ld (ui_red),a     ; a start asked meanwhile: forget it
3       call cur_tgt
        ld a,(fready) : or a : call nz,do_flip
        call map_back
        xor a : ld (budget),a : ld (budget+1),a
        ld a,(bwide) : or a : jr z,.ca5         ; the wide fight (no shadow): only what is marked
        ld hl,#7FFF : ld (bmax),hl : ld (bhalf),hl
        ld a,(sh_pend) : or a : call nz,sh_do
        ld de,sync_some : call cs_ed : ld de,conv_marks : call cs_ed : jr .ca6  ; (interrupts on: the music)
.ca5    ld hl,drow : ld b,48
4       ld (hl),0 : inc hl : djnz 4B
        xor a
1       push af : ld a,#0F : ld (cmask),a : ld a,#FF : ld (lmask),a : pop af : push af : call conv_rs : pop af : inc a : cp 24 : jr c,1B
.ca6    ld hl,ov_fl3w : call far_ui               ; (the overlays, the text layer - as a step's end; not in the 3D view)
        ld a,(bchg) : or a : jr z,8F
        call bcur_show : call do_flip           ; shown at once
8       call pan2
        call map_front : call cur_move
        call cur_show
        call scr_unmap
        pop af : jp po,2F : ei
2       pop ix : pop hl : pop de : pop bc : pop af
        ld sp,(v_sp)
        ret
v_sp    dw 0

; ------------------------------------------------------------------ screen: ZX bank 7 -> 320x200x16 (pages 1, 5)
; pair byte: left pixel colour c -> (c&7) | (c&8)<<3, right -> (c&7)<<3 | (c&8)<<4
; pages: 1 = pairs 0,4,8.. (+0) and 2,6,10.. (+#2000); 5 = pairs 1,5,9.. (+0) and 3,7,11.. (+#2000); 40 bytes a line
; ZX byte (y, cx) -> line y+4, pairs 16+4cx .. 19+4cx: offset (y+4)*40 + 4 + cx in each of the four parts
LUT     equ #3500               ; 4 tables (pixel pairs 00 01 10 11) x 256 attributes
SHP     equ #1D00               ; shadow of the pixels (6144, by rows: r*256 + l*32 + cx)
SHA     equ #39A0               ; shadow of the attributes (768, up to the fight's stack #3CA0)
OVPG    equ 21                  ; window 0's overlay (ovl.asm) kept here

        include "scr.asm"
; ---- the text window (rows 15..23) scrolls (SCROLL, xlix: 8 steps of one line, a frame each): converting each
; step would take a few frames, so the window is converted once, when the text line has moved up completely
s_hold  db 0                                    ; rows 24 - s_hold .. 23 not converted: 9 - 15..23 (the console),
                                                ; 24 - all (wideu.asm pn_bclr: a fight's whole screen till the game polls)
lay_scrl                                        ; (B = 0: a step - rows 15..23 held; else the console's query - uipage.asm)
        push hl : ld hl,scl_u : call far_g : pop hl : ret
lay_scre                                        ; (the lines marked, the text map scrolled: text.asm tx_scr; the
        push hl : ld hl,scr_u : call far_g : pop hl : ret       ;  console's line: mx.asm tw_beg)
; A = row -> CY: not to be converted now
held    push bc : ld b,a : ld a,(s_hold) : add a,b : cp 24 : ccf : ld a,b : pop bc : ret   ; (C: row A held - A + s_hold >= 24)

; ---- MRK1's band: B lines from HL (DSCR, line A) to SCR (+#3000); in the EGA view only the changed bytes are
; written, and only their lines and groups are marked (the band is copied in every pass of the menu's loop)
bd_sp   dw 0
; HL -> the next line of the screen layout, (bd_y) + 1
bd_y    db 0
bd_m    db 0
bd_t    db 1

; ---- marks (from the game's code: all registers kept)
; HL = address on screen 7: pixels -> its row and the next two, columns' group and the next; attributes -> its cell
; the mark vectors (call mkv at #011C..#0131): the routine in UPG by the vector (HL, AF, the rest kept)
mkv     ex (sp),hl : ld (mkv_r),hl : pop hl
        push af : ld a,UPG : call map_w3p : pop af
        call mkv_u
        push af : ld a,(cur) : call map_w3 : pop af : ret
mkv_r   dw 0
; A = 0..3 -> A = 1 << A
gbit    push hl : ld hl,gbt : add a,l : ld l,a : jr nc,1F : inc h
1       ld a,(hl) : pop hl : ret
gbt     db 1,2,4,8,16,32,64,128
; A = first row, B = rows, C = groups (A, B changed)
mk_rows push hl : push de
        push af : ld a,(ega) : or a : jr nz,3F : pop af : jr 2F     ; ZX screen mode: nothing to do
3       pop af
1       cp 24 : jr nc,2F
        ld e,a : ld d,0 : ld hl,drow : add hl,de : push af : ld a,c : or (hl) : ld (hl),a
        ld e,24 : add hl,de : ld (hl),#FF : pop af
        inc a : djnz 1B
2       pop de : pop hl : ret
mk_all
mk_off  push af : push bc
        ld a,1 : ld (fall),a
        ld a,(ega) : or a : jr z,1F : ld (fast),a                   ; (a fight's too: shown complete only - "?")
        ld a,(infight) : or a : jr nz,1F
        ld a,MPG : call map_w3p : call mo_mx : ld a,(cur) : call map_w3   ; (the EGA view, not a fight: mx.asm)
1       ld a,(bwide) : ld (bst),a              ; the wide fight: a whole screen-7 picture (state B)
        push hl : or a : ld hl,pn_bclr : call nz,far_g : pop hl     ; (state A's lines 0..3, 196..199 black)
        xor a : ld b,24 : ld c,#0F : call mk_rows
        pop bc : pop af : ret
; SCOORD: HL = address on screen 7 -> its character cell
; PUTATR: H = row, L = column, B = width, C = height (screen 7's attributes)
; PUTSIM: the same, pixels of screen 7
; PUTSPR: H = line, L = x (pixels), B = bytes, C = lines; PUTSCR: L = column (bytes)
; L = first column, B = width -> A = groups (0: none)
; D = first row, E = last row, A = groups
; A = first column, C = last column (0..31) -> A = groups (bits)
; lines A .. A+B-1, groups C
mk_ln   push af : push bc : push de : push hl
        ld e,a : add a,b : jr c,1F : cp 193 : jr c,2F
1       ld a,192
2       ld d,a                                  ; D = end line (exclusive), E = line
3       ld a,e : cp d : jr nc,9F
        ld a,e : rrca : rrca : rrca : and #1F : ld l,a : ld h,0 : ld b,h : push bc : ld bc,drow : add hl,bc : pop bc
        ld a,c : or (hl) : ld (hl),a            ; groups
        ; lines e&7 .. min(7, end-1 - row*8)
        ld a,e : and 7 : ld b,a                 ; first line in the row
        ld a,e : or 7 : inc a : cp d : jr c,4F : ld a,d     ; end of this row's part
4       sub e : push af                         ; count
        ld a,b : call gbit : ld b,a : pop af    ; B = first bit, A = count
        push de : ld e,0
5       ld d,a : ld a,e : or b : ld e,a : sla b : ld a,d : dec a : jr nz,5B
        ld a,l : add a,24 : ld l,a : jr nc,6F : inc h
6       ld a,e : or (hl) : ld (hl),a
        pop de
        ld a,e : or 7 : inc a : ld e,a : jr 3B
9       pop hl : pop de : pop bc : pop af : ret

        include "field.asm"
        include "wide.asm"
        include "ui.asm"
        include "ram.asm"
ptab_p  dw ptab                                 ; (patch_rng's table: here - zx_mem / zx_delpc keep their places)
iv_c    db 0                                    ; OUTDSC's count (shift2.asm sk_go2): xtil.asm's draw sequences
code_end                                        ; (resident: up to BDSC)
ovl_start
        include "ovl.asm"
ovl_end
        display "overlay ",ovl_start,"..",ovl_end
        ASSERT ovl_end <= SHP
        display "code end ",code_end, " (must be below ", BDSC, ")"
        ASSERT code_end <= BDSC
; ------------------------------------------------------------------ the start (only once: the shadow is here later)
; ------------------------------------------------------------------ messages
        IFDEF NEDOOS
m_hello db 13,10,"UFO2. NedoOS EGA edition vn0.12 (0.67.13) by ae485, 2026",13,10,"$"
        ELSE
m_hello db 13,10,"UFO2. CPM EGA edition v0.67.13 by ae485, 2026",13,10,"$"
        ENDIF
m_hdbg  db "DEBUG VERSION (service buttons, LAZY)",13,10
m_load  db "Loading...$"
m_ldg   db "Unpacking...$"
sdbg    db 0                            ; 1: "UFO2 DEBUG" (the command line)
m_bad   db 13,10,"UFO2.DAT: no snapshot in it",13,10,"$"
m_mode  db 27,"M0",27,"Z0$"             ; (CP/M told: EGA - its BIOS sets #FD77 to its mode while it works)
m_nodat db 13,10,"UFO2.DAT (disk image) not found on A:..D:",13,10,"$"
m_1m    db 13,10,"1024K only",13,10,"$"
m_crlf  db 13,10,"$"

; ------------------------------------------------------------------ start
start
        IFDEF NEDOOS
        jp n_start                              ; (nedo.asm: the pages, the windows, the interrupts' chain; then here)
start_n
        ELSE
        ld sp,#00FE                         ; (the code images reach past #3F00: out first, then the stack there)
        ENDIF
        call a_dbg                              ; "DEBUG" in the command line (#0080: before the stack grows there)
        IFNDEF NEDOOS
        ld a,i : ld (cpm_i),a
        call im_det
        ENDIF
        IFDEF NEDOOS
        di : ld sp,#C000                        ; (as CP/M's #00FE: not on the images (img_out maps W3 only): past
        ENDIF                                   ;  n_start's code - nb_img's copy there, in page 3 now)
        call img_out
        di                                      ; (CP/M's interrupt pushes on our stack: page zero's #00D4.. would be hit)
        call low_out                            ; window 0's page zero: map_w3, the fights' interrupt handler (mus.asm)
        ld sp,#3FFE
        ei
        ld a,(sdbg) : or a : jr z,0F
        ld de,m_hello : ld c,9 : call BDOS
        ld de,m_hdbg : ld c,9 : call BDOS       ; (debug: the text start, no picture)
0
        call d_probe : ld a,(mem1m) : or a : jr nz,0F
        ld de,m_1m : ld c,9 : call BDOS : EXIT0
0
        call d_open                             ; UFO2.DAT (A:..D:): the snapshot, the panels, the disk image
        jr c,1F
        ld de,m_nodat : ld c,9 : call BDOS : EXIT0
1       call mus_ld                             ; the music: the player, the intro (INTRO.PT3) while loading
        IFDEF NEDOOS
        IF NSTAGE >= 2
        call st_mnu
        ENDIF
        ELSE
        call st_mnu                             ; (0.60.0) the original's start menu (UFO2.MNU; not with DEBUG)
        ENDIF
        ld a,(sdbg) : or a
        call z,t_show                           ; UFO2.IMG beside it: the title picture (EGA) while loading
        xor a : ld (dfcb+32),a : ld hl,ibuf+128 : ld (gp),hl
        ; header 27 bytes
        ld hl,hdr : ld b,27
2       call getb : ld (hl),a : inc hl : djnz 2B
        call getb : ld (gpc),a : call getb : ld (gpc+1),a       ; (v72: PC, #7FFD, TR-DOS flag right after it)
        call getb : ld (g7ffd),a : call getb
        ld a,(g7ffd) : and 7 : ld (gbank),a
        ; the banks (packed blocks): 5, 2, the paged one, then the others
        ld a,5 : call ld_bank
        ld a,2 : call ld_bank
        ld a,(gbank) : call ld_bank
        ; the other banks in order 0..7 without 2, 5 and the paged one
        ld c,0
3       ld a,c : cp 2 : jr z,4F : cp 5 : jr z,4F
        ld hl,gbank : cp (hl) : jr z,4F
        push bc : call ld_bank : pop bc
4       inc c : ld a,c : cp 8 : jr c,3B
        ld a,(nbad) : or a : jr z,5F
        ld de,m_bad : ld c,9 : call BDOS : EXIT0
5       call p_load                             ; the fight's panels (the file's next records)
        call d_preload                          ; the disk image (the rest)
        call mx_load                            ; MPG's MX code (mx.asm: UFO2.DAT's last block)
        ld a,(d_ram) : or a : jr nz,7F
        EXIT0                                   ; (UFO2.DAT incomplete)
7       ld a,(sdbg) : or a : call z,t_wait      ; "PRESS ANY KEY": the intro till a key / its end (0.67.10: DEBUG - not)
        IFDEF NEDOOS
        IF NSTAGE == 1
        jp n_quit
        ENDIF
        ENDIF
        call t_ldg                              ; "Loading..." (the rest of the start)
        call mus_go                             ; the intro off; page MUSPG: the player, the map's / the sea's music
        call xs_load                            ; UFO2.SPR: the coloured fighters (pages SPG, SPG2)
        call ico_load                           ; UFO2.ICO: the items' / signs' pictures (ico.asm), the panels' cells
        call tx_init                            ; the text layer (text.asm; before xt_load: STAGE)
        call xt_load                            ; UFO2.TIL: the coloured port's tiles (TLPG, TLPG2; its page 4's part stays in STAGE)
        call s_load                             ; UFO2.SAV: the saved game, if there
        IFNDEF NEDOOS                           ; (CP/M's pages 1, 3, 5, 7 kept for its return; NedoOS: not ours)
        call save_pg
        ENDIF
        di : WIN P_W3, MPG : call mk_lmx : WIN P_W3, 3 : ei     ; the LUT (its code in MPG: mx.asm)
        ld a,(tshow) : or a : jr nz,8F
        ld de,m_mode : ld c,9 : call BDOS
8
        IFNDEF NEDOOS
        call save_p15
        ENDIF
        ld a,(tshow) : or a : call nz,t_clr
        di
        ld hl,bsync : ld de,bsync+1 : ld bc,dlin+24-bsync-1 : ld (hl),0 : ldir   ; (arrays: bsync.. dlin; #00D4..: mus.asm lowb)
        IFDEF NEDOOS
        ld hl,lowa_img : ld de,LOWA : ld bc,lowa_img_end-lowa_img : ldir      ; (int_f..: the start's menu's place - now)
        ENDIF
        ld hl,#3D40 : ld de,#3D41 : ld bc,#BF : ld (hl),0 : ldir                  ; (the cursors, fdrow)
        ld a,(sdbg) : ld (DBG),a                                                  ; (#3DF0..: mus.asm)
        ld a,15 : ld (FADE),a                                                     ; (the map's music faded in)
        ld a,#7F-MUSPA : ld (MUS_PV),a
        ; window 0's overlay -> page OVPG (bat_off brings it back after each wide fight)
        ld a,OVPG : call map_w2 : ld hl,ovl_start : ld de,#8000 : ld bc,ovl_end-ovl_start : ldir
        ; our IM2 table: #3E00..#3F00 = #3D -> #3D3D
        IFNDEF NEDOOS
        ld hl,#3E00 : ld de,#3E01 : ld bc,256 : ld (hl),#3D : ldir
        ENDIF
        ld a,#C3 : ld (#3D3D),a : ld hl,int_h : ld (#3D3E),hl
        ; windows: W1 = bank 5, W2 = bank 2, W3 = the paged bank
        WIN P_W1, PG_ZX+5
        WIN P_W2, PG_ZX+2
        ld a,(gbank) : ld (cur),a : call map_w3
        IFDEF NEDOOS                            ; the game's start: LD I,A : IM 2 -> IM 1 (nedo.asm's chain: IM 1 only)
        ld hl,(G_START+6) : ld de,#47ED : or a : sbc hl,de : jr nz,1F
        ld hl,(G_START+8) : ld de,#5EED : or a : sbc hl,de : jr nz,1F
        ld a,#56 : ld (G_START+9),a
1
        ENDIF
        ld a,7 : call map_w3 : ld hl,#C000 : ld de,#C001 : ld bc,#1AFF : ld (hl),0 : ldir     ; (no title picture: black)
        ld a,(gbank) : call map_w3
        IFDEF NEDOOS                            ; (the palette black till the EGA view - ovl.asm ega_on: the ZX
        di : call pal_blk : ei                  ;  screen's drafts, the copy not seen)
        ENDIF
        call zx_on                              ; bank 7 -> page 5, ATM ZX screen mode
        ld a,0 : call kb_mode                   ; keyboard controller: ZX matrix (CP/M leaves it in mode 2)
        ld a,(hdr+0) : ld (gi),a                ; the game's I
        call find_h
        ; the mouse on (PMOUSE = 1), if the control settings are where this version keeps them (KEYS = #40A8)
        ld hl,(G_KEYS) : ld de,G_KBR : or a : sbc hl,de : jr nz,1F
        ld a,1 : ld (G_PMOUSE),a
1       ld bc,#FBDF : in a,(c) : ld (G_OLDCO),a        ; OLDCO = the mouse counters now (no jump)
        ld b,#FF : in a,(c) : ld (G_OLDCO+1),a
        call hook_delpc
        IFNDEF SRCB
        call hook_mouse
        call hook_yn
        ; Kempston joystick: port #1F on the ATM under CP/M is not a joystick (phantom directions): always keys
        ld a,(G_CONTRJ) : cp #28 : jr nz,1F
        ld a,#18 : ld (G_CONTRJ),a              ; CONTR: JR Z,CO1 -> JR CO1
1
        ENDIF
        xor a : ld (G_KEYJOY),a                 ; KEYJOY = 0
        ; calls into the ROM area that are not ours (TR-DOS #3D13, #3D2F...): RET
        ld hl,#3D00 : ld de,#3D01 : ld bc,#3C : ld (hl),#C9 : ldir
        IFDEF NEDOOS
        ld hl,#3D3D : ld (n_vec),hl             ; (IM 1: the chain's vector - as the IM2 table's)
        ELSE
        ld a,#3E : ld i,a : im 2
        ENDIF
        ; registers from the snapshot (SNA: I, HL' DE' BC' AF', HL DE BC IY IX, IFF2, R, AF, SP, IM, border)
        ld hl,(gpc) : ld (rs_jp+1),hl
        ld a,(hdr+19) : and 4 : ld a,0 : jr z,1F : ld a,#FB
1       ld (rs_ei),a
        ld sp,hdr+1
        pop hl : pop de : pop bc : pop af
        exx : ex af,af'
        pop hl : pop de : pop bc : pop iy : pop ix
        ld sp,hdr+21 : pop af
        ld sp,(hdr+23)
rs_ei   nop
rs_jp   jp 0

; ------------------------------------------------------------------ snapshot reading
gp      dw ibuf+128                     ; the stream's place in ibuf (#80 low: empty)
nbad    db 0
hdr     ds 27
gpc     dw 0
g7ffd   db 0
gbank   db 0
gi      db 0
; A = next byte of UFO2.DAT's stream (keeps BC, DE, HL)
getb    push hl : ld hl,(gp) : bit 7,l : call nz,gfill
        ld a,(hl) : inc l : ld (gp),hl : pop hl : ret
; the next record -> ibuf, HL = ibuf (the file's end: #80s - packed blocks end; nbad = 1)
gfill   push de : push bc
        ld de,ibuf : ld c,26 : call BDOS
        ld de,dfcb : ld c,20 : call BDOS
        ld hl,ibuf : or a : jr z,1F
        ld a,1 : ld (nbad),a
        ld b,128
2       ld (hl),#80 : inc hl : djnz 2B
        ld hl,ibuf
1       pop bc : pop de : ret
; A = ZX bank: read 16K, patch, put into its page
ld_bank ld (lb_n),a
        push bc : call dot : call lz_blk : pop bc
        ld a,(lb_n)
put_bank
        ld (lb_n),a
        call patch
        di
        ld a,(lb_n) : call bk_pg : ld b,a : ld a,#7F : sub b
        ld bc,P_W2 : out (c),a
        ld hl,STAGE : ld de,#8000 : ld bc,#4000 : call fcopy
        ld bc,P_W2 : ld a,#7F-2 : out (c),a    ; CP/M's page 2 back
        ei : ret
lb_n    db 0


; CP/M's pages 3, 7 -> 51, 52; two screen buffers
save_pg di
        ld a,PG_S3 : call map_w2 : ld hl,#C000 : ld de,#8000 : ld bc,#4000 : call fcopy
        WIN P_W3, 7
        ld a,PG_S7 : call map_w2 : ld hl,#C000 : ld de,#8000 : ld bc,#4000 : call fcopy
        WIN P_W3, 3
        ld a,2 : call map_w2 : ei : ret
; CP/M's pages 5, 1 -> PG_S5, PG_S1 (the screen buffer A uses them in the game)
save_p15
        di
        WIN P_W3, 5
        ld a,PG_S5 : call map_w2 : ld hl,#C000 : ld de,#8000 : ld bc,#4000 : call fcopy
        WIN P_W3, 1
        ld a,PG_S1 : call map_w2 : ld hl,#C000 : ld de,#8000 : ld bc,#4000 : call fcopy
        WIN P_W3, 3
        ld a,2 : call map_w2 : ei : ret
; the panel's code -> UPG; TPG: its code, no attribute tables yet (at the start, before any file read: ibuf,
; STAGE, the stack are past the images)
img_out di
        WIN P_W3, UPG
        ld hl,ui_img : ld de,#C000 : ld bc,ui_img_end-ui_img : ldir
        ld hl,ui2_img : ld de,#FAE0 : ld bc,ui2_img_end-ui2_img : ldir
        ld hl,ui3_img : ld de,#F570 : ld bc,ui3_img_end-ui3_img : ldir
        ld hl,ui4_img : ld de,#EEB0 : ld bc,ui4_img_end-ui4_img : ldir
        ld hl,ui5_img : ld de,pn2_s+PN2_NS : ld bc,ui5_img_end-ui5_img : ldir
        ld hl,ui6_img : ld de,#F280 : ld bc,ui6_img_end-ui6_img : ldir
        WIN P_W3, TPG
        ld hl,#FC00 : ld de,#FC01 : ld bc,#1FF : ld (hl),0 : ldir
        ld hl,tpg_img : ld de,#F400 : ld bc,tpg_img_end-tpg_img : ldir
        ld hl,tpg5_img : ld de,#FED0 : ld bc,tpg5_img_end-tpg5_img : ldir
        ld hl,tpg6_img : ld de,#FD10 : ld bc,tpg6_img_end-tpg6_img : ldir
        ld hl,tpg7_img : ld de,#FF40 : ld bc,tpg7_img_end-tpg7_img : ldir
        ld hl,tpg8_img : ld de,#FD8D : ld bc,tpg8_img_end-tpg8_img : ldir
        WIN P_W3, OVPG
        ld hl,tpg2_img : ld de,#E000 : ld bc,tpg2_img_end-tpg2_img : ldir    ; (fc_t2: into TPG at each fight's start)
        ld hl,tpg3_img : ld de,#E400 : ld bc,tpg3_img_end-tpg3_img : ldir
        WIN P_W3, XPG
        ld hl,xpg_img : ld de,#C000 : ld bc,xpg_img_m-xpg_img : ldir
        ld de,#DFD0 : ld bc,xpg_img_end-xpg_img_m : ldir
        ld de,#FC00 : ld bc,xpg3_end-xpg_img_end : ldir                     ; (ommap.asm)
        WIN P_W3, MPG
        ld hl,m_q : ld bc,0                     ; (obj.asm m_q, m_r: k / 44, k % 44 for k < 299)
1       ld (hl),b : inc h : inc h : ld (hl),c : dec h : dec h : inc hl
        inc c : ld a,c : cp 44 : jr c,2F : ld c,0 : inc b
2       ld a,l : cp low (m_q+299) : jr nz,1B : ld a,h : cp high (m_q+299) : jr nz,1B
        ld hl,obj2_img : ld de,mk_sv+64 : ld bc,obj2_img_end-obj2_img : ldir
        WIN P_W3, TXPG
        ld hl,txc_img : ld de,#C000 : ld bc,txc_img_end-txc_img : ldir   ; (the text layer's code: textc.asm)
        ld hl,txo_img : ld de,#D800 : ld bc,txo_img_end-txo_img : ldir
        ld hl,txl_img : ld de,tx_sw+5 : ld bc,txl_img_end-txl_img : ldir
        ld hl,txm_img : ld de,tx_rm+5 : ld bc,txm_img_end-txm_img : ldir
        ld hl,txn_img : ld de,tx_nm+5 : ld bc,txn_img_end-txn_img : ldir
        WIN P_W3, SC_P0                        ; (enl.asm: the encyclopedia's pictures from the disk - its W2 code)
        ld hl,enl_img : ld de,EN_W2+#4000 : ld bc,enl_img_end-enl_img : ldir
        ld hl,ens_img : ld de,ENS_W2+#4000 : ld bc,ENS_N : ldir
        ld hl,TMK+#4000 : ld de,TMK+#4001 : ld bc,96*32-1 : ld (hl),0 : ldir       ; (enl.asm te_mk's masks: none yet)
        WIN P_W3, EPG
        ld hl,epg_img : ld de,EPG_A : ld bc,epg_img_end-epg_img : ldir
        ld hl,xel_img : ld de,xe_far+5 : ld bc,xel_img_end-xel_img : ldir
        WIN P_W3, 3
        call xt_hdr                             ; (TLPG, TLPG2: xtil_i.asm)
        IFNDEF NEDOOS
        ei
        ENDIF
        ret
        include "ram_init.asm"
        include "title.asm"
        include "mus.asm"
        include "init_mv.asm"
init_mv_end
        ASSERT init_mv_end <= LUT               ; (hook_delpc, find_h: called after mk_lut has made the LUT)
        include "init_d.asm"
        include "mz.asm"
        include "xspr.asm"
        include "xtil.asm"
        include "mnu0.asm"
        DISPLAY "start code end: ", /H, $
        ASSERT $ <= ibuf                        ; (the start's code: below its record buffer - STAGE past it)
        include "uipage.asm"
        include "tpg.asm"
        include "tpg2.asm"
        include "obj2.asm"
        include "xtil_i.asm"
        include "textc.asm"
        include "epg.asm"
        include "enl.asm"
init_end
        display "init end ",init_end, " (must be below #BF00)"
        ASSERT init_end <= #BF00            ; (img_out copies the images first (W3 only): then ibuf, STAGE, the title, the LUT; below W3)
        ASSERT img_out < ui_img             ; (the start code itself stays below them)
        IFDEF NEDOOS
        include "nedo.asm"
n_end
        ASSERT n_code_end <= #C000                  ; (n_start's code below W3: it maps W3 while copying)
        savebin "ufo2.com",#100,n_end-#100
        ORG init_end                            ; (the images below: as CP/M's - past the COM's end they'd pass #FFFF)
        ELSE
        savebin "ufo2.com",#100,init_end-#100
        ENDIF
; ---- MPG's objects' code (obj.asm) and MX past it: UFO2.DAT's last block (build/mkdat.py: ufo2o.bin + ufo2x.bin),
; mx_load puts them there
        include "obj.asm"
        savebin "ufo2o.bin",obj_img,obj_img_end-obj_img
OBJ_N   equ obj_img_end-obj_img
MX_O    equ #0E00
mx_img
        DISP #C000+MX_O
        include "mx.asm"
        include "xexp.asm"
        include "cursor.asm"
        include "supv.asm"
        include "textr.asm"
        IFDEF SRCB
        include "uidraw.asm"
        ENDIF
        include "xrep.asm"                      ; (last: its tables past the image)
mx_end
        ASSERT mx_end <= OB_Z0
        ENT
mx_img_end
        savebin "ufo2x.bin",mx_img,mx_img_end-mx_img
MX_N    equ mx_img_end-mx_img
; ---- TLPG's hooks' part (xpnt.asm at XPA): the same block's last part, mx_load puts it there
        include "xpnt.asm"
        savebin "ufo2p.bin",xpnt_img,xpn2_img_end-xpnt_img
XP_N    equ xpnt_img_end-xpnt_img
XP2_N   equ xpn2_img_end-xpn2_img
; ---- (0.61.0) the start menu's code: UFO2.MNU's first records (build/mkmnu.py: ufo2m.bin), mnu0.asm st_mnu
        SLOT 3
        PAGE 6
        ORG #C000
mnm_img
        include "mnu.asm"                       ; (DISP MNM_A, then its stub DISP SB_A)
mnm_img_end
        savebin "ufo2m.bin",mnm_img,mnm_img_end-mnm_img
        PAGE 0
MNM_N   equ mnm_img_end-mnm_img
MNM_R   equ (MNM_N+127)/128
        ASSERT MNM_A+MNM_N <= DH_A
        display "MX end ",mx_end, " (must be below ", OB_Z0, ")"
