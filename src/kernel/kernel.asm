[org 0x0]
[bits 16]

%define ENDL 0x0D, 0x0A


start:
    mov si, msg
    call print

.halt:
    cli
    hlt
    jmp .halt

; print function prints a string to console
; parameters
;   si contains string to print
print:
    push si
    push ax
    push bx

.loop:
    lodsb                   ; short for: mov al, [si] ; inc si
    test al, al
    jz .done

    mov ah, 0Eh
    mov bh, 0h
    int 10h                 ; For video services AH : 0EH -> teletype output BH -> page number 

    jmp .loop

.done:
    pop bx
    pop ax
    pop si

    ret

msg: db 'Hello Genuine from kernel...', ENDL, 0
