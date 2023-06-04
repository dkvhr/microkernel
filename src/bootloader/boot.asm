    [org 0x7c00]
    [BITS 16]

    %define ENDL 0x0D, 0x0A

    ; HEADER
    jmp short start                 ;EB 3C 90
    nop

BPB_OEM:                        db 'LEEJIEUN'       ; IUxUAENAS !!!
BPB_BytesPerSector:             dw 0x0200
BPB_SectorsPerCluster:          db 1
BPB_ReservedSectors:            dw 1
BPB_NumberOfFATs:               db 2
BPB_RootEntriesCount:           dw 0xe0
BPB_SectorsInLogicalVolume:     dw 0x800            ; 1MB
BPB_MediaDescriptorType:        db 0xf0
BPB_SectorsPerFAT:              dw 9
BPB_SectorsPerTrack:            dw 18
BPB_NumberOfHeads:              dw 2
BPB_NumberOfHiddenSectors:      dd 0
BPB_Large_Sector_Count:         dd 0

    ;; extended boot record (EBR)
EBR_DriveNumber:                db 0
                                db 0
EBR_Signature:                  db 0x28
EBR_VolumeID:                   db 0x12, 0x34, 0x56, 0x78
EBR_VolumeLabelString:          db 'LEEJIEUN OS'
EBR_SystemIdentifier:           db 'FAT12   '
EBR_BootCode:                   db 0x13

start:
        jmp main

puts:
        push si
        push ax
        push bx

.loop:
        lodsb
        or al, al
        jz .done

        mov ah, 0x0e
        mov bh, 0
        int 0x10

        jmp .loop

.done:
        pop ax
        pop si
        ret

main:
        mov ax, 0
        mov ds, ax
        mov es, ax

        mov ss, ax
        mov sp, 0x7c00

    ;; reading from floppy disk:
        mov [EBR_DriveNumber], dl

        mov ax, 1
        mov cl, 1
        mov bx, 0x7e00
        call disk_read

        mov si, msg_hello
        call puts

        cli
        hlt

    ;; in case of reading error

floppy_error:
        mov si, msg_fail
        call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 0x16
    jmp 0x0FFFF:0

.halt:
    cli
        jmp .halt


logic_block_address_to_cylinder_head_sector_address:
    push ax
    push dx
        xor dx, dx
        div word [BPB_SectorsPerTrack] ; ax=LBA/SectorsPerTrack
                                    ; dx=LBA%SectorsPerTrack
        inc dx
        mov cx, dx                     ; cx = sector

        xor dx, dx
        div word [BPB_NumberOfHeads]   ; ax=(LBA/SectorsPerTrack)/Heads  ;(cylinder)
                                    ; dx=(LBA/SectorsPerTrack)%Heads  ;(Head)
        mov dh, dl                     ; dl is the head number!
        mov ch, al                     ; ch = cylinder()
        shl ah, 6
        or cl, ah

        pop ax
        mov dl, al
        pop ax
        ret

    ;; Disk read (INT 13h)
    ;; ah=02
    ;; al=number of sectors
    ;; ch=track/cylinder number
    ;; cl=sector number
    ;; dl=drive number
    ;; es=bx=pointer to buffer

disk_read:
        ;; saving registers :)
        push ax
        push bx
        push cx
        push dx
        push di

        push cx
        call logic_block_address_to_cylinder_head_sector_address
        pop ax
        mov ah, 0x2
        mov di, 3
    .retry:
        pusha
        stc
        int 0x13
        jnc .done

        popa
        call disk_reset

        dec di
        test di, di
        jnz .retry

    .fail:
        jmp floppy_error

    .done:
        popa
        ;; restoring registers

        pop di
        pop dx
        pop cx
        pop bx
        pop ax
        ret

    ;; disk reset
disk_reset:
        pusha
        mov ah, 0
        stc
        int 0x13
        jc floppy_error
        popa
        ret

msg_hello:
        db 'Hello!', ENDL, 0
msg_fail:
        db 'Reading failed', ENDL, 0

times 510-($-$$) db 0
dw 0xaa55               ;db 0x55, 0xaa
