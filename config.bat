@echo off

:: Utilidad de compresión (tar nativo de Windows 10+)
set TAR=bsdtar.exe

:: Robocopy con progreso visible
set OPCIONES=/E /Z /R:2 /W:2 /XJ /COPY:DAT /XF "NTUSER*" "desktop.ini" /XD "AppData"

:: Email (BLAT)
set BLAT=blat.exe
set SMTP_SERVER=mail.rerda.com
set SMTP_PORT=465
set MAIL_FROM=admin@rerda.com
set MAIL_TO=edgardorerdamza@hotmail.com
set MAIL_USER=admin@rerda.com
set MAIL_PASS="Mprerda2026."