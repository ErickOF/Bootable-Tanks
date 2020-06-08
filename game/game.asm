bits 16
; Direccion de inicio
[org 0x7C00]

;------------------------------CONSTANTES------------------------------
; Pantalla de 320x200x256
ROWS                    equ     184         ; 200 - 16
COLS                    equ     288         ; 320 - 32
TILE_SIZE               equ     8           ; Sprites de 8x8

;-------------------------------Colores--------------------------------
; Se usa una representacion de 8 bit para cada color de la forma
; RRRGGGBB
; Hay una imagen llamada 8bit_color_mode.png con todos los colores
; posibles, si quieren cambiar un color, solo buscan la fila i y la
; columna j y el valor decimal sera, lo convierten a hex
; y ese es el color que usan, y tiene que usarse BASE_COLOR + el color
; que se obtuvo
BASE_COLOR              equ     0x0C00      ; Black
BG_COLOR:               equ     0x09        ; Azul
WALL_COLOR:             equ     0x02        ; Verde
PLAYER_COLOR:           equ     0x05        ; Amarillo


;--------------------------------Teclas--------------------------------
LEFT_KEY:               equ     75
RIGHT_KEY:              equ     77
UP_KEY:                 equ     72
DOWN_KEY:               equ     80



; User related variables
; Constants
side        equ     8d       ; Side of the square
user_speed  equ     8d       ; User movement speed
; Variables
pos_x: dw 100d               ; Offset from the origin column    
pos_y: dw 20d               ; Offset from the origin row  

color: db 5d                ; Color of the rectangle

jmp _start


;--------------------------------User input--------------------------------
check_for_key:
    ; === check for player commands:
    mov     ah, 0x01        ; Set int 16h to read input status
    int     16h             ; Call the int
    jnz     decode_key      ; if there is a key then process it
    ret     ; Else return to caller   

decode_key:

    mov     ah, 00h         ; Set int 16h to read the character
    int     16h             ; Call the int

    push    bx              ; Store the contents


    cmp     ah, UP_KEY      ; If UP_KEY then move up  
    jne     check_down      ; else check down
    mov     bx, [pos_y]     ; Load pos_y
    sub     bx, user_speed  ; Update pos
    mov     [pos_y], bx     ; Store the value

check_down:
    cmp     ah, DOWN_KEY    ; If DOWN_KEY then move down
    jne     check_left      ; else check down
    mov     bx, [pos_y]     ; Load pos_y
    add     bx, user_speed  ; Update pos
    mov     [pos_y], bx     ; Store the value

check_left:
    cmp     ah, LEFT_KEY    ; If LEFT_KEY then move left
    jne     check_right      ; else check down
    mov     bx, [pos_x]     ; Load pos_y
    sub     bx, user_speed  ; Update pos
    mov     [pos_x], bx     ; Store the value

check_right:
    cmp     ah, RIGHT_KEY   ; If d then move right
    jne     check_space      ; else check down
    mov     bx, [pos_x]     ; Load pos_y
    add     bx, user_speed  ; Update pos
    mov     [pos_x], bx     ; Store the value

check_space:
    cmp     al, SPACE_KEY   ; If SPACE_KEY then shoot
    ; TODO: SHOOT 

check_l:
    cmp     al, L_KEY       ; If L_KEY then pause
    ; TODO: PAUSE GAME

check_L:
    cmp     al, L_CAP_KEY   ; If L_CAP_KEY then pause
    ; TODO: PAUSE GAME

check_r:
    cmp     al, R_KEY       ; If R_KEY then re-start 
    ; TODO: RESTART GAME


check_R:
    cmp     al, R_CAP_KEY   ; If R_CAP_KEY then re-start 
    ; TODO: RESTART GAME


    pop     bx

    ret     ; Return to caller




;--------------------------------Drawing--------------------------------

draw_horizontal_line: 
    mov     ah, 0ch     ; Set up pixel write mode
    int     10h         ; Call interrupt
   
    dec     cx                      ; Decrease the x position
    cmp     cx, [pos_x]             ; Check if we finished
    jae     draw_horizontal_line    ; If we are not done keep drawing 

    ret             ; Return to caller

setup_draw_values:
    
    mov     cx, [pos_x]     ; Position in x of the tile
    add     cx, side        ; Side lenght
    mov     dx, [pos_y]     ; Position in y of the tile
    mov     al, [color]     ; Color of the tile

    ret     ; Return to caller


draw_square:
    ; Set up video mode
    mov     ah, 0h      ; Set up the interrupt for video mode
    mov     al, 13h     ; Set a 320x200 using 256-color VGA
    int     10h         ; Call int

    push    esp         ; Store the return adress
    call    setup_draw_values       ; Set up values in variables
    xor     bx, bx      ; i = 0

fill_square:            ; Fill the figure

    call    draw_horizontal_line   ; Draw the line
    call    setup_draw_values      ; Reset positions
    add     dx, bx          ; Add offset in y
    inc     bx              ; ++i
    cmp     bx, side        ; if (i < 20)
    jle     fill_square     ; i < 20

    pop     esp     ; Recover return adress     
    ret             ; Return to caller







;--------------------------------Main loop--------------------------------
_start:

    call    draw_square     ; Call square draw function
    call    check_for_key   ; Check for user input

    jmp     _start

; mov eax,cr0
; or eax,1
; mov cr0,eax

CURRENT_COLOR:          db      0x0
PLAYER                  db      0b00000000,0b00000000,0b00000000,0b00000000,0b00000000
; Padding
times 510 - ($-$$)      db      0x0
; Se convierte en un sector booteable
                        dw      0xAA55
