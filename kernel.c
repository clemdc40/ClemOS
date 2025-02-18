#include <stdint.h>

#define MULTIBOOT_MAGIC 0x1BADB002
#define MULTIBOOT_FLAGS 0
#define CHECKSUM -(MULTIBOOT_MAGIC + MULTIBOOT_FLAGS)

__attribute__((section(".multiboot")))
const uint32_t multiboot_header[] = {
    MULTIBOOT_MAGIC,
    MULTIBOOT_FLAGS,
    CHECKSUM
};

#define VGA_WIDTH  80
#define VGA_HEIGHT 25
#define VGA_ADDRESS 0xB8000

void clear_screen() {
    uint16_t* vga_buffer = (uint16_t*)VGA_ADDRESS;
    uint16_t blue_color = (1 << 12) | (' ' & 0xFF);  // Fond bleu

    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga_buffer[i] = blue_color;
    }
}

void kernel_main() {
    clear_screen();
    while (1);
}
