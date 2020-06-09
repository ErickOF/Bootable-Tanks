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


;--------------------------------Contador--------------------------------
game_counter            dw      0x0


BOOT:
    ; Set mode 0x13 (320x200x256 VGA)
    mov     ax, 0x0013
    mov     bx, 0x0105
    int     0x10    

START:
    mov word [current_color], BASE_COLOR
    mov byte [destr_tanks], 0x0
    mov byte [current_level],1
    ; Empieza en el centro
    mov byte [player], 0x00A0
    mov byte [player+2], 0x0060
    ; Aguila abajo en el centro
    mov byte [eagle], 0x00A0
    mov byte [eagle+2], 0x00B0
    ; Posicion del tanque1
    mov byte [tank1], 0x0020
    mov byte [tank1+2], 0x0010
    ; Posicion del tanque2
    mov word [tank2], 0x0118
    mov byte [tank2+2], 0x0010
    ; Posicion del tanque3
    mov byte [tank3], 0x0060
    mov byte [tank3+2], 0x0040
    ; Posicion del tanque4
    mov byte [tank4], 0x00E0
    mov byte [tank4+2], 0x0040




GAME_LOOP:
    ; i = 0
    xor     dx, dx
    ; 16px de padding
    add     dx, 0x0010
    ; j = 0
    xor     cx, cx
    ; 32px de padding
    add     cx, 0x0020

    jmp UPDATE

increaselevel:
    mov ax, current_level
    add ax,1
    cmp ax,4
    je increaselevel_e
    mov [current_level],ax
increaselevel_e:
    ret


UPDATE:
    int 0x13  
    push ax
    push dx
    push cx
    push bx

    mov ax,4
    sub ax,[current_level]
    mov cx,ax

    mov ax,[game_counter]
    add ax,1
    mov word [game_counter],ax

    ; if gamecounter % game_speed == 0
    mov dx,0     
    div cx
    cmp dx,0
    jne UPDATE_EXIT
    ;moving tanks
    


MOVE_TANK:
    rdtsc ;random number dx:ax
    ;mov ax,0  forces random

    mov dx,0
    mov cx,5
    div cx   

    mov bx, tank1
    call move_call
    mov bx, tank2
    call move_call
    mov bx, tank3
    call move_call
    mov bx, tank4
    call move_call

    jmp UPDATE_EXIT

move_call:    
    cmp dx,0
    je move_right
    cmp dx,1
    je move_left

    add bx,2
    cmp dx,2
    je move_down
    cmp dx,3
    je move_up
    ;if none
    ret

move_right:
    mov ax, [bx]
    add ax, TILE_SIZE
    cmp ax,0x0118
    jg  move_right_e
    mov [bx],ax
move_right_e:
    ret

move_left:
    mov ax, [bx]
    sub ax, TILE_SIZE
    cmp ax,0x0020
    jl  move_left_e
    mov [bx],ax
move_left_e:
    ret

move_up:
    mov ax, [bx]
    sub ax, TILE_SIZE
    cmp ax,0x0010
    jl  move_up_e
    mov [bx],ax
move_up_e:
    ret

move_down:
    mov ax, [bx]
    add ax, TILE_SIZE
    cmp ax,0x00B0
    jg  move_down_e
    mov [bx],ax
move_down_e:
    ret

UPDATE_EXIT:
    pop bx
    pop cx
    pop dx
    pop ax
    int 0x10

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
    sub byte [player+2], TILE_SIZE

CHECK_DOWN:
    cmp     ah, DOWN_KEY
    jne     CHECK_LEFT
    add byte [player+2], TILE_SIZE

CHECK_LEFT:
    cmp     ah, LEFT_KEY
    jne     CHECK_RIGHT
    sub byte [player], TILE_SIZE

CHECK_RIGHT:
    cmp     ah, RIGHT_KEY
    jne     MAZE_ROW_LOOP
    add byte [player], TILE_SIZE

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

CHECK_PLAYER_POS:
    ; if (j == player_x
    cmp     cx, [player]
    jne     CHECK_EAGLE_POS
    ; && i == player_y)
    cmp     dx, [player+2]
    je      SET_PLAYER_COLOR

CHECK_EAGLE_POS:
    ; if (j == eagle_x
    cmp     cx, [eagle]
    jne     CHECK_TANK1_POS
    ; && i == eagle_y)
    cmp     dx, [eagle+2]
    je      SET_EAGLE_COLOR

CHECK_TANK1_POS:
    ; if (j == tank1_x
    cmp     cx, [tank1]
    jne     CHECK_TANK2_POS
    ; && i == tank1_y)
    cmp     dx, [tank1+2]
    je      SET_TANK_COLOR

CHECK_TANK2_POS:
    ; if (j == tank2_x
    cmp     cx, [tank2]
    jne     CHECK_TANK3_POS
    ; && i == tank2_y)
    cmp     dx, [tank2+2]
    je      SET_TANK_COLOR

CHECK_TANK3_POS:
    ; if (j == tank3_x
    cmp     cx, [tank3]
    jne     CHECK_TANK4_POS
    ; && i == tank3_y)
    cmp     dx, [tank3+2]
    je      SET_TANK_COLOR

CHECK_TANK4_POS:
    ; if (j == tank4_x
    cmp     cx, [tank4]
    jne     SET_BG_COLOR
    ; && i == tank4_y)
    cmp     dx, [tank4+2]
    je      SET_TANK_COLOR
    ; else
    jmp     SET_BG_COLOR

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

; Tanques destruidos
destr_tanks             db      0x0
; Nivel actual de 1 - 3
current_level           dw      0x1
; Desde el origin de la columna
player:                 dd      0,0
; Desde el origin de la fila
eagle:                  dd      0,0
tank1:                  dd      0,0
tank2:                  dd      0,0
tank3:                  dd      0,0
tank4:                  dd      0,0
DESTROYED_TANKS:        db      "Tanques: ", 0
CURRENT_LEVEL_MSG:      db      "Nivel:   ", 0
current_color:          db      0x0

; Padding Needed for windows since you cant use dd, replace 720K with the needed amount
; Extend the second stage to (720K - 512 bytes) 
; bootload.bin will take up first 512 bytes 
; times 737280 - 512 - ($ - $$) db 0