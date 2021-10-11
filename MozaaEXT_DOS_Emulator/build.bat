@echo off
echo Deleting old build...
del *.exe
del *.dcu
del *.~*
del *.bak
del *.ddp
echo Compiling...
dcc32 mozaa.dpr -CG -Q -B+ -$B- -$D- -$A8+ -$Q- -$R- -$L- -$M- -$O+ -$W- -$Y- -$Z1- -$J- -$C- -$U- -$I-
echo Deleting new dcu....
del *.dcu
del *.ddp
echo Packing...
call upk mozaa.exe 
echo Creating archive...
del mozaa.rar
d:\progra~1\winrar\rar.exe a -cl -m5 -s mozaa.rar mozaa.exe readme.txt