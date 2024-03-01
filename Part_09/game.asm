;Здесь пишем код
        device  zxspectrum48
        org     0x0000

start:
        ; Инициализируем нужные переменные
        xor     a
        ld      (frame_counter), a
        
		ld		a, 13
		ld      (x_coord), a
        ld		a, 56
		ld      (y_coord), a

        ld      hl, map
        call    print_map           ; Рисуем на экране полную карты

main_loop:
        ld      a, (frame_counter)  ; Увеличиваем счётчик "кадров"
        add     4
        ld      (frame_counter), a

		call    clear_map_copy      ; Заполняем копию карты кодом 0xFF
        call    restore_background  ; Восстанавливаем фон под персонажем
        call    anim_map            ; Расставляем на карте нужные кадры анимации тайлов
        call    change_coords       ; Изменяем координаты персонажа по нажатию на клавиши
		call	fill_buff           ; Рисуем в теневом буфере задник и накладываем на него спрайт персонажа
        call    clear_map_buf       ; Очищает место под буфером в копии карты

        ld      hl, map_copy
        call    print_map           ; Рисуем на экране карту из копии

		call 	print_buf_xy        ; Рисуем на экране содержимое буфера
        call    anim_sprite         ; Вычисляем следующий кадр анимации персонажа

        jp      main_loop
;=======================================================

; Процедура заполнения буфера 32*32 четырьмя тайлами из основной карты
fill_buff:
; Копируем 4 тайла из основной карты в карту буфера (2*2)
		ld		hl, map
		call	coord_to_map_calc
		ld		de, map_copy_buf
		ld		bc, 23	            ; Для перехода на следующую строку
		ld		a, (hl)
		ld		(de), a
		inc		hl
		inc		de
		ld		a, (hl)
		ld		(de), a
		add		hl, bc
		inc		de
		ld		a, (hl)
		ld		(de), a
		inc		hl
		inc		de
		ld		a, (hl)
		ld		(de), a

; Дополнительно копируем анимированные тайлы из копии карты, если они есть
		ld		hl, map_copy
		call	coord_to_map_calc
		ld		de, map_copy_buf
		ld		a, (hl)
		cp		0xff
		jp		z, anim_copy_1
		ld		(de), a
anim_copy_1:
		inc		hl
		inc		de
		ld		a, (hl)
		cp		0xff
		jp		z, anim_copy_2
		ld		(de), a
anim_copy_2:
		ld		bc, 23
		add		hl, bc
		inc		de
		ld		a, (hl)
		cp		0xff
		jp		z, anim_copy_3
		ld		(de), a
anim_copy_3:
		inc		hl
		inc		de
		ld		a, (hl)
		cp		0xff
		jp		z, anim_copy_4
		ld		(de), a
anim_copy_4:

; Печатаем 4 тайла в буфер из буферной карты
		ld		hl, map_copy_buf
		ld 		de, buffer
		ld		bc, 4	            ; Количество печатаемых тайлов

fill_buff_3:
		push	hl
		push	bc

		; По номеру тайла вычисляем его адрес массиве тайлов
		ld		a, (hl)
		ld      h, 0
        ld      l, a

        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      bc, tiles
        add     hl, bc	            ; В HL адрес нужного тайла

        ; Печать тайла в буфер
		; Непосредственная печать одного тайна в нужное место буфера
		ld		b, 2			    ; Ширина тайла в байтах
fill_buff_2:
		ld		c, 16			    ; Высота тайла в пикселях
fill_buff_1:
		ld		a, (hl)			    ; Тайл
		ld		(de), a			    ; Буфер
		inc		de
		inc		hl
		dec		c
		jp		nz, fill_buff_1

		push	hl
		ld		hl, 16
		add		hl, de
		ex		hl, de
		pop		hl

		dec		b
		jp		nz, fill_buff_2

		; После печати тайла нужно подготовить данные для печати следующего: адрес в буфере и адрес в буферной карте
		pop		bc
		ld		hl, buf_tab - 2
		add		hl, bc
		ld		e, (hl)
		ld		d, b
		ld		hl, buffer
		add		hl, de
		ex		hl, de
		pop		hl
		inc		hl
		dec		c
		jp		nz, fill_buff_3

