.PHONY: all run clean disk.img

all: disk.img

disk.img: 
	@echo Build boot loader...
	make -C boot
	@echo Build complete...
	@echo Build kernel...
	make -C kernel
	@echo Build complete...
	@echo Disk image build start...
	cat boot/boot.bin kernel/vOS.bin > $@
	@echo All build complete...

QEMU = qemu-system-x86_64 -L . -m 256 -drive file=disk.img -M pc

run: disk.img
	sudo $(QEMU) -monitor stdio

clean: 
	make -C boot clean
	make -C kernel clean
	rm -f disk.img
