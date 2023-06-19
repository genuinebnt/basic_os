org 0x7C00
bits 16

_start:
    jmp main

main:
     mov ax, 0
     mov ds, ax
     mov es, ax

     mov ss, ax
     mov sp, 0x7C00

     mov si, msg
     call puts

     hlt

.halt:
    jmp .halt

puts:
    push ax
    push bx
    push si

.loop:
    mov al, [si]
    inc si
    or al, al
    jz .done

    mov ah, 0x0e
    mov bh, 0
    int 10h

    jmp .loop

.done:
    pop si
    pop bx
    pop ax
    ret

msg: db 'Hello world', 0x0D, 0x0A, 0x00

times 510-($-$$) db 0
dw 0AA55h