bits 16
; Direccion de inicio
[org 0x7C00]

;------------------------------CONSTANTES------------------------------
; Pantalla de 320x200x256
ROWS                    equ     184         ; 200 - 16
COLS                    equ     288         ; 320 - 32
TILE_SIZE               equ     16          ; Sprites de 8x8

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
PLAYER_SHOOT_COLOR:     equ     0x04        ; Vino
TANK_SHOOT_COLOR:       equ     0x05        ; Fussia (?)


;--------------------------------Teclas--------------------------------
LEFT_KEY:               equ     0x4B
RIGHT_KEY:              equ     0x4D
UP_KEY:                 equ     0x48
DOWN_KEY:               equ     0x50
; Tecla de disparo
SPACE_KEY               equ     0x39
; Tecla de reinicio
U_KEY                   equ     0x16
; Tecla de pausa
P_KEY                   equ     0x19
; Tecla para salir
ESC_KEY                 equ     0x01


;--------------------------------Contador--------------------------------
game_counter            dw      0x0


; Configurar el modo de video
BOOT:
    ; Set mode 0x13 (320x200x256 VGA)
    mov     ax, 0x0013
    mov     bx, 0x0105
    int     0x10    


; Iniciar todas las variables del juego
; Tambien funciona para reiniciar el juego
START:
    ; Color base, es negro
    mov word [current_color], BASE_COLOR
    ; Cantidad de tanques destruidos
    mov byte [destr_tanks], 0x0
    ; Nievel actual del juego
    mov byte [current_level], 1
    ; Empieza en el centro
    mov byte [player], 0xA0
    mov byte [player + 2], 0x60
    ; Aguila abajo en el centro
    mov byte [eagle], 0xA0
    mov byte [eagle + 2], 0xB0
    ; Posicion del tanque1
    mov byte [tank1], 0x20
    mov byte [tank1 + 2], 0x10
    ; Posicion del tanque2
    mov word [tank2], 0x0110
    mov byte [tank2 + 2], 0x10
    ; Posicion del tanque3
    mov byte [tank3], 0x60
    mov byte [tank3 + 2], 0x40
    ; Posicion del tanque4
    mov byte [tank4], 0xE0
    mov byte [tank4 + 2], 0x40
    ; Iniciar la memoria para mostrar los tanques
    mov word [DESTROYED_TANKS], 'T'
    mov word [DESTROYED_TANKS + 1], 'a'
    mov word [DESTROYED_TANKS + 2], 'n'
    mov word [DESTROYED_TANKS + 3], 'q'
    mov word [DESTROYED_TANKS + 4], 'u'
    mov word [DESTROYED_TANKS + 5], 'e'
    mov word [DESTROYED_TANKS + 6], 's'
    mov word [DESTROYED_TANKS + 7], ':'
    mov word [DESTROYED_TANKS + 8], ' '
    mov word [DESTROYED_TANKS + 9], 0x0
    ; Iniciar la memoria para mistrar el nivel
    mov word [CURRENT_LEVEL_MSG], 'N'
    mov word [CURRENT_LEVEL_MSG + 1], 'i'
    mov word [CURRENT_LEVEL_MSG + 2], 'v'
    mov word [CURRENT_LEVEL_MSG + 3], 'e'
    mov word [CURRENT_LEVEL_MSG + 4], 'l'
    mov word [CURRENT_LEVEL_MSG + 5], ':'
    mov word [CURRENT_LEVEL_MSG + 6], ' '
    mov word [CURRENT_LEVEL_MSG + 7], ' '
    mov word [CURRENT_LEVEL_MSG + 8], ' '
    mov word [CURRENT_LEVEL_MSG + 9], 0x0
    ; Direccion del jugador. Arriba por defecto
    ; Arriba    0x00
    ; Derecha   0x01
    ; Abajo     0x02
    ; Izquierda 0x03
    mov byte [shoot_dir], 0x0;
    ; Disparo del jugador fuera de pantalla
    mov byte [player_shoot], 0x0
    mov byte [player_shoot + 2], 0x0
    ; El jugador no ha disparado
    mov word [player_shot], 0x0




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
    push dx
    mov ax, [bx]
    add ax, TILE_SIZE
    mov dx,0x0120 
    sub dx, TILE_SIZE
    cmp ax,dx
    jg  move_right_e
    mov [bx],ax

move_right_e:
    pop dx
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
    push dx
    mov ax, [bx]
    add ax, TILE_SIZE
    mov dx,0x00B8
    sub dx,TILE_SIZE
    cmp ax,dx
    jg  move_down_e
    mov [bx],ax

move_down_e:
    pop dx
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


; Mostrar el texto con la cantidad de tanques destruidos
DESTROYED_TANKS_CHAR:
    ; Carga el byte actual en SI y aumentar la direccion
    lodsb
    ; Verificar si ya termino de recorrer la cadena 
    cmp     al, 0
    ; Imprimir siguiente mensaje
    je      LEVEL_MSG
    xor     bh, bh
    ; Pagina donde se imprime
    add     bh, 0x00
    ; Color del texto
    xor     bl, bl
    add     bl, 0x08
    int     0x10
    ; Siguiente caracter
    jmp     DESTROYED_TANKS_CHAR

