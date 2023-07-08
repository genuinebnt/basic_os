[org 0x7C00]
[bits 16]

%define ENDL 0x0D, 0x0A

;FAT12 HEADERS

jmp short start ; 2 bytes offset 0
nop ; 1 byte offset 2

bdb_oem:                    db 'MSWIN4.1' ;offset 3
bdb_bytes_per_sector:       dw 0200h      ;offset 11
bdb_sector_per_cluster:     db 1          ;offset 13
bdb_reserved_sectors:       dw 0001h      ;offset 14
bdb_num_fat:                db 2          ;offset 16
bdb_num_root_dir_entry:     dw 00E0h      ;offset 17
bdb_total_sector_in_vol:    dw 0B40h      ;offset 19
bdb_media_desc_type:        db 0F0h       ;offset 21
bdb_num_sector_per_fat:     dw 0009h      ;offset 22
bdb_num_sector_per_track:   dw 0012h      ;offset 24
bdb_num_heads:              dw 0002h      ;offset 26
bdb_num_hidden_sectors:     dd 0h         ;offset 28
bdb_large_sector_count:     dd 0h         ;offset 32

; extended boot record

ebdb_drive_num:             db 0                            ;offset 36
ebdb_flags_win_nt:          db 0                            ;offset 37
ebdb_signature:             db 29h                          ;offset 38
ebdb_vol_id:                db 0xA0, 0xB9, 0xCE, 0x28       ;offset 39
ebdb_partition_name:        db 'BASICOS    '                ;offset 43 11 bytes
ebdb_system_id:             db 'FAT12   '                   ;offset 54 8 bytes



start:
;   setup segment registers and stack pointer
    mov ax, 0

    mov ds, ax
    mov es, ax

    ;setup stack
    mov ss, ax
    mov sp, 0x7C00      ; stack grows downwards so we set to 7C00(or any lower address) so we dont overwrite code with stack memory

    mov dl, [ebdb_drive_num]        ; set drive number

    ; mov si, msg_loading
    ; call print

    mov ax, [bdb_num_fat]
    mov bx, [bdb_num_sector_per_fat]
    mul bx
    add ax, [bdb_reserved_sectors]  ; ax = reserved_sectors + (fat_count * sectors_per_fat)

    push ax ;   ax = lba of root_dir:  store ax so that we can use it for other calculations

    mov ax, [bdb_num_root_dir_entry]
    shl ax, 5   ; 1 shift left multiplies by 2
    add ax, [bdb_bytes_per_sector]  ; entry_size * entry_count + bytes_per_sector
    dec ax      
    div bx      ; (entry_size * entry_count + bytes_per_sector - 1) / bytes_per_sector

    mov dl, [ebdb_drive_num]        ; set drive number
    mov bx, buffer
    mov cl, al                      ; sectors to read
    pop ax
    call disk_read

    mov si, buffer
    call print

    cli
    hlt 

;
; Error handling functions
;
floppy_error:
    mov si, floppy_error_msg
    call print

    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h
    jmp 0FFFFh:0

.halt:
    cli
    hlt

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

; Converts Logical block address to CHS address
; Parameters: LBA address in AH
; Returns:
; DH : head
; CX : Upper 6 bits is cylinder and lower 2 bits is sector
lba_to_chs:
    push ax
    push dx

    xor dx, dx                                      ; dx = 0
    div word [bdb_num_sector_per_track]             ; AX = LBA / NumSectorPerTrack 
                                                    ; DX = LBA % NumSectorPerTrack
    mov cx, dx
    inc cx                                          ; Sectors = LBA % NumSectorPerTrack + 1

    mov dx, ax
    div word [bdb_num_heads]                        ; Cylinder = AX = (LBA / NumSectorPerTrack) / NumHeadsPerCylinder == LBA / (NumSectorPerTrack * NumHeadsPerCylinder)
                                                    ; Heads = DX = (LBA / NumSectorPerTrack) % NumHeadsPerCylinder
    
    mov dh, dl                                      ; Upper half bits of dx need heads value for bios disk reading
    mov ch, al
    shl ah, 6
    or cl, ah 

    pop ax
    mov dl, al
    pop ax                                          ; we are only returning cx and dl so ax and dh can be restored

    ret

; calls int 13h to read from disk
; parameters: 
;   address of buffer to read in bx
;   total sector count to read 
;   dl contains drive number
disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    call lba_to_chs             ; will set ch, cl and dh

    mov di, 3
    mov ah, 2

.retry:
    pusha
    stc
    int 13h

    dec di
    jnc .done

    ; disk read failed
    popa
    call disk_reset

    test di, di
    jnz .retry

    jmp floppy_error

.done:
    popa
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret

disk_reset:
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    ret


msg_loading: db 'Loading...', ENDL, 0
floppy_error_msg: db 'Cannot read from floppy', ENDL, 0

times 510-($-$$) db 0

dw 0xAA55

buffer: