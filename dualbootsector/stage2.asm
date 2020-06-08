[BITS 16]
[ORG 0x0000]      ; This code is intended to be loaded starting at 0x1000:0x0000
                  ; Which is physical address 0x10000. ORG represents the offset
                  ; from the beginning of our segment.

; Our bootloader jumped to 0x1000:0x0000 which sets CS=0x1000 and IP=0x0000
; We need to manually set the DS register so it can properly find our variables
; like 'var'

mov ax, cs
mov ds, ax       ; Copy CS to DS (we can't do it directly so we use AX temporarily)

mov bx, var
mov ah, 0x0e
mov al, [bx]
xor bh, bh       ; BH = 0 = Display on text mode page 0
int 0x10
jmp $

var:
db 'X'

; Padding
; Extend the second stage to (720K - 512 bytes) 
; bootload.bin will take up first 512 bytes 
times 737280 - 512 - ($ - $$) db 0