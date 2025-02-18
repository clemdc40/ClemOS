[org 0x7C00]      ; Adresse de chargement du bootloader
bits 16           ; Mode réel (16 bits)

start:
    cli           ; Désactiver les interruptions
    mov ax, 0x2401
    int 0x15      ; Désactiver le cache CPU (par sécurité)

    lgdt [gdt_desc]   ; Charger la GDT (pour passer en mode protégé)

    ; Activer le mode protégé (32 bits)
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp CODE_SEG:init_pm   ; Sauter en mode protégé

[bits 32]         ; Passage en mode protégé (32 bits)

init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Charger le kernel (adresse 0x100000)
    mov esp, 0x90000
    call KERNEL_ENTRY   ; Appeler le kernel

    jmp $

; GDT (Global Descriptor Table)
gdt:
    dq 0              ; Descripteur nul
gdt_code:
    dw 0xFFFF, 0x0000, 0x9A, 0xCF
gdt_data:
    dw 0xFFFF, 0x0000, 0x92, 0xCF
gdt_end:

gdt_desc:
    dw gdt_end - gdt - 1
    dd gdt

CODE_SEG equ gdt_code - gdt
DATA_SEG equ gdt_data - gdt
KERNEL_ENTRY equ 0x100000

times 510-($-$$) db 0
dw 0xAA55  ; Signature du bootloader
