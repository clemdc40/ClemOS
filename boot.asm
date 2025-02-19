[BITS 16]
[ORG 0x7C00]

cli
lgdt [gdt_descriptor]
mov eax, cr0
or eax, 0x1
mov cr0, eax
jmp 08h:start_protected_mode

[BITS 32]
start_protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov edi, 0xB8000      ; Adresse mémoire vidéo en mode texte
    mov esi, welcome_message
    call print_string

    jmp $

print_string:
    mov ecx, 80           ; On limite à 80 caractères
.loop:
    lodsb
    test al, al
    jz done
    mov [edi], al         ; Stocke le caractère ASCII
    mov byte [edi+1], 0x0F ; Définit la couleur (blanc sur noir)
    add edi, 2            ; Passe au caractère suivant
    loop .loop

done:
    ret

gdt:
    dq 0x0000000000000000  ; Null descriptor
    dq 0x00CF9A000000FFFF  ; Code segment (32-bit)
    dq 0x00CF92000000FFFF  ; Data segment

gdt_descriptor:
    dw (gdt_descriptor - gdt) - 1
    dd gdt

welcome_message db "ClemOS 32-bit Mode is running!", 0

times 510 - ($ - $$) db 0
dw 0xAA55
