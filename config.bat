@echo off
chcp 65001 >nul

:: Utilidad de compresión (tar nativo de Windows 10+)
set TAR=bsdtar.exe

:: Robocopy con progreso visible
set OPCIONES=/E /Z /R:2 /W:2 /XJ /COPY:DAT /XF "NTUSER*" "desktop.ini" /XD "AppData"

:: Email (BLAT con SSL/TLS en puerto 465)
set BLAT=blat.exe
call ..\datos.bat