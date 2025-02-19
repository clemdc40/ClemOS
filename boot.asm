; boot.asm
[BITS 16]
[org 0x7C00]        ; Adresse de chargement du bootloader

start:
    ; Initialisation des segments (facultatif pour un premier test)
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Préparation pour l'affichage du texte
    mov si, message

print_char:
    lodsb           ; Charge le caractère pointé par SI dans AL et incrémente SI
    cmp al, 0
    je halt         ; Si le caractère est 0 (fin de chaîne), on sort de la boucle
    mov ah, 0x0E    ; Fonction d'affichage teletype du BIOS
    int 0x10        ; Appel de l'interruption BIOS pour afficher le caractère
    jmp print_char

halt:
    cli             ; Désactive les interruptions
    hlt             ; Arrête le processeur
    jmp halt        ; Boucle infinie pour ne pas continuer l'exécution

; Message à afficher (terminé par un 0)
message db "ClemOS", 0

; Remplissage jusqu'à 510 octets, puis signature 0xAA55 pour le bootloader
times 510 - ($ - $$) db 0
dw 0xAA55
