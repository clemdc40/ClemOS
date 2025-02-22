// kernel.c - Kernel minimal qui affiche "ClemOs >" et boucle
void kmain(void)
{
    volatile char* video = (volatile char*)0xB8000;

    // Nettoyer l'écran
    for (int i = 0; i < 80 * 25; i++) {
        video[i * 2]     = ' ';    // Espace
        video[i * 2 + 1] = 0x07;   // Couleur gris clair sur fond noir
    }

    // Afficher "ClemOs > " en haut à gauche
    const char* message = "ClemOs > ";
    int i = 0;
    while (message[i] != '\0') {
        video[i * 2]     = message[i];
        video[i * 2 + 1] = 0x07;   // Attribut
        i++;
    }

    // Boucle infinie pour éviter que le kernel ne quitte
    while (1) {
        __asm__ __volatile__("hlt");
    }
}
