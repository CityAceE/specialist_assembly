;Здесь пишем код
	device zxspectrum48
	org 0x0000

start:
        xor     a
        ld      (frame_counter),a
        ld      (x_coord),a
        ld      (y_coord),a

        ld      hl, map
        call    print_map

main_loop:
        call    clear_map_copy
        call    anim_map

        ld      hl, map_copy
        call    print_map

        ld      a, (frame_counter)
        add     4
        ld      (frame_counter), a

        call    change_coords

        ld      a, 0
        call    print_sprite_mask

        jp      main_loop

; Изменение координат спрайта
change_coords:
		call	keyboard
		or		a
		jp		z, no_key

		ld		b, a
		and		0b100
		jp		z, key_1
		ld		a, (x_coord)
		cp		45				; (384 - 24) / 8
		jp		nc, key_1
		inc		a
		ld		(x_coord), a
key_1:

		ld		a, b
		and		0b10000
		jp		z, key_2
		ld		a, (x_coord)
		or		a
		jp		z, key_2
		dec		a
		ld		(x_coord), a
key_2:

		ld		a, b
		and		0b10
		jp		z, key_3
		ld		a, (y_coord)
		or		a
		jp		z, key_3
		; dec		a
		sub		8
		ld		(y_coord), a
key_3:

		ld		a, b
		and		0b1
		jp		z, key_4
		ld		a, (y_coord)
		cp		256 - 24
		jp		nc, key_4
		; inc		a
		add		8
		ld		(y_coord), a
key_4:

no_key:
		ld		a, (x_coord)
		ld		d, a
		ld		a, (y_coord)
		ld		e, a

        ret

; Опрос клавиатуры на предмет нажатия курсорных клавиш и пробела
; Результат в регистре А
; A = 0 - не было нажатия
; Отдельные установленные биты:
; 0 - Вниз
; 1 - Вверх
; 2 - Вправо
; 4 - Влево
; 5 - Пробел
keyboard:
		ld		a, 0x91			; Программируем ППИ КР580ВВ55А
		ld		(0xff03), a		; Порты A и C - на ввод, порт B - на вывод

		ld		a, 0b11111011
		ld		(0xff01), a		; Отправляем 0 в строку матрицы с нужными клавишами

		ld		a, (0xff02)		; Встречаем 0 в левой половине клавиатуры
		cpl
		and 	0b00000011

		ld		b, a

		ld		a, (0xff00)		; Встречаем 0 в правой половине клавиатуры
		cpl
		and		0b00110100

		or		b

		ret

; Печать спрайта с маской
; D - координата X - 0...13
; E - координата Y - 0...232
; A - номер спрайта
print_sprite_mask:
        ld      hl, 0x9000
        add     hl, de
        ex      hl, de

        ; Умножаем A на 144
		ld		l, a
		ld		h, 0
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, hl
		ld		b, h
		ld		c, l
		add		hl, hl
		add		hl, hl
		add		hl, hl
		add		hl, bc

		ld		bc, sprites
		add		hl, bc

		ld		c, 3		; Количество столбцов в спрайте
print_sprite_mask_2:

		ld		b, 24		; Количество строк в спрайте
print_sprite_mask_1:
		ld		a, (de)

		or		(hl)			; В регистре A результат OR c маской

		inc		hl
		xor		(hl)			; В регистре A результат XOR со спрайтом

		ld		(de), a

		inc		e
		inc		hl

		dec		b
		jp		nz, print_sprite_mask_1

		ld		a, e
		sub		24
		ld		e, a

		inc		d
		dec		c
		jp		nz, print_sprite_mask_2
		ret

; Расставляем на копии карты текущие правильные кадры анимации спрайтов
anim_map:
		ld		bc, 384		; Длина всей карты
		ld		de, 0
		ld		hl, map

anim_map_2:
		ld		a, (hl)

		; Имеем номер тайла, нужно узнать его свойство
		push	hl
		push	de

		ld		hl, tiles_prop
		ld		d, 0
		ld		e, a
		add		hl, de
		ld 		a, (hl)
		and		0b00000011
		jp		z, anim_map_1
		call	calc_anim_frame
		; По возвращении кадр анимации, который нужно записать в копию карты
		; По смещению в DE

		pop		de	; Смещение от начала карты
		pop		hl	; Адрес в основной карте

		push 	bc
		ld		c, a
		ld		a, (hl)
		add		c	; В А текущий номер кадра для анимации
		pop		bc

		push 	hl
		ld		hl, map_copy
		add		hl, de
		ld		(hl),a
		pop		hl

		jp		anim_map_3

anim_map_1:
		pop		de	; Смещение от начала карты
		pop		hl	; Адрес в основной карте

anim_map_3:
		inc		hl
		inc		de
		dec		bc
		ld		a, b
		or		c
		jp		nz, anim_map_2

		ret

; HL - адрес текущего элемента на карте
; DE - номер текущего элемента на карте

; Нужно
; 1. Определить номер текущего кадра анимации
; 2. Записать его в копию карты


calc_anim_frame:
		ld		a, (hl)		; Загружаем свойство спрайта
		ld		e, a		; Сохраняем свойство спрайта

		and		0b11		; Количество кадров
		inc		a			; Необходимо перевести с 0...3 на 1...4
		ld 		h, a		; Сохраняем количество кадров

		ld		a, e
		and		0b11000		; Скорость анимации
		ld		e, a		; Сохраняем скорость анимации
		ld		d, a		; Сохраняем скорость анимации

		; Умножаем количество кадров на скорость анимации
		xor		a
