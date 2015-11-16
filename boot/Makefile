.PHONY: all clean boot.bin

all: boot.bin

boot.bin: src/boot.asm
	nasm -o $@ $<

clean:
	rm -f boot.bin
