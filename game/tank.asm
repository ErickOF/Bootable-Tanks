bits 16
; Direccion de inicio
[org 0x7C00]

; cx -> x
; dx -> y

;------------------------------CONSTANTES------------------------------
; Pantalla de 320x200x256
ROWS                    equ     184
COLS                    equ     288
TILE_SIZE               equ     8          ; Sprites de 10x10

;-------------------------------Colores--------------------------------
; Se usa una representacion de 8 bit para cada color de la forma
; RRRGGGBB
; Hay una imagen llamada 8bit_color_mode.png con todos los colores
; posibles, si quieren cambiar un color, solo buscan la fila i y la
; columna j y el valor decimal sera (i * 15 + j), lo convierten a hex
; y ese es el color que usan
BG_COLOR:               equ     0x0C09      ; Azul
PLAYER_COLOR:           equ     0x02        ; Verde


;--------------------------------Teclas--------------------------------
LEFT_KEY:               equ     75
RIGHT_KEY:              equ     77
UP_KEY:                 equ     72
DOWN_KEY:               equ     80


BOOT:
    ; Set mode 0x13 (320x200x256 VGA)
    mov ax, 0x0013
    mov bx, 0x0105
    int     0x10

GAME_LOOP:
    ; i = 0
    xor     dx, dx
    ; 16px de padding
    add     dx, 0x0010
    ; j = 0
    xor     cx, cx
    ; 32px de padding
    add     cx, 0x0020

MAZE_ROW_LOOP:
    cmp     dx, ROWS
    ; if (i < ROWS)
    jne     MAZE_COL_LOOP
    ; Reiniciar
    jmp     GAME_LOOP

MAZE_COL_LOOP:
    cmp     cx, COLS
    ; if (j < COLS)
    jne     DRAW_TITLE

    ; j = 0
    xor     cx, cx
    ; 32px de padding
    add     cx, 0x0020
    ; i += TILE_SIZE
    add     dx, TILE_SIZE
    ; Siguiente fila
    jmp     MAZE_ROW_LOOP

DRAW_TITLE:
    ; Dibujar sprite
    mov     ax, BG_COLOR
    xor     bx, bx
    int     0x10

    ; j++
    add     cx, TILE_SIZE
    
    ; Siguiente columna
    jmp     MAZE_COL_LOOP

; mov eax,cr0
; or eax,1
; mov cr0,eax

; Padding
times 510 - ($-$$)      db      0x0
; Se convierte en un sector booteable
                        dw      0xAA55
