.PHONY: all build clean runqemu move

all: build runqemu

APP=tank
#/dev/sdb

DEVICE = output.img
SIZE=6
TANKSIZE = $(shell echo $$(( $(SIZE) - 1 )))

# windows can't use dd, replace it with:
# copy /b bootload.bin+tank.bin disk.img

build:
	@nasm -f bin bootload.asm -o bootload.bin
	@nasm -f bin $(APP).asm -o $(APP).bin
	dd if=/dev/zero of=$(APP).img bs=1024 count=$(SIZE)
	dd if=bootload.bin of=$(APP).img conv=notrunc
	dd if=$(APP).bin of=$(APP).img bs=512 count=$(TANKSIZE) seek=1 conv=notrunc 

clean:
	@rm -f *.bin *.img

runqemu:
	# RAM = 4GB  
	@qemu-system-i386 -m 512 -drive file=$(APP).img,format=raw

# run as:  make move DEVICE=/dev/sd*  (commonly sdb) 
# check devices with sudo fdisk -l
move:
	@sudo dd if=$(APP).img of=$(DEVICE)
	@sync #flushes the stream