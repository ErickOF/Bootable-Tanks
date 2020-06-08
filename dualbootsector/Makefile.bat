nasm -f bin bootload.asm -o bootload.bin
nasm -f bin stage2.asm -o stage2.bin
copy /b bootload.bin+stage2.bin disk.img

qemu-system-i386 -m 512 -drive file=disk.img,format=raw
