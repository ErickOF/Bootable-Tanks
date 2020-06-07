org 0x7C00                  ; BIOS loads our programm at this address
bits 16                     ; We're working at 16-bit mode here

check_for_key:
    ; === check for player commands:
    mov     ah, 0x01        ; Set int 16h to read input status
    int     16h             ; Call the int
    jz      check_for_key   ; if there is no key, call again   

decode_key:

    mov     ah, 00h         ; Set int 16h to read the character
    int     16h             ; Call the int


    cmp     al, 0x77        ; If w then move up
    je      print_key       ; Jump to routine
    cmp     al, 0x57        ; If W then move up
    je      print_key       ; Jump to routine  

    cmp     al, 0x73        ; If s then move down
    je      print_key       ; Jump to routine
    cmp     al, 0x53        ; If S then move down
    je      print_key       ; Jump to routine

    cmp     al, 0x61        ; If a then move left
    je      print_key       ; Jump to routine
    cmp     al, 0x41        ; If A then move left
    je      print_key       ; Jump to routine

    cmp     al, 0x64        ; If d then move right
    je      print_key       ; Jump to routine
    cmp     al, 0x44        ; If D then move right
    je      print_key       ; Jump to routine

    cmp     al, 0x20        ; If space then shoot
    je      print_key       ; Jump to routine

    cmp     al, 0x70        ; If p then pause
    je      print_key       ; Jump to routine
    cmp     al, 0x50        ; If P then pause
    je      print_key       ; Jump to routine

    cmp     al, 0x75        ; If u then re-start 
    je      print_key       ; Jump to routine
    cmp     al, 0x55        ; If U then re-start 
    je      print_key       ; Jump to routine

    jmp     check_for_key   ; If invalid key then keep waiting


print_key:                  ; If there is a valid input, print the key

    mov     ah, 0x0E        ; Set up character write in TTy mode           
    int     10h             ; Call the int
    jmp     check_for_key


;; Magic numbers
times 0200h - 2 - ($ - $$)  db 0    ;Zerofill up to 510 bytes
dw 0AA55h                           ;Boot Sector signature