;Здесь пишем код
	device zxspectrum48
	org 0x0000

start:

	ld hl, map
	ld de, 0x0000

	ld c, 16
print_map2:
	ld b, 24
print_map:
	ld a, (hl)
	call print_tile_xy
	inc hl
	inc d
	dec b
	jp nz, print_map

	ld d, b
	inc e
	dec c
	jp nz, print_map2

loop: jp loop

; Печать тайла по координатам
; A - номер тайла
; D - координата X = 0...24
; E - координата Y = 0...16
print_tile_xy:
	push hl
	push de
	push bc


	push de
	ld h, 0
	ld l, a

	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	ld de, tiles
	add hl, de
	pop de

	push hl

	ld a, e
	rla
	rla
	rla
	rla
	ld e, a
	
	ld a, d
	rla
	ld d, a


	ld hl, 0x9000
	add hl, de
	ex hl, de
	pop hl


	call print_tile
	
	
	pop bc
	pop de
	pop hl
	
	ret

; Печать тайла 16*16
; HL - адрес данных спрайта
; DE - адрес в экранной области

print_tile:
	ld b, 2
print_tile2:
	ld c, 16
	push de
print_tile1:
	ld a, (hl) ; Спарйт
	ld (de), a ; Экран
	inc e
	inc hl
	dec c
	jp nz, print_tile1
	pop de
	inc d 
	dec b
	jp nz, print_tile2
	ret

map:
	include "map.asm"

tiles:
	incbin "sprites_2x2_nomask.bin"

finish:	
	savebin "game.bin", start, finish-start
