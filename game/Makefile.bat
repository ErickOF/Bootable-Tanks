nasm -f bin -o tank.img tank.asm
nasm -f bin tank.asm -o tank.bin
copy /b bootload.bin+tank.bin disk.img


qemu-system-i386 -m 512 -drive file=tank.img,format=raw
