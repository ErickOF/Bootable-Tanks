[BITS 16]                   ;   This is used to indicate a 16 bit code
[ORG 0x7C00]                ;   This is used in order to load the Bootloader by the BIOS post interrupt 0x19 at this address

jmp start                   ;   Jump to label start
start:  
     call loadSecondSector ;  Load the second sector to memory 
     jmp 0x200:0000;       ;  and jumps to the address of the game (tanks)

loadSecondSector:
     mov ax, 0x200 ;    Sets where data from RAM where USB data is read
     mov es, ax    ;    Copy the value to a register
     mov cl, 2     ;    Sets the USB sector where game is written
     mov al, 4     ;    Sets to copy game contained in 4 segments of the USB
     mov bx, 0     ;    Offset of memory
     mov dl, 0x80  ;    Set the drive number
     mov dh, 0     ;    Head number
     mov ch, 0     ;    Cylinder number
     mov ah, 02h   ;    Read function
     int 0x13      ;    Interrupt
     ret           ;    If failure, return to where it started

TIMES 510 - ($-$$) db 0 ;   Bytes needed for padding, fills the rest with zeros
dw 0xaa55 ; BIOS signature