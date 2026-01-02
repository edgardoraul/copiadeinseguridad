@echo off
cd /d %~dp0
chcp 850 >nul
setlocal EnableDelayedExpansion

:: Contador para incrementar
set CONTADOR=0

:: Utilidad de compresión (tar nativo de Windows 10+)
set TAR=bsdtar.exe

:: Robocopy con progreso visible
set OPCIONES=/E /Z /R:2 /W:2 /XJ /COPY:DAT /XF "NTUSER*" "desktop.ini" /XD "AppData"

:: Email envío con.... ¿qué carajos te importa, pelotudo?
call ../datos.bat

for /f "tokens=1,2,3 delims=|" %%A in (hosts.txt) do (

  call backup_host.bat "%%A" "%%B" "%%C"

)