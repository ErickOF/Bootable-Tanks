.PHONY: all build clean runqemu

all: build runqemu

APP=tank

build:
	@nasm -f bin -o $(APP).img $(APP).asm
	@nasm -f bin -o $(APP).com -Dcom_file=1 $(APP).asm

clean:
	@rm $(APP).img $(APP).com

runqemu:
	# RAM = 4GB
	@qemu-system-i386 -m 4096 -drive file=$(APP).img,format=raw
