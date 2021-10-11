Эмулятор DOS

Виртуальный ПК: (CPU P5, FPU, 6 Mb ОЗУ, ISA, НГМД, НЖМД)

Основано на проекте MOZAA DOS EMULATOR (based on Bochs for Win32)

Эмулятор ДОС-системы на базе минимального ПК.

Свободно распространяемый, рекомендуется для применения в средних школах, 
колледжах РФ и СНГ.

Состав виртуального диска:

FreeDOS, VC, NCSI, Pacman, Digger, PKZip, PkUnzip, Format, Fdisk, Sys, 
Scandisk

Для отмены измений на гибком диске (к примеру форматирования в виртуальной 
системе воспользуйтесь функцией отмены изменений в меню программы)

Настройка (emu.ini):

[Hardware]
BX_C_PRESENT=1 (Есть ли НЖМД, 1 или 0)
HDD_NUM_CYL=1224 (Число цилиндров НЖМД)
HDD_SECTOR_PER_TRACK=17 (Число секторов НЖМД)
HDD_NUM_HEADS=15 (Число головок НЖМД)
HDD_FILE_DISK=C:\mozaa_hdd_file.img (Путь к снимку НЖМД, файл создается 
автоматически)
MEMORYMB=7 (Размер оперативной памяти ОЗУ)
CPU_SPEED=700000 (Скорость эмуляции, экспериментируйте для получения 
оптимального результата)

Размер НЖМД вычисляется по формуле HDD_NUM_CYL* HDD_NUM_HEADS* HDD_SECTOR_PER_TRACK*512

Тов. Александр Владимирович Дарк

http://www.darksoftware.narod.ru
e-mail: www.darksoftware@yandex.ru