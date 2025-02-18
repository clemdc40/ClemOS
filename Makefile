ASM = nasm
CC = x86_64-linux-gnu-gcc
LD = x86_64-linux-gnu-ld
CFLAGS = -ffreestanding -m32 -fno-pic -nostdlib -lgcc
LDFLAGS = -m elf_i386

all: build/boot.bin build/kernel.bin build/os.iso

build/boot.bin: boot.asm
	mkdir -p build
	$(ASM) -f bin boot.asm -o build/boot.bin

build/kernel.bin: kernel.c
	mkdir -p build
	$(CC) $(CFLAGS) -c kernel.c -o build/kernel.o
	$(LD) $(LDFLAGS) -T linker.ld -o build/kernel.bin build/kernel.o

build/os.iso: build/boot.bin build/kernel.bin
	mkdir -p iso/boot/grub
	cp build/kernel.bin iso/boot/kernel.bin
	echo 'set timeout=0' > iso/boot/grub/grub.cfg
	echo 'set default=0' >> iso/boot/grub/grub.cfg
	echo 'menuentry "My OS" {' >> iso/boot/grub/grub.cfg
	echo '    multiboot /boot/kernel.bin' >> iso/boot/grub/grub.cfg
	echo '}' >> iso/boot/grub/grub.cfg
	grub-mkrescue -o build/os.iso iso/

run: build/os.iso
	qemu-system-x86_64 -cdrom build/os.iso

clean:
	rm -rf build iso
