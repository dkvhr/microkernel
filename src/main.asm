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

EBPB_DriveNumber:               db 0
EBPB_Flags:                     db 0
EBPB_Signature:                 db 0x28
EBPB_VolumeID:                  dd 0
EBPB_VolumeLabelString:         dq 0
EBPB_SystemIdentifier:          dq 0
EBPB_BootCode:                  db 0x13

start:
    jmp main

puts:
    push si
    push ax

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

    mov si, msg_hello
    call puts

    hlt

.halt:
    jmp .halt

msg_hello: db 'Hello!', ENDL, 0

times 510-($-$$) db 0
dw 0xaa55               ;db 0x55, 0xaa
