; ===================================================================
;  Bootloader ClemOS - Passe en mode protégé, affiche un prompt
; ===================================================================
[ORG 0x7C00]       ; L'adresse où le BIOS charge ce secteur (512 octets)
[BITS 16]

start:
    ; Désactiver les interruptions
    cli

    ; Configuration de la GDT
    lgdt [gdt_descriptor]

    ; Passer en mode protégé : on met le bit PE (Protection Enable) dans CR0
    mov eax, cr0
    or  eax, 0x1
    mov cr0, eax

    ; Saut lointain (far jump) pour vider le pipeline et activer le PM
    jmp 0x08:protected_mode_entry


; -------------------------------------------------------------------
;  Mode protégé (32 bits)
; -------------------------------------------------------------------
[BITS 32]

protected_mode_entry:
    ; Initialiser les segments
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Initialiser la pile (pile très basique pour le moment)
    mov esp, 0x90000    ; Par exemple, on place la pile à 0x90000

    ; Appeler le code qui efface l'écran et affiche le prompt
    call start_command_prompt

.halt:
    ; Boucle infinie pour bloquer ici si jamais on en sort
    jmp .halt


; -------------------------------------------------------------------
;  Code du prompt et lecture clavier
; -------------------------------------------------------------------
start_command_prompt:
    ; Effacer l'écran (80x25)
    mov edi, 0xB8000
    mov ecx, 80*25
.clear_screen:
    mov word [edi], 0x0720  ; (0x20 = espace, 0x07 = gris sur noir)
    add edi, 2
    loop .clear_screen

    ; Réinitialiser le pointeur (en haut à gauche de l'écran)
    mov edi, 0xB8000

    ; Afficher "ClemOS >"
    mov esi, prompt_message
    call print_string

command_loop:
    ; Lire un scancode
    call read_key
    ; Afficher directement le scancode (pour l’exemple)
    ; Si tu veux afficher un caractère ASCII, il faudra convertir ici.
    mov [edi], al
    mov byte [edi+1], 0x0F  ; blanc sur noir
    add edi, 2
    jmp command_loop


; -------------------------------------------------------------------
;  Lecture du clavier (polling)
; -------------------------------------------------------------------
read_key:
.wait_key:
    in   al, 0x64       ; lire le status du contrôleur clavier
    test al, 1          ; vérifier si le buffer est plein
    jz .wait_key

    in al, 0x60         ; récupérer le scancode
    ret


; -------------------------------------------------------------------
;  Afficher une chaîne terminée par 0
; -------------------------------------------------------------------
print_string:
    mov ecx, 80  ; limite de sécurité (80 caractères max)
.print_loop:
    lodsb
    test al, al
    jz .done_print
    mov [edi], al
    mov byte [edi+1], 0x0F   ; blanc sur noir
    add edi, 2
    loop .print_loop
.done_print:
    ret


; -------------------------------------------------------------------
;  Chaînes et données
; -------------------------------------------------------------------
prompt_message db "ClemOS > ", 0


; -------------------------------------------------------------------
;  GDT : descripteurs pour le mode protégé
; -------------------------------------------------------------------
gdt:
    dq 0x0000000000000000     ; Descripteur NULL
    dq 0x00CF9A000000FFFF     ; Code segment 32 bits
    dq 0x00CF92000000FFFF     ; Data segment 32 bits

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt - 1      ; taille de la GDT - 1
    dd gdt                    ; adresse linéaire de la GDT


; -------------------------------------------------------------------
;  Remplir jusqu’à 512 octets et signer le secteur
; -------------------------------------------------------------------
times 510 - ($ - $$) db 0
dw 0xAA55
