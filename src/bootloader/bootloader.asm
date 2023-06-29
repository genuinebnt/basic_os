[org 0x7C00]
[bits 16]

%define ENDL 0x0D, 0x0A

;FAT12 HEADERS

jmp short start ; 2 bytes offset 0
nop ; 1 byte offset 2

bdb_oem:                    db 'MSWIN4.1' ;offset 3
bdb_bytes_per_sector:       dw 0200h        ;offset 11
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
    jmp main

print:
    push ax
    push bx
    push si

.loop:
    lodsb
    or al, al
    jz .done

    mov ah, 0x0e
    mov bh, 0
    int 0x10

    jmp .loop

.done:
    pop si
    pop bx
    pop ax

    ret
    
main: 
    mov ax, 0
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7C00

    ; read something from floppy
    ; bios should set dl to drive number

    mov ax, 1               ; lba = 1, second sector of disk
    mov cl, 1               ; 1 sector to read
    mov bx, 0x7E00          ; data should be after bootloader
    call disk_read          

    mov si, msg
    call print

    cli
    hlt

; Error handling function
floppy_error:
    mov si, msg_read_failed
    call print
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h
    jmp 0FFFFh:0

.halt
    cli
    hlt

; Converts LBA address to CHS address
; Parameters:
;   - ax: LBA address
; Returns:
;   - cl [bits 0-5]: sector number (upper)
;   - ch [bits 6-15]: cylinder (lower)
;   - dh: head
lba_to_chs:
    push ax
    push dx

    xor dx, dx          ; dx = 0
    div word [bdb_num_sector_per_track] ; ax = LBA / SectorPerTrack
                                        ; dx = LBA % SectorPerTrack
    inc dx                              ; Sector = (LBA % SectorPerTrack) + 1
    mov cx, dx                          ; Save sector count

    xor dx, dx
    div word [bdb_num_heads]            ; cylinder = ax -> (LBA / SectorPerTrack) / HeadsPerCylinder
                                        ; heads = ax -> (LBA / SectorPerTrack) % HeadsPerCylinder
    mov dh, dl                          ; upper bits of dx has head value
    mov ch, al                          ; ch = cylinder 
    shl ah, 6                           ; shift higher 2 bits
    or cl, ah                           ; cl has sector number

    pop ax
    mov dl, al
    pop ax
    ret

; read sectors from disk
; parameters:
;   ax: lba
;   cl: number of sectors to read
;   dl: drive number
;   es:bx: memory address where to store read data
disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx                             ; temporarily save number of sectors to read contained in cl
    call lba_to_chs                     
    pop ax                              ; save number of sectors to al

    mov ah, 02h
    mov di, 3                           ; retry count

.retry:
    pusha                               ; save all registers since we dont know what registers interrupt will overwrite
    stc                                 ; set carry flag, some bios dont set it

    int 13h                             ; carry flag cleared = success
    jnc .done

    popa
    call disk_reset

    popa
    test di, di
    jnz .retry

.fail:
    jmp floppy_error

.done:
    popa

    pop ax
    pop bx
    pop cx
    pop dx
    pop di

    ret

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg: db 'Hello world', ENDL, 0
msg_read_failed: db 'Read from disk failed', ENDL, 0

times 510-($-$$) db 0

dw 0xAA55
