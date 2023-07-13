bits 16

SECTION _TEXT class=CODE
global _X86_Video_WriteCharTeletype

; args: character and page number
; prints character to screen
_X86_Video_WriteCharTeletype:
    push bp
    mov bp, sp

    push bx

    mov ah, 0Eh
    mov al, [bp + 4]
    mov bh, [bp + 6]
    int 10h

    pop bx
    mov sp, bp
    pop bp
    ret

