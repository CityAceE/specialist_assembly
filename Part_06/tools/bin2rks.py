import sys


def hex_number(number):
    sting_number = str(hex(number)).lstrip('0x').upper()
    while len(sting_number) < 4:
        sting_number = '0' + sting_number
    return sting_number


if len(sys.argv) > 1:
    filename = sys.argv[1]
    if len(sys.argv) > 2:
        start = int(sys.argv[2])
    else:
        start = 0

    with open(filename, 'rb') as f_obj:
        binary_file = f_obj.read()

    finish = len(binary_file) - 1

    cs = 0
    for i in range(finish):
        cs += binary_file[i]
        cs += (binary_file[i] << 8)

    cs = (cs & 0xff00) | ((cs + binary_file[finish]) & 0xff)

    binary_file = bytearray(binary_file)

    header = [start % 256, start // 256, (start + finish) % 256, (start + finish) // 256]
    header = bytearray(header)

    check_sum = [cs % 256, cs // 256]
    check_sum = bytearray(check_sum)

    rks_file = header + binary_file + check_sum

    if '.' in filename:
        name_parts = filename.split('.')
        name_parts[-1] = 'rks'
        filename = '.'.join(name_parts)
    else:
        filename = filename + '.rks'

    print("ИМЯ ФАЙЛА:", filename)
    print("КОНТРОЛЬНАЯ СУММА =" + hex_number(cs))
    print("НАЧАЛЬНЫЙ АДРЕС =" + hex_number(start))
    print("КОНЕЧНЫЙ  АДРЕС =" + hex_number(start + finish))

    with open(filename, 'wb') as f_obj:
        f_obj.write(rks_file)

else:
    print("Usage: python bin2rks.py filename.bin [start_address]")
