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
PLAYER_COLOR:           equ     0x2C        ; Amarillo


;--------------------------------Teclas--------------------------------
LEFT_KEY:               equ     0x4B
RIGHT_KEY:              equ     0x4D
UP_KEY:                 equ     0x48
DOWN_KEY:               equ     0x50
; Tecla de reinicio
U_KEY                   equ     0x16
; Tecla de pausa
P_KEY                   equ     0x19

BOOT:
    ; Set mode 0x13 (320x200x256 VGA)
    mov     ax, 0x0013
    mov     bx, 0x0105
    int     0x10

START:
    mov word [current_color], BASE_COLOR
    mov byte [current_level], 0x01
    mov byte [destr_tanks], 0x0
    ; Empieza en el centro
    mov word [player_x], 0x00A0
    mov word [player_y], 0x0060

GAME_LOOP:
    ; i = 0
    xor     dx, dx
    ; 16px de padding
    add     dx, 0x0010
    ; j = 0
    xor     cx, cx
    ; 32px de padding
    add     cx, 0x0020

DESTROYED_TANKS_COUNT:
    ; Cargar el mensaje de tanques destruidos
    mov     si, DESTROYED_TANKS
    ; Function teletype
    ; http://www.ctyme.com/intr/rb-0106.htm
    mov     ah, 0x0E

DESTROYED_TANKS_CHAR:
    ; Carga el byte actual en SI y aumentar la direccion
    lodsb
    ; Verificar si ya termino de recorrer la cadena 
    cmp     al, 0
    je      LEVEL_MSG
    int     0x10
    ; Siguiente caracter
    jmp     DESTROYED_TANKS_CHAR

LEVEL_MSG:
    ; Mostrar la cantidad de tanques destruidos
    mov     al, '0'
    add     al, [destr_tanks]
    int     0x10

    push    dx

    ; Configurar el cursor en la fila 1 y columna 0
    mov     ah, 0x02
    xor     bh, bh
    mov     dh, 0x01
    xor     dl, dl
    int     0x10

    pop     dx

    mov     ah, 0x0E
    ; Cargar el mensaje de nivel actual
    mov     si, CURRENT_LEVEL_MSG

LEVEL_MSG_CHAR:
    ; Carga el byte actual en SI y aumentar la direccion
    lodsb
    ; Verificar si ya termino de recorrer la cadena 
    cmp     al, 0
    je      DONE
    int     0x10
    ; Siguiente caracter
    jmp     LEVEL_MSG_CHAR

DONE:
    ; Mostrar el nivel actual
    mov     al, '0'
    add     al, [current_level]
    int     0x10

    push    dx

    ; Configurar el cursor en la fila 0 y columna 0
    mov     ah, 0x02
    xor     bh, bh
    xor     dh, dh
    xor     dl, dl
    int     0x10

    pop     dx

CHECK_KEY:
    ; Leer el status de la entrada
    mov     ah, 0x01        
    int     0x16
    ; Si no hay una tecla
    jz      MAZE_ROW_LOOP

GET_KEY:
    ; Leer el caracter
    mov     ah, 0x0
    int     0x16

    ; Si es una u se reinicia el juego
    cmp     ah, U_KEY
    je      START

CHECK_UP:
    cmp     ah, UP_KEY
    jne     CHECK_DOWN
    sub byte [player_y], TILE_SIZE

CHECK_DOWN:
    cmp     ah, DOWN_KEY
    jne     CHECK_LEFT
    add byte [player_y], TILE_SIZE

CHECK_LEFT:
    cmp     ah, LEFT_KEY
    jne     CHECK_RIGHT
    sub byte [player_x], TILE_SIZE

CHECK_RIGHT:
    cmp     ah, RIGHT_KEY
    jne     MAZE_ROW_LOOP
    add byte [player_x], TILE_SIZE

MAZE_ROW_LOOP: ; for i in range(ROWS)
    cmp     dx, ROWS
    ; if (i != ROWS)
    jne     MAZE_COL_LOOP
    ; Reiniciar
    jmp     GAME_LOOP

MAZE_COL_LOOP: ; for j in range(COLS)
    cmp     cx, COLS
    ; if (j != COLS)
    jne     DRAW_TILE

    ; j = 0
    xor     cx, cx
    ; 32px de padding
    add     cx, 0x0020
    ; i += TILE_SIZE
    add     dx, TILE_SIZE
    ; Siguiente fila
    jmp     MAZE_ROW_LOOP

DRAW_TILE:
    ; Sprite de mxn (8x8)
    mov     ax, TILE_SIZE
    mov     bx, TILE_SIZE
    mov word [current_color], BASE_COLOR

    ; if (j == player_x
    cmp     cx, [player_x]
    jne     SET_BG_COLOR
    ; && i == player_y)
    cmp     dx, [player_y]
    je      SET_PLAYER_COLOR

    ; else
    jmp     SET_BG_COLOR

SET_PLAYER_COLOR:
    add byte [current_color], PLAYER_COLOR
    jmp     DRAW_TILE_ROW

SET_BG_COLOR:
    add byte [current_color], BG_COLOR

DRAW_TILE_ROW:
    ; if (ax > 0)
    cmp     ax, 0
    jg      DRAW_TILE_COL
    ; j += TILE_SIZE
    add     cx, TILE_SIZE
    
    ; Siguiente columna
    jmp     MAZE_COL_LOOP

DRAW_TILE_COL:
    ; if (bx != 0)
    cmp     bx, 0x0
    jne     DRAW_PIXEL

    ; bx = TILE_SIZE
    mov     bx, TILE_SIZE
    ; ax++
    dec     ax
    jmp     DRAW_TILE_ROW

DRAW_PIXEL:
    push    cx
    push    dx

    add     dx, ax
    add     cx, bx

    push    ax

    ; Dibujar sprite
    mov word ax, [current_color]
    push    bx
    xor     bx, bx
    int     0x10

    pop     bx
    pop     ax
    pop     dx
    pop     cx

    dec     bx
    jmp     DRAW_TILE_COL

; mov eax,cr0
; or eax,1
; mov cr0,eax

; Tanques destruidos
destr_tanks             db      0x0
; Nivel actual de 1 - 3
current_level           db      0x0
; Desde el origin de la columna
player_x:               dw      0x0
; Desde el origin de la fila
player_y:               dw      0x0
DESTROYED_TANKS:        db      "Tanques: ", 0
CURRENT_LEVEL_MSG:      db      "Nivel:   ", 0
current_color:          db      0x0
; Padding
times 510 - ($-$$)      db      0x0
; Se convierte en un sector booteable
                        dw      0xAA55
