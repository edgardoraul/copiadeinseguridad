@REM @echo off
@REM set HOST=%~1
@REM set LOG=%~2
@REM set MAILLOG=%~3

@REM "%BLAT%" "%LOG%" ^
@REM  -to "%MAIL_TO%" ^
@REM  -f "%MAIL_FROM%" ^
@REM  -server "%SMTP_SERVER%" ^
@REM  -port %SMTP_PORT% ^
@REM  -subject "Backup %HOST% - %DATE%" >> "%MAILLOG%" 2>&1

@REM if errorlevel 1 (
@REM     echo [%DATE% %TIME%] ERROR: No se pudo enviar email >> "%LOG%"
@REM ) else (
@REM     echo [%DATE% %TIME%] Email enviado correctamente >> "%LOG%"
@REM )

@REM exit /b 0

echo Prueba directa | D:\Archivos de Programa\copiadeinseguridad\blat.exe ^
-to "edgardorerdamza@hotmail.com" ^
-server "mail.rerda.com" ^
-port 465 ^
-u "admin@rerda.com" ^
-p "Mprerda2026." ^
-f "admin@rerda.com" ^
-subject "Prueba BLAT SSL" ^
-ssl
echo "Chau·"