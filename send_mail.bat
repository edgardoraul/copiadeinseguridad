echo off
:: Recibir parámetros del script caller
set HOST=%1
set SHARE=%2
set TIPO_BACKUP=%3
set TAMANIO_FORMATO=%4
set ZIP=%5
set HORA_INICIO=%6
set HORA_FIN=%7

:: Crear archivo temporal con contenido del email
set TEMP_EMAIL=%TEMP%\backup_email_%RANDOM%.txt


:: Escribir resumen en el archivo temporal
(
	echo === RESUMEN DE BACKUP ===
	echo.
	echo Host:		%HOST%
	echo Recurso:	%SHARE%
	echo Tipo:		%TIPO_BACKUP%
	echo Peso:		%TAMANIO_FORMATO%
	echo Estado:	EXITOSO
	echo Inicio:	%HORA_INICIO%
	echo Fin:		%HORA_FIN%
	echo.
	echo Archivo:	%ZIP%
) > "%TEMP_EMAIL%"

::set TEMP_EMAIL=%LOG%

:: Enviar email con SwithMail
"SwithMail.exe" /s /from "%MAIL_FROM%" /name "Sistema Backup Rerda" /server "%SMTP_SERVER%" /p "%SMTP_PORT%" /SSL /u "%MAIL_USER%" /pass "%MAIL_PASS%" /to "%MAIL_TO%" /sub "Backup %HOST% - %SHARE% - %TIPO_BACKUP%" /bodytxt "%TEMP_EMAIL%" /Log /enc "utf-8"

if errorlevel 1 (
	echo [%DATE% %TIME%] ERROR: No se pudo enviar email
	del "%TEMP_EMAIL%"
	exit /b 1
) else (
	echo [%DATE% %TIME%] Email enviado correctamente
	del "%TEMP_EMAIL%"
	exit /b 0
)