calc_anim_frame_1:
		add		e
		dec		h
		jp		nz, calc_anim_frame_1

		; В A имеем длительность анимации текущего тайла в кадрах

		; Нужно поделить счётчик кадров на длительность анимации в кадрах
		; и получить остаток от деления
		ld		e, a
		ld		hl, frame_counter
		ld		a, (hl)
		; c - длительность анимации в кадрах
		; a - счётчик кадров
calc_anim_frame_3:
		cp 		e			; A - C
		jp		c, calc_anim_frame_2
		sub		e
		jp		calc_anim_frame_3
calc_anim_frame_2:

		; В A остаток от деления кадры/длительность анимации
		; Это текущая позиция в анимации

		; Текущую позицию (A) в анимации нужно поделить без остатка на скорость проигрывания (D)
		; Так мы получим текущий кадр анимации

		; A - текущая позиция в анимации
		; D - скорость анимации в кадрах

		ld		e, 0	; Текущий кадр
calc_anim_frame_5:
		cp		d
		jp		c, calc_anim_frame_4
		sub		d
		inc		e
		jp		calc_anim_frame_5

calc_anim_frame_4:
		ld		a, e
		; В A текущий кадр анимации для

		ret

; Очищаем копию карты
clear_map_copy:
        ld      hl, map_copy
        ld      bc, 384
clear_map_copy1:
        ld      a, 0xff
        ld      (hl), a
        inc     hl
        dec     bc
        ld      a, b
        or      c
        jp      nz, clear_map_copy1
        ret

; Печать карты по тайлам
; HL - адреc карты
print_map:
        ld      de, 0x0000

        ld      c, 16
print_map2:
        ld      b, 24
print_map_1:
        ld      a, (hl)
        cp      0xff
        jp      z, print_map_3
        call    print_tile_xy
print_map_3:
        inc     hl
        inc     d
        dec     b
        jp      nz, print_map_1

        ld      d, b
        inc     e
        dec     c
        jp      nz, print_map2
        ret

; Печать тайла по координатам
; A - номер тайла
; D - координата X = 0...24
; E - координата Y = 0...16
print_tile_xy:
        push    hl
        push    de
        push    bc

        push    de
        ld      h, 0
        ld      l, a

        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      de, tiles
        add     hl, de
        pop     de

        push    hl

        ld      a, e
        rla
        rla
        rla
        rla
        ld      e, a

        ld      a, d
        rla
        ld      d, a

        ld      hl, 0x9000
        add     hl, de
        ex      hl, de
        pop     hl

        call    print_tile

        pop     bc
        pop     de
        pop     hl

        ret

; Печать тайла 16*16
; HL - адрес данных спрайта
; DE - адрес в экранной области

print_tile:
        ld      b, 2
print_tile2:
        ld      c, 16
        push    de
print_tile1:
        ld      a, (hl) ; Спрайт
        ld      (de), a ; Экран
        inc     e
        inc     hl
        dec     c
        jp      nz, print_tile1
        pop     de
        inc     d
        dec     b
        jp      nz, print_tile2
        ret

 ; Свойства тайлов:
 ; 00 (2 бита) - количество кадров в анимации
 ; 0 (1 бит) - тип анимации
 ; 00 (2 бита) - скорость проигрывания анимации
 ; 000 (3 бита) - тип (пустота, поверхность, лестница и т.д.)
tiles_prop:
        db      0b00000000 ; 0 Пустота

        db      0b00100000 ; 1 Кирпич №1
        db      0b00100000 ; 2 Кирпич №2

        db      0b00000000 ; 3 Окно фрагмент №1
        db      0b00000000 ; 4 Окно фрагмент №2
        db      0b00000000 ; 5 Окно фрагмент №3
        db      0b00000000 ; 6 Окно фрагмент №4

        db      0b01000000 ; 7 Лестница поверх кирпича
        db      0b01000000 ; 8 Лестница

        db      0b00001111 ; 9 Цветок №1, 4 кадра, скорость 8
        db      0b00000000 ; 10
        db      0b00000000 ; 11
        db      0b00000000 ; 12

        db      0b00010111 ; 13 Цветок №2, 4 кадра, скорость 16
        db      0b00000000 ; 14
        db      0b00000000 ; 15
        db      0b00000000 ; 16

        db      0b00011111 ; 17 Цветок №3, 4 кадра, скорость 24
        db      0b00000000 ; 18
        db      0b00000000 ; 19
        db      0b00000000 ; 20

        db      0b00001111 ; 21 Цветок №4, 4 кадра, скорость 8
        db      0b00000000 ; 22
        db      0b00000000 ; 23
        db      0b00000000 ; 24

        db      0b00001111 ; 25 Волна №1, 4 кадра, скорость 8
        db      0b00000000 ; 26
        db      0b00000000 ; 27
        db      0b00000000 ; 28

        db      0b00001111 ; 29 Волна №2, 4 кадра, скорость 8
        db      0b00000000 ; 30
        db      0b00000000 ; 31
        db      0b00000000 ; 32

        db      0b00000000 ; 33 Кирпич №1
        db      0b00000000 ; 34 Кирпич №2

map:
        include "map.asm"

tiles:
        incbin  "sprites_2x2_nomask.bin"

sprites:
        incbin  "sprites_3x3_mask.bin"

finish:
        savebin "game.bin", start, finish-start

map_copy:
        defs    384, 0xff

frame_counter
        db      0

x_coord:
		db		0
y_coord:
		db		0
