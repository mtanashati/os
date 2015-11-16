[org 0x00]				; Set start address of code 0x00
[bits 16]				; Set as 16bits code from now

section .text				; Define text section(segment)

jmp 0x07c0:start			; Copy 0x07c0 to cs segment register and jump to start label

total:	dw	1024			; OS image size except for bootloader
					; Maximum size : 1152 sectors(0x90000byte)

start:
	mov	ax, 0x07c0		; Change start address(0x7c00) of boot loader as value of segment register
	mov	ds, ax			; Set to ds segment register
	mov	ax, 0xb800		; Change start address(0xb800) of video memory as value of segment register
	mov	es, ax			; Set to es segment register

	; Create stack area on 0x0000:0000~0x0000:ffff
	mov 	ax, 0x0000
	mov	ss, ax
	mov	sp, 0xfffe
	mov	bp, 0xfffe

	mov	si, 0			; Initialize si register

.clear:
	mov	byte[es:si], 0x00	
	mov	byte[es:si+1], 0x6f

	add	si, 2
	cmp	si, 80 * 25 * 2
	jl	.clear 

	; Print Starting message on the top
	push	STARTINGMESSAGE		; Push address of message in the stack
	push	0			; Y-coordinate
	push	0			; X-coordinate
	call	PRINTMESSAGE		; Call print function
	add	sp, 6			; Remove parameters

	; Print OS loading message
	push	LOADINGMESSAGE		; Push address of message in the stack
	push	1			; Y-coordinate
	push	0			; X-coordinate
	call	PRINTMESSAGE		; Call print function
	add	sp, 6			; Remove parameters

	; Loading os image from the disk
	; Before read the disk, reset
resetdisk:
	; Call BIOS reset function
	; service number 0, drive number(0 = Floppy)
	mov	ax, 0
	mov	dl, 0
	int	0x13
	; If error occurs, move to error handler
	jc	diskerror

	; Read sector from the disk
	; Set memory address(es:bx) 0x10000
	mov	si, 0x1000
	mov	es, si
	mov	bx, 0x0000
	mov	di, word[total]

readdata:
	; Check if all sectors are read
	cmp	di, 0			; Compare 0 with sectors of OS image
	je	readend
	sub	di, 0x1			; Decrease 1

	; Call BIOS function
	mov	ah, 0x02		; BIOS service number 2(Read sector)
	mov	al, 0x1			; How many sectors would you read?
	mov	ch, byte[track]		; Set track number
	mov	cl, byte[sector]	; Set sector number
	mov	dh, byte[head]		; Set head number
	mov	dl, 0x00		; Set drive number(0=Floppy)
	int	0x13			; Execute interrupt service
	jc	diskerror		; If error occurs, move to error handler

	; Caculate address, track, head, sector
	add	si, 0x0020		; 512 bytes to segment value
	mov	es, si			; Increase 1 sector

	; Check if last sector(18) is read
	; If it's not last sector move to readdata and read again
	mov	al, byte[sector]
	add	al, 0x01
	mov	byte[sector], al
	cmp	al, 19
	jl	readdata

	; If head changed 1->0 means both sides of head are read
	; So move to down and increase track number
	cmp	byte[head], 0x00	; Compare 0x00 with head number
	jne	readdata		; If head number is not 0 move to readdata

	; Move to readdata after increase sector
	add	byte[track], 0x01
	jmp	readdata

readend:
	; Print complete message
	push	COMPLETEMESSAGE
	push	1
	push	20
	call	PRINTMESSAGE
	add	sp, 6

	; Execute loaded virtual OS image
	jmp	0x1000:0x0000

; Function code area
; Function for handling disk error
diskerror:
	push	ERRORMESSAGE
	push	1
	push	20
	call	PRINTMESSAGE

	jmp $				; Infinite loop

; Message print function
; @param: x, y, text
PRINTMESSAGE:
	push	bp
	mov	bp, sp
	push	es
	push	si
	push	di
	push	ax
	push	cx
	push	dx

	mov	ax, 0xb800
	mov	es, ax

	; Calculate address of video memory with x, y
	; Get the line address first using y
	mov	ax, word[bp + 6]
	mov	si, 160
	mul	si
	mov	di, ax

	; Get the final address using x * 2
	mov	ax, word[bp + 4]
	mov	si, 2
	mul	si
	add	di, ax

	; Address of message
	mov	si, word[bp + 8]

.messageloop
	mov	cl, byte[si]
	cmp	cl, 0
	je	.messageend

	mov	byte[es:di], cl
	add	si, 1
	add	di, 2
	jmp	.messageloop

.messageend:
	pop	dx
	pop	cx
	pop	ax
	pop	di
	pop	si
	pop	es
	pop	bp
	ret

; Data area
; Starting message of bootloader
STARTINGMESSAGE:	db 'SANGGYU OS BOOT LOADER START', 0;
ERRORMESSAGE:		db 'DISK ERROR', 0
LOADINGMESSAGE:		db 'OS IMAGE LOADING...', 0
COMPLETEMESSAGE:	db 'COMPLETE', 0

; Variables related to disk read
sector:	db 0x02
head:	db 0x00
track:	db 0x00

times 510 - ($ - $$) db 0x00		; $ : address of current line
					; $$ : start address of current section(.text)
					; $ - $$ : offset based on current section
					; 510 - ($ - $$) : From current to 510
					; db 0x00 : Declare 1 byte and value is 0x00
					; time : Execute repeatedly
					; Fill as 0x00 from current to 510 

db 0x55					; Declare 1 byte and value is 0x55
db 0xaa					; Declare 1 byte and value is 0xaa
					; Mark as a boot sector
