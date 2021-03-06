bits 16
; Direccion de inicio
[org 0x7C00]

;------------------------------CONSTANTES------------------------------
; Pantalla de 320x200x256
ROWS                    equ     184         ; 200 - 16
COLS                    equ     288         ; 320 - 32
TILE_SIZE               equ     8           ; Sprites de 8x8
PADDING_X               equ     0x0020      ; Padding used in the x dim
PADDING_Y               equ     0x0010      ; Padding used in the y dim

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
EAGLE_COLOR:            equ     0x28        ; Rojo
TANK_COLOR:             equ     0x06        ; Naranja


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
    mov byte [player_x], 0x00A0
    mov byte [player_y], 0x0060
    ; Aguila abajo en el centro
    mov byte [eagle_x], 0x00A0
    mov byte [eagle_y], 0x00B0
    ; Posicion del tanque1
    mov byte [tank1_x], 0x0020
    mov byte [tank1_y], 0x0010
    ; Posicion del tanque2
    mov word [tank2_x], 0x0118
    mov byte [tank2_y], 0x0010
    ; Posicion del tanque3
    mov byte [tank3_x], 0x0060
    mov byte [tank3_y], 0x0040
    ; Posicion del tanque4
    mov byte [tank4_x], 0x00E0
    mov byte [tank4_y], 0x0040

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


CHECK_MAZE_POS:

    ; Quick check if we are inside the padding limits
    cmp     cx, PADDING_X
    jl      CHECK_PLAYER_POS
    cmp     dx, PADDING_Y
    jl      CHECK_PLAYER_POS

    push    ax  ; Save the value for later
    push    bx  ; Save the value for later
    push    dx  ; Save the value for later
    push    cx  ; Save the value for later


    ; Divide to get the row we are in
    mov     ax, dx          ; Move pos_y into ax
    mov     dx, 0           ; Clear dividend, high
    sub     ax, PADDING_Y   ; Remove pad so we can compare in terms of tile size
    mov     cx, TILE_SIZE   ; Set the divisor
    div     cx              ; Divide ax/cx = positiony_inside_pad/Tile_len   
    ; Cociente => ax    Residuo => dx

    
    ; Prepare source dir target
    mov     cx, 0x3         ; Load the amount of values that represent a row
    mul     cx              ; ax = cx*ax = 3*current_row
    mov     si, ax          ; Store thew rows we need to jump to the value we want

    pop     cx              ; Restore the cx value
    push    cx              ; Save it again

    ; Divide to get the column we are in
    mov     ax, cx          ; Move pos_x into ax
    mov     dx, 0           ; Clear dividend, high
    sub     ax, PADDING_X   ; Remove pad so we can compare in terms of tile size
    mov     cx, TILE_SIZE   ; Set the divisor
    div     cx              ; Divide ax/cx = positionx_inside_pad/Tile_len   
    ; Cociente => ax    Residuo => dx

    mov     bx, ax          ; Store the column we are in, in bx

    ; Divide to get the memory position that describes the point we are in
    mov     dx, 0           ; Clear dividend, high
    mov     cx, 0x10        ; Set the divisor to word len
    div     cx              ; Divide ax/cx = tile/tiles_per_row   
    ; Cociente => ax    Residuo => dx

    add     si, ax          ; Get to the exact address we need
    mov     ax, bx          ; Reload the tile we are in 

    ; Map ax between [0,15]
    cmp     ax, 0x1F        ; If ax > 31
    jle     AX_SMALL       
    sub     ax, 0x20        ; Map
    jmp     VERIFY_MAZE_POS ; Jump to the comparison

AX_SMALL:

    cmp     ax, 0xF        ; If ax > 15
    jle     VERIFY_MAZE_POS       
    sub     ax, 0x10        ; Map

VERIFY_MAZE_POS:
    mov     bx, [MAZE+si]   ; Load the row we need
    not     bx              ; Leave a 1 in the place we want to check
    and     bx, ax          ; Extract the value
    cmp     bx, ax          ; Check if we have a 1 in the place we need
    
    ; Else pop and leave
    pop    cx  ; Restore the cx value
    pop    dx  ; Restore the dx value
    pop    bx  ; Restore the bx value
    pop    ax  ; Restore the ax value

    je      SET_WALL_COLOR  ; If we do means there was a 0 in the desired pos so jump
    
    


CHECK_PLAYER_POS:
    ; if (j == player_x
    cmp     cx, [player_x]
    jne     CHECK_EAGLE_POS
    ; && i == player_y)
    cmp     dx, [player_y]
    je      SET_PLAYER_COLOR

CHECK_EAGLE_POS:
    ; if (j == eagle_x
    cmp     cx, [eagle_x]
    jne     CHECK_TANK1_POS
    ; && i == eagle_y)
    cmp     dx, [eagle_y]
    je      SET_EAGLE_COLOR

CHECK_TANK1_POS:
    ; if (j == tank1_x
    cmp     cx, [tank1_x]
    jne     CHECK_TANK2_POS
    ; && i == tank1_y)
    cmp     dx, [tank1_y]
    je      SET_TANK_COLOR

CHECK_TANK2_POS:
    ; if (j == tank2_x
    cmp     cx, [tank2_x]
    jne     CHECK_TANK3_POS
    ; && i == tank2_y)
    cmp     dx, [tank2_y]
    je      SET_TANK_COLOR

CHECK_TANK3_POS:
    ; if (j == tank3_x
    cmp     cx, [tank3_x]
    jne     CHECK_TANK4_POS
    ; && i == tank3_y)
    cmp     dx, [tank3_y]
    je      SET_TANK_COLOR

