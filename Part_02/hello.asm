	device zxspectrum48
	org 0x0000
start:	
	
coord_x equ	10
coord_y equ 10

	ld a, 0x40
	ld (0xFF02),a

	ld de, (0x90 + coord_x) * 256 + 8 * coord_y
	ld hl, text

next_symbol:	
	ld a, (hl)
	or a
	jp z,loop
	
	push hl
	push de
	call print_symbol
	pop de
	pop hl

	inc d
	inc hl

	jp next_symbol
	
loop:
	jp loop


print_symbol:
	ld h, 0
	ld l, a
	
	add hl, hl
	add hl, hl
	add hl, hl

	ld bc, font0
	add hl, bc
	
	ld b, 8

symbol:	
	ld a, (hl)
	cpl
	ld (de), a
	inc hl
	inc de
	dec b
	jp nz, symbol
	
	ret

font:
	incbin "font.bin"
	
text:	
	db "Hello, World!", 0
	
font0 equ font - 32 * 8
	
finish:	
	savebin "hello.bin", start, finish-start