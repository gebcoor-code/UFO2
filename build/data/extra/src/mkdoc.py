# UFO2DOC.COM (SEADOC): the screen saver replaced (seadoc_fx.asm -> fx.bin at #0C55, fx2.bin at #0DAB).
# #0A90..#0D83 is encrypted (the start XORs it with R and IXL, #0D84): key = the original's bytes XOR its decrypted
# image (run the decryptor in an emulator), the new part XORed with the same key.
