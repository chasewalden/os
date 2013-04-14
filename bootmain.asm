;Boot.asm
;first stage boot loader for TurbOS
;Chase Walden
;September 5, 2012

BITS 16
ORG 0X0000

start: jmp main ;skip BPB

OEM			db "TurbOS  "
bytesPerSector		dw 512
sectorsPerCluster	db 1
reservedSectors		dw 2
numberOfFATs		db 2
rootEntries		dw 224
totalSectors		dw 1440
identifier		db 0xf9
sectorsPerFAT		dw 9
sectorsPerTrack		dw 9
headsPerCylender	dw 2
hiddenSectors		dd 0
numberBigSectors	dd 0
driveNumber		db 0
unused			db 0
extraBootSig		db 0x29
serialNumber		dd 0xa0a1a2a3
volumeLabel		db "TURBOS TEST"
fileSystem		db "FAT12   "

;BPB

printchr;
	mov ah, 0x0E
	int 0x10
	ret

print:
	lodsb ;load next byte from si into al
	mov bl, 0x0A
	or al,al
	jz .done

	call printchr
	
	jmp print
	
.done:
	ret

main:

	cli
	mov ax, 0x07C0
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	
	;Make Stack
	
	mov ax, 0x0000 ;bottom of stack
	mov ss, ax
	mov sp, 0xFFFF ;top of stack
	sti

	mov si, finding
	call print

	;call readSector
	
	cli
	hlt		

finding db "Hello World!!!",0x00



