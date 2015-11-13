.PHONY: all run clean

all: disk.img

disk.img: 
	@echo Build boot loader...
	make -C boot
	@echo Build complete...
	@echo Disk image build start...
	cp boot/boot.bin $@
	@echo All build complete...

QEMU = qemu-system-x86_64 -L . -m 256 -drive file=disk.img -M pc

run: disk.img
	sudo $(QEMU) -monitor stdio

clean: 
	make -C boot clean
	rm -f disk.img