; Здесь печатаем спрайт с маской в буфер
		 ; Печать спрайта с маской
		; A - номер спрайта

		; Определяем положение спрайта внутри буфера по координатам из x_coord и y_coord
		ld      hl, buffer
		ld		a,	(x_coord)
		and		1
		ld		e, 32
		jp		nz, buf_coord_1
		ld		e, a
buf_coord_1:
		ld		d, 0
		add		hl, de
		ld		a,	(y_coord)
		and		0b1111
		ld		e, 8
		jp		nz, buf_coord_2
		ld		e, a
buf_coord_2:
		ld		d, 0
		add		hl, de
		ex		de, hl
		; В DE адрес в буфере для печати спрайта

		; Выясняем адрес нужного кадра анимации спрайта
		ld		a, (current_anim)
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
		; В HL адрес нужного спрайта

		ld		c, 3		; Количество столбцов в спрайте
print_sprite_mask_buf_2:

		ld		b, 24		; Количество строк в спрайте
print_sprite_mask_buf_1:
		ld		a, (de)
		or		(hl)		; В регистре A результат OR c маской
		inc		hl
		xor		(hl)		; В регистре A результат XOR со спрайтом
		ld		(de), a

		inc		de
		inc		hl

		dec		b
		jp		nz, print_sprite_mask_buf_1

		; Переход на следующий столбец буфера = DE + 8
		push	hl
		ld		hl, 8
		add		hl, de
		ex		hl, de
		pop		hl

		dec		c
		jp		nz, print_sprite_mask_buf_2
		;--------------------------------------------------------
		ret

; Таблица сдвигов от начала для 4-х тайлов (исключая нулевой)
buf_tab:
		db		80, 16, 64

; Очищает (0xFF) в копии карты место под вывод буфера
clear_map_buf:
		ld		hl, map_copy
		call	coord_to_map_calc
		ld		a, 0xff
		ld		(hl), a
		inc		hl
		ld		(hl), a
		ld		de, 23
		add		hl,	de
		ld		(hl), a
		inc		hl
		ld		(hl), a
        ret

; Проверка препятствия
; На входе: DE - координаты тайла D - Y, E - X
; На выходе: Z=1 - препятствие, Z=0 - нет препятствия
barrier_check:
		ld		hl, map
		call	coord_to_map_calc_de
		ld		e, (hl)
		ld		d, 0
		ld		hl, tiles_prop
		add		hl, de
		ld		a, (hl)
		and		0b11100000
		cp		0b00100000		; Код препятствия
		ret

; По координатам персонажа из DE вычисляем координаты левого верхнего тайла под ним
; Координаты персонажа берутся из переменных x_coord и y_coord
; На входе HL - адрес карты (оригинал иди копия)
; На входе DE - координаты E - X, D - Y
; На выходе HL - адрес в карте
; DE - сдвиг
coord_to_map_calc_de:
		push	hl
		ld		a, e	; 0...47
		or		a				; Сбрасываем флаг С
		rra						; Делим на 2 получаем левую координату тайла
		ld		e, a

		ld		a, d	; 0...255
		jp		coord_to_map_calc_01

; По координатам персонажа из переменных x_coord и y_coord вычисляем координаты левого верхнего тайла под ним
; Координаты персонажа берутся из переменных x_coord и y_coord
; На входе HL - адрес карты (оригинал иди копия)
; На выходе HL - адрес в карте
; DE - сдвиг
coord_to_map_calc:
		push	hl
		ld		a, (x_coord)	; 0...47
		or		a				; Сбрасываем флаг С
		rra						; Делим на 2 получаем левую координату тайла
		ld		e, a

		ld		a, (y_coord)	; 0...255
coord_to_map_calc_01:
		rra						; Делим на 16 получаем верхнюю координату тайла
		rra
		rra
		rra
		and		0b00001111		; Убираем возможные лишние единицы после rra, если флаг С был установлен
		ld		d, a

; По координатам ищем сдвиг в карте: y * 24 + x
; На выходе D - Y, E - X
		ld		h, 0
		ld		l, d        ; HL = y (D)
		ld		d, h	    ; DE = x (E)

		add		hl, hl      ; y * 2
		add		hl, hl      ; y * 4
		add		hl, hl      ; y * 8
		ld		b, h
		ld		c, l
		add		hl, hl      ; y * 16
		add		hl, bc      ; y * 24
		add		hl, de      ; + x

		ex		hl, de
		pop		hl
		add		hl, de		; В HL - адрес в основной карте
		ret

