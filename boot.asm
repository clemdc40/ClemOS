; boot.asm - Bootloader qui charge le kernel et passe en mode protégé
[org 0x7C00]
bits 16

start:
    cli                 ; Désactiver les interruptions
    mov ax, 0x0003
    int 0x10            ; Mode texte 80x25

    ; Charger le kernel en mémoire avant de passer en mode protégé
    mov ax, 0x1000      ; Segment où on va charger le kernel
    mov es, ax
    mov bx, 0x0000      ; Offset = 0

    mov ah, 0x02        ; BIOS: lire secteur(s)
    mov al, 1           ; lire 1 secteur (512 octets)
    mov ch, 0
    mov cl, 2           ; secteur #2
    mov dh, 0
    mov dl, 0x00        ; lecteur de disquette A:
    int 0x13
    jc disk_error       ; Si erreur, afficher un message

    ; Activer la ligne A20
    in al, 0x92
    or al, 00000010b
    out 0x92, al

    ; Charger la GDT
    lgdt [gdt_descriptor]

    ; Passer en mode protégé
    cli
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp 0x08:pm_entry   ; Saut lointain pour recharger CS (Code segment GDT)

; ================================
; Mode protégé (PM)
; ================================
[bits 32]
pm_entry:
    mov ax, 0x10        ; Sélecteur data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000    ; Initialisation de la pile

    ; Saut vers le kernel chargé à 0x10000 avec le bon sélecteur
    jmp 0x08:0x10000

; ================================
; Global Descriptor Table (GDT)
; ================================
gdt_start:
    dq 0                ; Descripteur NULL

; -- Code segment (0x08) --
gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b        ; 0x9A = Code segment, exécutable
    db 11001111b        ; 0xCF = Limite en pages, 32 bits
    db 0x00

; -- Data segment (0x10) --
gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b        ; 0x92 = Data segment, lisible
    db 11001111b        ; 0xCF = Limite en pages, 32 bits
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Taille de la GDT
    dd gdt_start                ; Adresse linéaire de la GDT

; ================================
; Message en mode réel
; ================================
[bits 16]
print_string:
    pusha
.next_char:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    int 0x10
    jmp .next_char
.done:
    popa
    ret

disk_error:
    mov si, disk_error_msg
    call print_string
    hlt

disk_error_msg db "Erreur de lecture du disque!", 0

; Signature du bootloader (obligatoire)
times 510 - ($ - $$) db 0
dw 0xAA55
