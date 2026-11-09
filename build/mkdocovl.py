# NedoOS: UFO2DOC.OVL - UFO2DOC.COM (SEADOC, data/extra) as the game's overlay (nedo.asm n_doc loads it at #0100
# with the menu's memory saved; mnu.asm mm_doc). The COM's #0A90..#0D83 decrypted here (its start XORs each byte with
# its address' low byte and R: 2 + 22 * n - the decryptor's loop), the decryptor skipped; then:
# - its BDOS calls (CALL 5: NedoOS's kernel) -> n_bdos (#F000, page 3: the game's CP/M layer);
# - the BIOS (WBOOT at (#0001): ATM CP/M's #F800 - CONST #F803, CONIN #F806, CONOUT #F809, #F812): n_doc puts a
#   table of its own at #F800 (page 3) - (#0001) read as #F800;
# - its stacks (#0ED7; the BIOS calls' #00FF - over the game's page zero) -> #9EF0, #9F70 (past the longest text,
#   UFO2.INS: #1092..#9992); the font's FCB (#006C - CP/M's, NedoOS's kernel's page zero) -> #9E00;
# - the screen's pages (W3: #C0F7 / #FFF7 = #7A page 5, #7E page 1 - ATM's 640x200) -> P_W3 (#F7F7), the real
#   screen pages #FA, #FE (zxl.asm PS5, PS1 | #80); #7C (page 3) as it is.
#   python3 mkdocovl.py UFO2DOC.COM UFO2DOC.OVL
import sys

src, dst = sys.argv[1], sys.argv[2]
b = bytearray(open(src, 'rb').read())
B = 0x100


def at(a, old, new):
    o = a - B
    assert b[o:o + len(old)] == bytes(old), '%04X: %s, not %s' % (a, b[o:o + len(old)].hex(), bytes(old).hex())
    b[o:o + len(new)] = bytes(new)


# the encrypted part
for i, a in enumerate(range(0x0A90, 0x0D84)):
    b[a - B] ^= (a & 0xFF) ^ ((2 + 22 * i) & 0x7F)
assert b[0x0D7D - B:0x0D84 - B] == bytes([0x31, 0xD7, 0x0E, 0xFB, 0xC3, 0xEB, 0x0F]), 'not decrypted'
at(0x0136, [0xC3, 0x84, 0x0D], [0xC3, 0x7D, 0x0D])          # JP #0D84 (the decryptor) -> #0D7D (its way on)
at(0x0100, [0x31, 0xD7, 0x0E], [0x31, 0xF0, 0x9E])          # LD SP,#0ED7
at(0x0D7D, [0x31, 0xD7, 0x0E], [0x31, 0xF0, 0x9E])
at(0x046E, [0x31, 0xFF, 0x00], [0x31, 0x70, 0x9F])          # (the BIOS calls' stack)
for a in (0x0471, 0x047E):
    at(a, [0x2A, 0x01, 0x00], [0x21, 0x00, 0xF8])          # LD HL,(#0001) -> LD HL,#F800
for a, old in ((0x099F, 0x6C), (0x09A2, 0x6D), (0x09AF, 0x6C), (0x09B7, 0x6C), (0x09E9, 0x6C)):
    o = a - B
    assert b[o] in (0x21, 0x11) and b[o + 1:o + 3] == bytes([old, 0]), '%04X' % a
    b[o + 1:o + 3] = bytes([old - 0x6C, 0x9E])              # the font's FCB: #9E00
n = 0
for o in range(len(b) - 2):                                  # CALL 5
    if b[o:o + 3] == b'\xCD\x05\x00':
        b[o + 1:o + 3] = b'\x00\xF0'; n += 1
assert n == 16, n
n = 0
for o in range(len(b) - 2):                                  # the W3 port, its pages
    if b[o] == 0x01 and b[o + 1] == 0xF7 and b[o + 2] in (0xC0, 0xFF):
        b[o + 2] = 0xF7; n += 1
        for p in list(range(o - 2, o - 1)) + [o + 3]:
            if b[p] == 0x3E and b[p + 1] in (0x7A, 0x7E):
                b[p + 1] |= 0x80
assert n == 24, n
for o in range(len(b) - 1):                                  # (none left)
    if b[o] == 0x3E and b[o + 1] in (0x7A, 0x7E):
        raise SystemExit('%04X: page %02X left' % (o + B, b[o + 1]))
at(0x0A09, [0xF3], [0x00])                                  # its letter's DI (W3 = the screen's page meanwhile:
                                                             #  on_int, mnu.asm dm_ih keep W3 - the music's ticks not lost)
# its screen's clearing (#04E1: PUSH over the screen, DI for its whole time - the music's ticks lost at each page) ->
# LDIR with the interrupts on, at #0741 (its extended memory's copiers: never called)
at(0x04E1, [0x21, 0x40, 0x1F], [0xC3, 0x41, 0x07])
assert b[0x0741 - B] == 0xE5 and b[0x0794 - B] == 0xE5
at(0x0741, list(b[0x0741 - B:0x0774 - B]), [
    0x01, 0xF7, 0xF7, 0x3E, 0xFA, 0xED, 0x79, 0xAF, 0xCD, 0x61, 0x07,      # page 5 (the points): 0
    0x01, 0xF7, 0xF7, 0x3E, 0xFE, 0xED, 0x79, 0x3E, 0x07, 0xCD, 0x61, 0x07,  # page 1 (the attributes): 7
    0x01, 0xF7, 0xF7, 0x3E, 0x7C, 0xED, 0x79, 0xFB, 0xC9,                 # W3 = page 3, EI
    0x21, 0x00, 0xC0, 0xCD, 0x6A, 0x07, 0x21, 0x00, 0xE0,                 # #0761: #C000.., #E000.. (8000 each)
    0x77, 0x54, 0x5D, 0x13, 0x01, 0x3F, 0x1F, 0xED, 0xB0, 0xC9])          # #076A
# the screen saver's way out (a key: #F812 doesn't take it) -> CONIN (#F806: the key taken - one page on, not two;
# its ESC: back to the menu)
at(0x0E17, [0xC3, 0x8E, 0x04], [0xC3, 0x06, 0xF8])
assert b[0x02F5 - B:0x02F7 - B] == b'\xFB\xC9'               # (EI : RET - n_doc's n_vec while it runs)
open(dst, 'wb').write(b)
print('%s: %d bytes' % (dst, len(b)))