; Печать буфера 32*32 (2*2 тайла) по координатам на экран из переменных x_coord и y_coord
print_buf_xy:
		; По координатам вычисляем адрес на экране
        ld		a, (x_coord)
		and		0b11111110
		ld		d, a

		ld		a, (y_coord)	; 0...255
		and		0b11110000
		ld		e, a

		ld		hl, 0x9000
		add		hl, de
		ex		hl, de

		ld 		hl, buffer

		; Непосредственно печать буфера
		ld		b, 4			; Ширина буфера в байтах
print_buf_2:
		ld		c, 32			; Высота буфера в пикселях
		push	de
print_buf_1:
		ld		a, (hl)			; Буфер
		ld		(de), a			; Экран
		inc		e
		inc		hl
		dec		c
		jp		nz, print_buf_1
		pop		de
		inc		d
		dec		b
		jp		nz, print_buf_2

		ret

; Выбираем фазу анимации
; На выходе в A текущий кадр анимации (0..2):
anim_sprite:
		ld		a, (x_coord)
		ld		b, a
		ld		a, (x_coord_prev)
		cp		b
		jp		nz, anim_sprite_2
		ld		a, (y_coord)
		ld		b, a
		ld		a, (y_coord_prev)
		cp		b
		jp		nz, anim_sprite_2
		ld		a, (current_anim)
		ret

anim_sprite_2:
		ld		a, (x_coord)
		ld		(x_coord_prev), a
		ld		a, (y_coord)
		ld		(y_coord_prev), a

		ld		a, (current_anim)
		inc		a
		cp		3		; Три фазы анимации движения
		jp		nz, anim_sprite_1
		xor		a
anim_sprite_1:
		ld		(current_anim), a
		ret

; Восстанавливаем фон
; Берём последние координаты героя и вычисляем какие тайлы на карте он перекрывает
; Главный герой при перемещении на 8, всегда занимает только 2 тайла по горизонтали и 2 по вертикали
; При попиксельном перемещении может покрывать 3 тайла
restore_background:
		; Теперь нужно скопировать из оригинальной карты в её копию значение тайла с координатами в DE
		ld		hl, map
		call	coord_to_map_calc

		; Копируем из оригинальной карты в копию квадрат 2*2 со сдвигом от начала карты в DE
		; На будущее НЕОБХОДИМО УЧЕСТЬ ПЕРЕХОД ЗА ПРАВЫЙ КРАЙ И НИЗ (добавить ещё одну лишнюю строку внизу?)

		push	hl
		ld		a, (hl)
		inc		hl
		ld		b, (hl)

		ld		hl, map_copy
		add		hl, de
		push	hl
		ld		(hl), a
		inc		hl
		ld		(hl), b

		pop		de

		pop		hl
		ld		bc, 24		; Количество тайлов в одной строке (384 / 16)
		add		hl, bc
		ld		a, (hl)
		inc		hl
		ld		b, (hl)

		ex		hl, de
		ld		de, 24		; Количество тайлов в одной строке (384 / 16)
		add		hl, de
		ld		(hl), a
		inc		hl
		ld		(hl), b

		ret

; Изменение координат спрайта
change_coords:
		call	keyboard
		jp		z, get_coords

		ld		(pressed_keys), a

		; Нажатие "Вправо"
		and		0b100
		jp		z, key_1
		ld		a, (x_coord)
		cp		45				; (384 - 24) / 8
		jp		nc, key_1
		inc		a
		ld		(x_coord), a
		;------------------------------------------------
		; Проверяем наличие препятствия справа от спрайта
		; Проверяем верхнюю половину спрайта на совпадение с препятствием
		add		2				; Добавляем к координате X ширину спрайта минус 1
		ld		e, a
		ld		a, (y_coord)
		ld		d, 	a
		call	barrier_check
		jp		z, key_right_01	; Возвращаем координату, если препятствие
		; Поверяем всё то же самое на нижней половине спрайта
		ld		a, (x_coord)
		add		2				; Добавляем к координате X ширину спрайта минус 1
		ld		e, a
		ld		a, (y_coord)
		add		16				; Добавляем к координате Y высоту спрайта минус 8
		ld		d, a
		call	barrier_check
		jp		nz, key_1		; Переходим дальше, если не препятствие
key_right_01:
		ld		a, (x_coord)
		dec		a
		ld		(x_coord), a
