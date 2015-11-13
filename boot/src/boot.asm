[org 0x00]				; Set start address of code 0x00
[bits 16]				; Set as 16bits code from now

section .text				; Define text section(segment)

jmp 0x07c0:start			; Copy 0x07c0 to cs segment register and jump to start label

start:
	mov	ax, 0x07c0			; Change start address(0x7c00) of boot loader as value of segment register
	mov	ds, ax			; Set to ds segment register
	mov	ax, 0xb800		; Change start address(0xb800) of video memory as value of segment register
	mov	es, ax			; Set to es segment register

	mov	si, 0			; Initialize si register

.clear:
	mov	byte[es:si], 0x00	
	mov	byte[es:si+1], 0x07

	add	si, 2
	cmp	si, 80 * 25 * 2
	jl	.clear 

	mov	si, 0			; Initialize si register
	mov	di, 0			; Initialize di register

.messageloop:
	mov	cl, byte[si + message]
	cmp	cl, 0
	je	.messageloop

	mov	byte[es:di], cl

	add	si, 1
	add	di, 2

	jmp	.messageloop

.messageend:
	jmp	$

message:	db 'Hello, world!', 0

times 510 - ($ - $$) db 0x00	; $ : address of current line
				; $$ : start address of current section(.text)
				; $ - $$ : offset based on current section
				; 510 - ($ - $$) : From current to 510
				; db 0x00 : Declare 1 byte and value is 0x00
				; time : Execute repeatedly
				; Fill as 0x00 from current to 510 

db 0x55				; Declare 1 byte and value is 0x55
db 0xaa				; Declare 1 byte and value is 0xaa
				; Mark as a boot sector
