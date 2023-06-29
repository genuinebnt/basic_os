[org 0x7C00]
[bits 16]

start:
    jmp main

print:

.loop:
    lodsb
    or al, al
    jz .done

    mov ah, 0x0e
    mov bh, 0
    int 0x10

    jmp .loop

.done:
    ret
main: 
    mov ax, 0
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7C00

    mov si, msg
    call print


    hlt
    jmp .halt

.halt:
    jmp .halt

msg: db 'Hello world', 0

times 510-($-$$) db 0

dw 0xAA55
