; Direccion de inicio
[org 0x7C00]

;---------------------------------Notes--------------------------------
; di - pointer to video memory location
; ax - pixel data bfcc (4 bit background color, 4 bit foreground color,
;      8-bit character (code 437))
; cx - counter used in combination with stosw
; stosw - puts ax data into di (video memory) and decrements cx
; scasw - way to increment di with 1 byte (even though it's supposed to
;         scan a string...)
; cbw - 1 byte trick to zero out ah (zero mask) and leave al intact so
;       long as al is less than 0x80


;------------------------------CONSTANTS-------------------------------
TILE_SIZE               equ 0x08                            ; 8x8
Y_PADDING               equ 0x10                            ;  16px
X_PADDING               equ 0x20                            ;  32px
X_SIZE:                 equ 0x0140                          ; 320px
BG_START                equ Y_PADDING*X_SIZE + X_PADDING    ; (16, 32)
BG_END                  equ     

;-------------------------------Colores--------------------------------
; Se usa una representacion de 8 bit para cada color de la forma
; RRRGGGBB
; Hay una imagen llamada 8bit_color_mode.png con todos los colores
; posibles, si quieren cambiar un color, solo buscan la fila i y la
; columna j y el valor decimal sera (i * 15 + j), lo convierten a hex
; y ese es el color que usan
BG_COLOR:               equ     0x01        ; Azul
PLAYER_COLOR:           equ     0x02        ; Verde


;--------------------------------Teclas--------------------------------
LEFT_KEY                equ     75
RIGHT_KEY               equ     77
UP_KEY                  equ     72
DOWN_KEY                equ     80

;--------------------------------SPRITES-------------------------------
; Noten que el laberinto es simetrico para ahorrar memoria
; Aqui pongo comentarios con la otra mitad para que la vean
; Los 1s son campos libres para andar y los 0s son paredes
BACKGROUND:
        ; 21x32
        dw 0b0000000000000000;0000000000000000
        dw 0b0111111111111111;1111111111111110
        dw 0b0111111111100011;1100011111111110
        dw 0b0111111111100011;1100011111111110
        dw 0b0111111111111111;1111111111111110
        dw 0b0111111001111111;1111111001111110
        dw 0b0111111001111111;1111111001111110
        dw 0b0111111001111111;1111111001111110
        dw 0b0111111001111111;1111111001111110
        dw 0b0111001111111100;0011111111001110
        dw 0b0111001001111100;0011111001001110
        dw 0b0111001001111111;1111111001001110
        dw 0b0111001001111100;0011111001001110
        dw 0b0111111111111110;0111111111111110
        dw 0b0111111111100010;0100011111111110
        dw 0b0111101111111111;1111111111011110
        dw 0b0111101001111100;0011111001011110
        dw 0b0111111001111110;0111111001111110
        dw 0b0111111111111110;0111111111111110
        dw 0b0111111111111111;1111111111111110
        dw 0b0000000000000000;0000000000000000

INIT:
    ; Configurar el modo VESA 0x13 (320x200x256 VGA)
    ; Mas informacion en https://en.wikipedia.org/wiki/VESA_BIOS_Extensions#cite_note-tradvga-1
    ; Basicamente el 0x0013 es una pantalla de 320x200 con colores de 0-255
    mov     ax, 0x0013
    ; Llamar BIOS
    int     0x10
    ; Borra la bandera DF (Direction Flag, DF=0) en el registro EFLAGS
    cld
    ; Segmento de video
    mov     ax, 0xA000
    ; Se usa como segmento de datos fuente
    mov     ds, ax
    ; Se usa como segmento de datos fuente
    mov     es, ax

    ; Dibujar fondo
    ; Cargar el fondo
    mov     si, BACKGROUND

DRAW_BG_ROW:
    ; Se carga una palabra de los datos del segmento de codigo
    cs      lodsw
    ; Se intercambian los valores entre ax y cx
    xchg    ax, cx
    ; Offset debido al espejo que les habia dicho
    mov     bx, 30 * TILE_SIZE

; Padding
times 510-($-$$)        db      0x4F
; Se convierte en un sector booteable
                        db      0x55, 0xAA