; Mostrar el nivel actual del juego
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
    je      DONE_STATUS
    int     0x10
    ; Siguiente caracter
    jmp     LEVEL_MSG_CHAR

DONE_STATUS:
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


; Verificar las teclas que ha presionado el usuario
CHECK_KEY:
    ; Leer el status de la entrada
    mov     ah, 0x01        
    int     0x16
    ; Si no hay una tecla
    jz      MOV_PLAYER_SHOOT

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
    sub word [player + 2], TILE_SIZE

    push    bx

    mov word bx, [player_shot]
    cmp     bx, 0x00
    jne      CHECK_DOWN

    ; Cambiar la direccion a arriba
    mov word [shoot_dir], 0x0

CHECK_DOWN:
    pop     bx

    cmp     ah, DOWN_KEY
    jne     CHECK_LEFT
    add word [player + 2], TILE_SIZE

    push    bx

    mov word bx, [player_shot]
    cmp     bx, 0x00
    jne      CHECK_LEFT

    ; Cambiar la direccion a abajo
    mov word [shoot_dir], 0x02

CHECK_LEFT:
    pop     bx
    cmp     ah, LEFT_KEY
    jne     CHECK_RIGHT
    sub word [player], TILE_SIZE

    push    bx

    mov word bx, [player_shot]
    cmp     bx, 0x00
    jne      CHECK_RIGHT

    ; Cambiar la direccion a la izquierda
    mov word [shoot_dir], 0x03

CHECK_RIGHT:
    pop     bx

    cmp     ah, RIGHT_KEY
    jne     CHECK_SPACE
    add word [player], TILE_SIZE

    push    bx

    mov word bx, [player_shot]
    cmp     bx, 0x00
    jne      CHECK_SPACE

    ; Cambiar la direccion a la derecha
    mov word [shoot_dir], 0x01

CHECK_SPACE:
    pop     bx

    cmp     ah, SPACE_KEY
    jne     CHECK_ESC


    push    ax

    mov word ax, [player_shot]

    cmp     ax, 0x0
    jg      CHECK_ESC

    ; Disparar
    mov     ax, [player]
    mov     [player_shoot], ax
    mov     ax, [player + 2]
    mov     [player_shoot + 2], ax

    ; El jugador ya disparo
    mov byte [player_shot], 0x01

CHECK_ESC:
    pop     ax

    cmp     ah, ESC_KEY
    jne     MOV_PLAYER_SHOOT
    jmp     HALT


MOV_PLAYER_SHOOT:
    push    ax

    ; Verificar si el jugador se movia 
    mov word ax, [shoot_dir]

    ; Mover bala hacia arriba
    cmp     ax, 0x0
    je      MOV_PLAYER_SHOOT_UP

    ; Mover bala hacia la derecha
    cmp     ax, 0x1
    je      MOV_PLAYER_SHOOT_RIGHT

    ; Mover bala hacia la down
    cmp     ax, 0x2
    je      MOV_PLAYER_SHOOT_DOWN

    ; Mover bala hacia la derecha
    jmp     MOV_PLAYER_SHOOT_LEFT

MOV_PLAYER_SHOOT_UP:
    sub word [player_shoot + 2], TILE_SIZE
    jmp     MOV_PLAYER_SHOOT_DONE

MOV_PLAYER_SHOOT_RIGHT:
    add word [player_shoot], TILE_SIZE
    jmp     MOV_PLAYER_SHOOT_DONE

MOV_PLAYER_SHOOT_DOWN:
    add word [player_shoot + 2], TILE_SIZE
    jmp     MOV_PLAYER_SHOOT_DONE

MOV_PLAYER_SHOOT_LEFT:
    sub word [player_shoot], TILE_SIZE
    jmp     MOV_PLAYER_SHOOT_DONE


MOV_PLAYER_SHOOT_DONE:
    mov word ax, [player_shoot]
    ; player_shoot_x < 16
    cmp     ax, 0x10
    jl      PLAYER_SHOOT_DISAPPEAR
    ; player_shoot_x > COLS
    cmp     ax, COLS
    jg      PLAYER_SHOOT_DISAPPEAR
    mov word ax, [player_shoot + 2]
    ; player_shoot_y < 32
    cmp     ax, 0x20
    jl      PLAYER_SHOOT_DISAPPEAR
    ; player_shoot_y < ROWS
    cmp     ax, ROWS
    jg      PLAYER_SHOOT_DISAPPEAR

    jmp     PLAYER_SHOOT_DONE

PLAYER_SHOOT_DISAPPEAR:
    mov byte [player_shoot], 0x0
    mov byte [player_shoot + 2], 0x0
    mov word [player_shot], 0x0

PLAYER_SHOOT_DONE:
    pop     ax

