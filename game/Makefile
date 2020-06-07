.PHONY: all build clean runqemu

all: clean build runqemu

APP=tank

build:
	@nasm -f bin -o $(APP).img $(APP).asm
	@nasm -f bin -o $(APP).com -Dcom_file=1 $(APP).asm

clean:
	@rm tank.img tank.com

runqemu: tank.img
	@qemu-system-i386 -fda tank.img
