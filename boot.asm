; boot.asm – Bootloader (stage 1) 16 bits, 512 octets max

[ORG 0x7C00]
[BITS 16]

start:
    cli
    ; Affiche un message de chargement (optionnel, en 16 bits)
    mov si, kernel_load_msg
    call print_string

    ; Charger le kernel depuis le disque (par exemple, 10 secteurs à partir du secteur 2)
    mov ah, 0x02         ; fonction lecture secteur
    mov al, 10           ; nombre de secteurs
    mov ch, 0            ; cylindre 0
    mov cl, 2            ; secteur 2
    mov dh, 0            ; tête 0
    mov dl, 0            ; disque 0
    mov ax, 0x2000       ; Charger à 0x20000
    mov es, ax
    mov bx, 0x0000
    int 0x13

    ; Passer en mode protégé n'est pas nécessaire ici si le kernel en 32 bits le gère
    ; On saute directement vers le kernel chargé à 0x20000.
    ; Utilisation d'un saut loin (far jump)
    jmp 0x2000:0x0000

; Routine simple pour afficher une chaîne (16 bits, utilisant BIOS)
print_string:
    mov ax, 0xB800       ; Charger le segment VGA dans AX
    mov es, ax           ; ES = 0xB800
    mov di, 0            ; Offset à 0 (début de la mémoire VGA)
.print_char:
    lodsb                ; Charger le caractère suivant dans AL
    cmp al, 0            ; Fin de la chaîne ?
    je .done
    mov [es:di], al      ; Écrire le caractère dans la mémoire VGA
    mov byte [es:di+1], 0x07  ; Attribuer une couleur (par exemple, blanc sur noir)
    add di, 2            ; Avancer au prochain caractère (2 octets par caractère)
    jmp .print_char
.done:
    ret

; --- Remplissage pour atteindre 510 octets ---
kernel_load_msg db "Loading kernel...", 0  ; ✅ Déplacé avant `times 510`
times 510 - ($ - $$) db 0
dw 0xAA55