; Dibujar el laberinto
MAZE_ROW_LOOP: ; for i in range(ROWS)
    cmp     dx, ROWS
    ; if (i != ROWS)
    jl     MAZE_COL_LOOP
    ; Reiniciar
    jmp     GAME_LOOP

MAZE_COL_LOOP: ; for j in range(COLS)
    cmp     cx, COLS
    ; if (j != COLS)
    jl     DRAW_TILE

    ; j = 0
    xor     cx, cx
    ; 32px de padding
    add     cx, 0x0020
    ; i += TILE_SIZE
    add     dx, TILE_SIZE
    ; Siguiente fila
    jmp     MAZE_ROW_LOOP


; Dibujar cada sprite
DRAW_TILE:
    ; Sprite de mxn (8x8)
    mov     ax, TILE_SIZE
    mov     bx, TILE_SIZE
    mov word [current_color], BASE_COLOR


; Verificar las posiciones de los objetos con order de prioridad
CHECK_PLAYER_POS:
    ; if (j == player_x
    cmp     cx, [player]
    jne     CHECK_EAGLE_POS
    ; && i == player_y)
    cmp     dx, [player + 2]
    je      SET_PLAYER_COLOR

CHECK_EAGLE_POS:
    ; if (j == eagle_x
    cmp     cx, [eagle]
    jne     CHECK_PLAYER_SHOOT_POS
    ; && i == eagle_y)
    cmp     dx, [eagle + 2]
    je      SET_EAGLE_COLOR

CHECK_PLAYER_SHOOT_POS:
    ; if (j == player_shoot_x
    cmp     cx, [player_shoot]
    jne     CHECK_TANK1_POS
    ; && i == player_shoot_y)
    cmp     dx, [player_shoot + 2]
    je      SET_PLAYER_SHOOT_COLOR

CHECK_TANK1_POS:
    ; if (j == tank1_x
    cmp     cx, [tank1]
    jne     CHECK_TANK2_POS
    ; && i == tank1_y)
    cmp     dx, [tank1 + 2]
    je      SET_TANK_COLOR

CHECK_TANK2_POS:
    ; if (j == tank2_x
    cmp     cx, [tank2]
    jne     CHECK_TANK3_POS
    ; && i == tank2_y)
    cmp     dx, [tank2 + 2]
    je      SET_TANK_COLOR

CHECK_TANK3_POS:
    ; if (j == tank3_x
    cmp     cx, [tank3]
    jne     CHECK_TANK4_POS
    ; && i == tank3_y)
    cmp     dx, [tank3 + 2]
    je      SET_TANK_COLOR

CHECK_TANK4_POS:
    ; if (j == tank4_x
    cmp     cx, [tank4]
    jne     SET_BG_COLOR
    ; && i == tank4_y)
    cmp     dx, [tank4 + 2]
    je      SET_TANK_COLOR
    ; else
    jmp     SET_BG_COLOR


; Configurar el color de cada objecto
SET_PLAYER_COLOR:
    add byte [current_color], PLAYER_COLOR
    jmp     DRAW_TILE_ROW

SET_EAGLE_COLOR:
    add byte [current_color], EAGLE_COLOR
    jmp     DRAW_TILE_ROW

SET_PLAYER_SHOOT_COLOR:
    add byte [current_color], PLAYER_SHOOT_COLOR
    jmp     DRAW_TILE_ROW

SET_TANK_COLOR:
    add byte [current_color], TANK_COLOR
    jmp     DRAW_TILE_ROW

SET_BG_COLOR:
    add byte [current_color], BG_COLOR


; Comenzar a dibujar cada sprite
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


; Dibujar un pixel del sprite
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


; Salir del juego
HALT:
    ; Limpiar las banderas de interrupciones
    cli
    ; Detener ejecucion
    hlt

; mov eax,cr0
; or eax,1
; mov cr0,eax

; Tanques destruidos
destr_tanks             db      0x0
; Nivel actual de 1 - 3
current_level           dw      0x1
; Desde el origin de la columna
; Desde el origin de la fila
player:                 dd      0, 0
player_shoot:           dd      0, 0
; Direccion actual del jugador
; Usado para saber hacia donde tienen que ir las balas
shoot_dir:              dw      0x0
player_shot:            dw      0x0
eagle:                  dd      0, 0
tank1:                  dd      0, 0
tank2:                  dd      0, 0
tank3:                  dd      0, 0
tank4:                  dd      0, 0
shoots:                 dq      0x0,0x0, 0x0,0x0, 0x0,0x0, 0x0,0x0
DESTROYED_TANKS:        db      "Tanques: ", 0x0
CURRENT_LEVEL_MSG:      db      "Nivel:   ", 0x0

current_color:          db      0x0

; Padding Needed for windows since you cant use dd, replace 720K with the needed amount
; Extend the second stage to (720K - 512 bytes) 
; bootload.bin will take up first 512 bytes 
; times 737280 - 512 - ($ - $$) db 0
