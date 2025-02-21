/* kernel.c */
#include <stdint.h>
#include <stdbool.h>

// Définition de la mémoire vidéo (mode texte)
volatile uint16_t* const VGA_MEMORY = (uint16_t*)0xB8000;
const int VGA_WIDTH = 80;
const int VGA_HEIGHT = 25;

// Position du curseur
static int cursor_row = 0;
static int cursor_col = 0;

// Couleurs VGA
enum vga_color {
    VGA_COLOR_BLACK = 0,
    VGA_COLOR_WHITE = 15,
    // Ajoute d'autres couleurs si besoin
};

static inline uint8_t vga_entry_color(uint8_t fg, uint8_t bg) {
    return fg | bg << 4;
}

static inline uint16_t vga_entry(unsigned char uc, uint8_t color) {
    return (uint16_t)uc | (uint16_t)color << 8;
}

// --- Gestion du texte ---

// Efface l'écran
void clear_screen() {
    uint16_t blank = vga_entry(' ', vga_entry_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK));
    for (int y = 0; y < VGA_HEIGHT; y++) {
        for (int x = 0; x < VGA_WIDTH; x++) {
            VGA_MEMORY[y * VGA_WIDTH + x] = blank;
        }
    }
    cursor_row = 0;
    cursor_col = 0;
}

// Défilement de l'écran si on dépasse la dernière ligne
void scroll() {
    if (cursor_row < VGA_HEIGHT)
        return;
    for (int y = 1; y < VGA_HEIGHT; y++) {
        for (int x = 0; x < VGA_WIDTH; x++) {
            VGA_MEMORY[(y - 1) * VGA_WIDTH + x] = VGA_MEMORY[y * VGA_WIDTH + x];
        }
    }
    // Efface la dernière ligne
    for (int x = 0; x < VGA_WIDTH; x++) {
        VGA_MEMORY[(VGA_HEIGHT - 1) * VGA_WIDTH + x] = vga_entry(' ', vga_entry_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK));
    }
    cursor_row = VGA_HEIGHT - 1;
    cursor_col = 0;
}

// Affiche un caractère
void putchar(char c) {
    if (c == '\n') {
        cursor_col = 0;
        cursor_row++;
        scroll();
        return;
    } else if (c == '\r') {
        cursor_col = 0;
        return;
    } else {
        VGA_MEMORY[cursor_row * VGA_WIDTH + cursor_col] = vga_entry(c, vga_entry_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK));
        cursor_col++;
        if (cursor_col >= VGA_WIDTH) {
            cursor_col = 0;
            cursor_row++;
            scroll();
        }
    }
}

// Affiche une chaîne de caractères
void print(const char* str) {
    while (*str) {
        putchar(*str++);
    }
}

// --- Gestion mémoire (heap simple) ---
static uint32_t heap_end = 0x100000;  // Début du heap (1MB)

void* kmalloc(uint32_t size) {
    void* addr = (void*)heap_end;
    heap_end += size;
    return addr;
}

// --- Gestion des entrées (command prompt) ---

#define CMD_BUFFER_SIZE 256
char cmd_buffer[CMD_BUFFER_SIZE];
uint32_t cmd_index = 0;

// Pour simplifier, on fait un écho de la commande saisie
void process_command(const char* cmd) {
    print("\nYou entered: ");
    print(cmd);
    print("\nClemOS > ");
}

// Fonction d'accès aux ports (lecture d'une touche)
static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    asm volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

// Lecture d'une touche (polling)
// Note : En pratique, il faudra gérer les scancodes correctement et utiliser les interruptions.
char read_key() {
    uint8_t key = inb(0x60);
    return (char) key;
}

// Boucle de commande avec buffer, gestion du Backspace (scancode 0x0E ici)
void command_prompt() {
    print("ClemOS > ");
    while (1) {
        char c = read_key();
        if (c == 0x0E) {  // Backspace (attention, les scancodes réels nécessitent une conversion)
            if (cmd_index > 0) {
                cmd_index--;
                if (cursor_col == 0 && cursor_row > 0) {
                    cursor_row--;
                    cursor_col = VGA_WIDTH - 1;
                } else {
                    cursor_col--;
                }
                VGA_MEMORY[cursor_row * VGA_WIDTH + cursor_col] = vga_entry(' ', vga_entry_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK));
            }
        } else if (c == '\r' || c == '\n') {
            cmd_buffer[cmd_index] = '\0';
            process_command(cmd_buffer);
            cmd_index = 0;
        } else {
            if (cmd_index < CMD_BUFFER_SIZE - 1) {
                cmd_buffer[cmd_index++] = c;
                putchar(c);
            }
        }
    }
}

// --- Système de fichiers (stub pour FAT12) ---
// Ici, on simule la lecture d'un fichier depuis le disque.
bool read_file(const char* filename, void* buffer, uint32_t size) {
    print("\n[FS] Reading file: ");
    print(filename);
    print("\n");
    // Dans une vraie implémentation, on parserait la structure FAT12
    return true;
}

// --- Multitâche / Gestion des processus (très rudimentaire) ---
#define MAX_TASKS 4
typedef void (*task_func)();

typedef struct {
    uint32_t esp;   // Pour stocker le pointeur de pile, etc.
    bool active;
} task_t;

task_t tasks[MAX_TASKS];
uint32_t current_task = 0;

void scheduler_init() {
    for (int i = 0; i < MAX_TASKS; i++) {
        tasks[i].active = false;
    }
}

// Pour l'exemple, on "ajoute" une tâche en appelant simplement la fonction
void scheduler_add(task_func func) {
    for (int i = 0; i < MAX_TASKS; i++) {
        if (!tasks[i].active) {
            tasks[i].active = true;
            func();
            break;
        }
    }
}

// Stub d'un scheduler (boucle infinie)
void scheduler_run() {
    while (1) {
        // En vrai, ici il faudrait changer de contexte entre les tâches
        command_prompt();
    }
}

// Une tâche d'exemple
void dummy_task() {
    print("\n[Task] Dummy task running.\n");
    while(1); // Boucle infinie pour simuler une tâche
}

// --- Kernel main ---
void kernel_main() {
    clear_screen();
    print("Bienvenue sur ClemOS Kernel!\n");
    print("[Memory] Heap starts at 0x100000\n");

    // Initialisation du scheduler
    scheduler_init();

    // Exemple d'ajout d'une tâche (désactivé ici pour laisser le prompt fonctionner)
    // scheduler_add(dummy_task);

    // Lancement de la boucle du prompt
    command_prompt();

    while (1) {
        // Idle loop
    }
}
__attribute__((section(".text.entry")))
void _start() {
    kernel_main();
}
