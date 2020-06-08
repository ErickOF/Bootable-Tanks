.PHONY: all build clean runqemu

all: build runqemu



build:
	@nasm -f bin bootload.asm -o bootload.bin
	@nasm -f bin stage2.asm -o stage2.bin
	dd if=/dev/zero of=disk.img bs=1024 count=720
	dd if=bootload.bin of=disk.img conv=notrunc
	dd if=stage2.bin of=disk.img bs=512 seek=1 conv=notrunc


clean:
	@rm -f bootload.bin stage2.bin disk.img

runqemu:
	# RAM = 4GB
	@qemu-system-i386 -m 512 -drive file=disk.img,format=raw
