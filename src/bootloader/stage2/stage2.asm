bits 16

SECTION _ENTRY class=CODE

extern _cstart_
global entry

entry:
    cli
    mov ax, ds
    mov ss, ax
    mov sp, 0
    sti

    xor dh, dh
    push dx
    call _cstart_

    cli
    hlt