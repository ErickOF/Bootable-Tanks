[bits 16]
[ORG 0x7c00]    ; Bootloader starts at physical address 0x07c00

    ; BIOS sets DL to boot drive before jumping to the bootloader

    ; Since we specified an ORG(offset) of 0x7c00 we should make sure that
    ; Data Segment (DS) is set accordingly. The DS:Offset that would work
    ; in this case is DS=0 . That would map to segment:offset 0x0000:0x7c00
    ; which is physical memory address (0x0000<<4)+0x7c00 . We can't rely on
    ; DS being set to what we expect upon jumping to our code so we set it
    ; explicitly
    xor ax, ax
    mov ds, ax        ; DS=0

    cli               ; Turn off interrupts for SS:SP update
                      ; to avoid a problem with buggy 8088 CPUs
    mov ss, ax        ; SS = 0x0000
    mov sp, 0x7c00    ; SP = 0x7c00
                      ; We'll set the stack starting just below
                      ; where the bootloader is at 0x0:0x7c00. The
                      ; stack can be placed anywhere in usable and
                      ; unused RAM.
    sti               ; Turn interrupts back on

reset:                ; Resets floppy drive
    xor ax,ax         ; 0 = Reset floppy disk
    int 0x13
    jc reset          ; If carry flag was set, try again

    mov ax,0x1000     ; When we read the sector, we are going to read address 0x1000
    mov es,ax         ; Set ES with 0x1000

floppy:
    xor bx,bx   ;Ensure that the buffer offset is 0!
    mov ah,0x2  ;2 = Read floppy
    mov al,0x1  ;Reading one sector
    mov ch,0x0  ;Track 1
    mov cl,0x2  ;Sector 2, track 1
    mov dh,0x0  ;Head 1
    int 0x13
    jc floppy   ;If carry flag was set, try again
    jmp 0x1000:0000 ;Jump to 0x1000, start of second program

times 510 - ($ - $$) db 0       ;Fill the rest of sector with 0
dw 0xAA55   ;This is the boot signature