CHECK_TANK4_POS:
    ; if (j == tank4_x
    cmp     cx, [tank4_x]
    jne     SET_BG_COLOR
    ; && i == tank4_y)
    cmp     dx, [tank4_y]
    je      SET_TANK_COLOR
    ; else
    jmp     SET_BG_COLOR

SET_WALL_COLOR:
    ; To arrive here we had to push all those values so restore them
    add byte [current_color], WALL_COLOR
    jmp     DRAW_TILE_ROW

SET_PLAYER_COLOR:
    add byte [current_color], PLAYER_COLOR
    jmp     DRAW_TILE_ROW

SET_EAGLE_COLOR:
    add byte [current_color], EAGLE_COLOR
    jmp     DRAW_TILE_ROW

SET_TANK_COLOR:
    add byte [current_color], TANK_COLOR
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




; Padding
times 510 - ($-$$)      db      0x0
; Se convierte en un sector booteable
                        dw      0xAA55


; Tanques destruidos
destr_tanks             db      0x0
; Nivel actual de 1 - 3
current_level           db      0x0
; Desde el origin de la columna
player_x:               dw      0x0
; Desde el origin de la fila
player_y:               dw      0x0
eagle_x:                dw      0x0
eagle_y:                dw      0x0
tank1_x:                dw      0x0
tank1_y:                dw      0x0
tank2_x:                dw      0x0
tank2_y:                dw      0x0
tank3_x:                dw      0x0
tank3_y:                dw      0x0
tank4_x:                dw      0x0
tank4_y:                dw      0x0
DESTROYED_TANKS:        db      "Tanques: ", 0
CURRENT_LEVEL_MSG:      db      "Nivel:   ", 0
current_color:          db      0x0

; Semilla del laberinto
MAZE:
    dw 0b0000000000000000;000000000000000000000000000000000000
    dw 0b0000000000000000
    dw 0b0000000000000000

    dw 0b0111111111111111;011111111111111111111111111111111110
    dw 0b1111111111111111
    dw 0b1110000000000000
    
    dw 0b0001111111111000;000111111111100011111100011111111000
    dw 0b1111110001111111
    dw 0b1000000000000000
    
    dw 0b0001111111111000;000111111111100011110001111111111000
    dw 0b1111000111111111
    dw 0b1000000000000000
    
    dw 0b0111111111111111;1111111111111110
    dw 0b0111111111111111;1111111111111110
    dw 0b0111111111111111;1111111111111110
    
    dw 0b0111111001111111;1111111001111110
    dw 0b0111111001111111;1111111001111110
    dw 0b0111111001111111;1111111001111110
    
    dw 0b0111111001111111;1111111001111110
    dw 0b0111111001111111;1111111001111110
    dw 0b0111111001111111;1111111001111110
    
    dw 0b0111111001111111;1111111001111110
    dw 0b0111111001111111;1111111001111110
    dw 0b0111111001111111;1111111001111110
    
    dw 0b0111111001111111;1111111001111110
    dw 0b0111111001111111;1111111001111110
    dw 0b0111111001111111;1111111001111110
    
    dw 0b0111001111111100;0011111111001110
    dw 0b0111001111111100;0011111111001110
    dw 0b0111001111111100;0011111111001110
    
    dw 0b0111001001111100;0011111001001110
    dw 0b0111001001111100;0011111001001110
    dw 0b0111001001111100;0011111001001110
        
    dw 0b0111001001111111;1111111001001110
    dw 0b0111001001111111;1111111001001110
    dw 0b0111001001111111;1111111001001110
    
    dw 0b0111001001111100;0011111001001110
    dw 0b0111001001111100;0011111001001110
    dw 0b0111001001111100;0011111001001110
    
    dw 0b0111111111111110;0111111111111110
    dw 0b0111111111111110;0111111111111110
    dw 0b0111111111111110;0111111111111110
    
    dw 0b0111111111100010;0100011111111110
    dw 0b0111111111100010;0100011111111110
    dw 0b0111111111100010;0100011111111110
    
    dw 0b0111101111111111;1111111111011110
    dw 0b0111101111111111;1111111111011110
    dw 0b0111101111111111;1111111111011110
    
    dw 0b0111101001111100;0011111001011110
    dw 0b0111101001111100;0011111001011110
    dw 0b0111101001111100;0011111001011110
    
    dw 0b0111111001111110;0111111001111110
    dw 0b0111111001111110;0111111001111110
    dw 0b0111111001111110;0111111001111110
    
    dw 0b0111111111111110;0111111111111110
    dw 0b0111111111111110;0111111111111110
    dw 0b0111111111111110;0111111111111110
    
    dw 0b0111111111111111;1111111111111110
    dw 0b0111111111111111;1111111111111110
    dw 0b0111111111111111;1111111111111110
    
    dw 0b0000000000000000;0000000000000000
    dw 0b0000000000000000;0000000000000000
    dw 0b0000000000000000;0000000000000000
    
    dw 0b0111101111111111;1111111111011110
    dw 0b0111101111111111;1111111111011110
    dw 0b0111101111111111;1111111111011110
    
    dw 0b0111101001111100;0011111001011110
    dw 0b0111101001111100;0011111001011110
    dw 0b0111101001111100;0011111001011110
    
    dw 0b0111111001111110;0111111001111110
    dw 0b0111111001111110;0111111001111110
    dw 0b0111111001111110;0111111001111110
    
    dw 0b0111111111111110;0111111111111110
    dw 0b0111111111111110;0111111111111110
    dw 0b0111111111111110;0111111111111110
    
    dw 0b0111111111111111;1111111111111110
    dw 0b0111111111111111;1111111111111110
    dw 0b0111111111111111;1111111111111110
    
    dw 0b0000000000000000;0000000000000000
    dw 0b0000000000000000;0000000000000000
    dw 0b0000000000000000;0000000000000000

