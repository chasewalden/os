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

;input:
;si holds string

printLoad:
	mov al, [loading]
	call printchr
	ret

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
	
		

loadRootDir:	

	call printLoad

	xor cx, cx
	xor dx,dx
	mov ax, 0x0020
	mul WORD [rootEntries]
	div WORD [bytesPerSector]
	xchg ax, cx

	call printLoad

	mov al, BYTE [numberOfFATs]
	mul WORD [sectorsPerFAT]
	add ax, WORD [reservedSectors]
	mov WORD [datasector], ax
	add WORD [datasector], cx

	call printLoad

	mov bx, 0x0200
	call readSectors

	mov cx, WORD [rootEntries]
	mov di, 0x0200

	.loop:
	
	call printLoad

	push cx
	mov cx, 0x000B
	push si
	push di
	rep cmpsb
	pop di
	je loadFAT
	pop cx
	add di, 0x0020
	loop .loop
	mov al, 0x01
	call error

loadFAT:
	
	call printLoad

	mov dx, WORD [di + 0x001A]
	mov WORD [cluster], dx

	xor ax,ax
	mov al, BYTE [numberOfFATs]
	mul WORD [sectorsPerFAT]
	mov cx, ax

	mov ax, WORD [reservedSectors]

	mov bx, 0x0200
	call readSectors

	call printLoad

	mov ax, 0x0050
	mov es, ax
	xor bx, bx
	push bx

loadKernel:

	call printLoad

	mov ax, WORD [cluster]
	pop bx
	call ClusterLBA
	xor cx, cx
	mov cl, BYTE [sectorsPerCluster]
	call readSectors
	push bx

	;compute cluster

	mov ax, WORD [cluster]
	mov cx, ax
	mov dx, ax
	shr dx, 0x0001
	add cx, dx
	mov bx, 0x0200
	add bx, cx
	mov dx, WORD [bx]
	test ax, 0x0001
	jnz .odd

.even:
	and dx, 0000111111111111b
	jmp .done
.odd:
	shr dx, 0x0004
.done:
	mov WORD [cluster], dx
	cmp dx, 0x0FF0
	jb loadKernel

readSectors:

.main:	
	mov di, 0x0005
		
.loop:
	push ax
	push bx
	push cx
	call LBACHS
	mov ah, 0x02
	mov al, 0x01
	mov ch, BYTE [absoluteTrack]
	mov cl, BYTE [absoluteSector]
	mov dh, BYTE [absoluteHead]
	mov dl, BYTE [driveNumber]

ClusterLBA:
	
LBACHS:
error:
	mov si, err
	call print
	add al, 0x30
	call printchr

;fill the rest of the file

datasector 	dw 0x0000
cluster 	dw 0x0000

absoluteSector	db 0x00
absoluteHead	db 0x00
absoluteTrack	db 0x00

filename 	db "KERNEL  SYS"
err 		db 10,13,"ERROR = ",0
finding		db "Loading Kernel",0
loading 	db ">"

times 510 - ($ - $$) db 0

sig:	dw 0xaa55

