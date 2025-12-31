@echo off
chcp 65001 >nul

set "SMTP_SERVER=mail.rerda.com"
set "SMTP_PORT=587"
set "MAIL_FROM=admin@rerda.com"
set "MAIL_TO=edgardorerdamza@hotmail.com"
set "MAIL_USER=admin@rerda.com"
set "MAIL_PASS=Mprerda2026."

:: --- CREAR INFORME ---
set "TEMP_EMAIL=%TEMP%\informe.txt"

:: Escribimos el archivo (ahora se guardará como Windows-1252)
echo === INFORME DE PRUEBA === > "%TEMP_EMAIL%"
echo Detalle: Backup ejecutado con éxito. >> "%TEMP_EMAIL%"
echo Ubicación: Operación terminada. >> "%TEMP_EMAIL%"

:: --- ENVÍO ---
:: Cambiamos /encoding "utf-8" por /encoding "windows-1252"
"SwithMail.exe" /s /from "%MAIL_FROM%" /pass "%MAIL_PASS%" /server "%SMTP_SERVER%" /p "%SMTP_PORT%" /SSL /u "%MAIL_USER%" /to "%MAIL_TO%" /sub "Prueba Western" /bodytxt "%TEMP_EMAIL%" /encoding "windows-1252"

if %errorlevel% EQU 0 (echo Enviado OK) else (echo Error: %errorlevel%)

del "%TEMP_EMAIL%"