key_1:

		; Нажатие "Влево"
		ld		a, (pressed_keys)
		and		0b10000
		jp		z, key_2
		ld		a, (x_coord)
		or		a
		jp		z, key_2
		dec		a
		ld		(x_coord), a
		;------------------------------------------------
		; Проверяем наличие препятствия справа от спрайта
		ld		e, a
		ld		a, (y_coord)
		ld		d, 	a
		call	barrier_check
		jp		z, key_left_01	; Возвращаем координату обратно, если препятствие
		ld		a, (x_coord)
		ld		e, a
		ld		a, (y_coord)
		add		16				; Добавляем к координате Y высоту спрайта минус 8
		ld		d, a
		call	barrier_check
		jp		nz, key_2		; Переходим дальше, если не препятствие
key_left_01:
		ld		a, (x_coord)
		inc		a
		ld		(x_coord), a		
key_2:

		; Нажатие "Вверх"
		ld		a, (pressed_keys)
		and		0b10
		jp		z, key_3
		ld		a, (y_coord)
		or		a
		jp		z, key_3
		; dec		a
		sub		8
		ld		(y_coord), a
		;------------------------------------------------
		; Проверяем наличие препятствия над спрайтом
		ld		d, a
		ld		a, (x_coord)
		ld		e, a
		call	barrier_check
		jp		z, key_up_01	; Возвращаем координату, если препятствие
		ld		a, (y_coord)
		ld		d, a
		ld		a, (x_coord)
		add		2				; Добавляем к координате X ширину спрайта минус 1
		ld		e, a
		call	barrier_check
		jp		nz, key_3
key_up_01:
		ld		a, (y_coord)
		add		8
		ld		(y_coord), a
key_3:

		; Нажатие "Вниз"
		ld		a, (pressed_keys)
		and		0b1
		jp		z, key_4
		ld		a, (y_coord)
		cp		256 - 24
		jp		nc, key_4
		; inc		a
		add		8
		ld		(y_coord), a
		;-------------------------------------------
		; Проверяем наличие препятствия под спрайтом
		add		16				; Добавляем к координате Y высоту спрайта минус 8
		ld		d, a
		ld		a, (x_coord)
		ld		e, a
		call	barrier_check
		jp		z, key_down_01	; Возвращаем координату, если препятствие
		ld		a, (y_coord)
		add		16				; Добавляем к координате Y высоту спрайта минус 8
		ld		d, a
		ld		a, (x_coord)
		add		2				; Добавляем к координате X ширину спрайта минус 1
		ld		e, a
		call	barrier_check
		jp		nz, key_4
key_down_01:
		ld		a, (y_coord)
		sub		8
		ld		(y_coord), a
key_4:

; Загружаем в DE координаты из переменных x_coord и y_coord
get_coords:
		ld		a, (x_coord)
		ld		d, a
		ld		a, (y_coord)
		ld		e, a
        ret

; Опрос клавиатуры на предмет нажатия курсорных клавиш и пробела
; Результат в регистре А
; A = 0 - не было нажатия
; Z = 1 - не было нажатия
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
		ld		(hl), a
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

; Вычисляем текущий кадр анимации тайла исходя из его свойств
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

; Основная тайловая карты игры
map:
        include "map.asm"

; Набор тайлов 16*16 пикселей без маски
tiles:
        incbin  "sprites_2x2_nomask.bin"

; Набор спрайтов 24*24 пикселей с маской
sprites:
        incbin  "sprites_3x3_mask.bin"

finish:
        savebin "game.bin", start, finish-start

; Всё следующие данные на сохраняется в бинарнике, они генерируется в процессе работы программы

; Текущая копия игровой карты
map_copy:
        defs    384, 0xff

; Текущий "кадр" игры
frame_counter
        db      0       ; 0...255

; Координаты персонажа на экране
x_coord:
		db		0       ; 0...47
y_coord:
		db		0       ; 0...255

; Предыдущие координаты персонажа на экране
x_coord_prev:
        db      0       ; 0...47
y_coord_prev:
        db      0       ; 0...255

; Номер текущего кадра анимации персонажа
current_anim:
        db      0

; Карта тайлов буфера
map_copy_buf:
		db		0, 0, 0, 0

; Буфер части экрана 2*2 тайла (32*32 пикселя)
buffer:
		defs	32 / 8 * 32

; Нажатые клавиши		
pressed_keys:
		db		0
