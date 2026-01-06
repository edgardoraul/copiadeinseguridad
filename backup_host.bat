echo off

set "HOST=%~1"
set "SHARE=%~2"
set "DISCO=%~3"
set "NombreZip=%~4"
set "FECHA_HOY=%DATE:~6,4%-%DATE:~3,2%-%DATE:~0,2%"

:: Fecha actual, disco base, carpeta temporal y log
set FECHA=%DATE:~6,4%-%DATE:~3,2%-%DATE:~0,2%
set FECHA_ROBOCOPY=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%
set HORA=%TIME:~0,2%:%TIME:~3,2%
set FECHA_COMPLETA=%FECHA% %HORA%
set HORA_INICIO=%TIME%
set BASE=%DISCO%\Backup\%HOST%
set "TMP=%BASE%\%SHARE%"
set "LOG=%BASE%\%HOST%.log"

:: Controla si existe la carpeta base
if not exist "%BASE%" mkdir "%BASE%"

:: Crear nombre único para archivo de control (uno por cada SHARE)
set SHARE_SAFE=%SHARE:\=_%
set LASTBACKUP_FILE=%BASE%\.last_full_backup_%SHARE_SAFE%.txt

:: PASO 2: Detectar si es primer backup o diferencial
set TIPO_BACKUP=FULL
if exist "%LASTBACKUP_FILE%" (
	for /f "tokens=1,2 delims= " %%L in (%LASTBACKUP_FILE%) do (
		set ULTIMA_FECHA=%%L
		set ULTIMA_HORA=%%M

		:: Controla si ya se hizo un backup hoy
		if "%ULTIMA_FECHA%"=="%FECHA_HOY%" (
			echo [%DATE% %TIME%] Ya se realizó un backup FULL hoy. No se permiten múltiples backups FULL en el mismo día.>>"%LOG%"
			echo [%DATE% %TIME%] Hoy ya se realizó un backup de: %HOST% - %SHARE%
			exit /b
		)
	)
	set TIPO_BACKUP=DIFERENCIAL
	echo [%DATE% %TIME%] Backup diferencial - Última fecha/hora: %ULTIMA_FECHA% %ULTIMA_HORA%>>"%LOG%"
	echo.
	echo === BACKUP DIFERENCIAL ===
	echo Últimos cambios desde: %ULTIMA_FECHA% %ULTIMA_HORA%
	echo.
) else (
	echo [%DATE% %TIME%] Primer backup - COMPLETO>>"%LOG%"
	echo.
	echo === BACKUP COMPLETO FULL ===
	echo.
)

:: Controla si el host está encendido
ping -n 1 -w 1000 %1 >nul
if errorlevel 1 (
	echo [%DATE% %TIME%] HOST APAGADO>>"%LOG%"
	exit /b
)

:: Controla si el recurso compartido está disponible
if not exist "\\%HOST%\%SHARE%" (
	echo [%DATE% %TIME%] RECURSO COMPARTIDO NO DISPONIBLE \\%HOST%\%SHARE%>>"%LOG%"
	exit /b
)

:: Copia temporal CON PROGRESO EN TIEMPO REAL
mkdir "%TMP%" >nul 2>&1

:: PASO 3: Si es diferencial, agregar /MAXAGE para copiar solo cambios
set OPCIONES_DIFF=%OPCIONES%
if "%TIPO_BACKUP%"=="DIFERENCIAL" (
	for /f "tokens=1 delims=-" %%A in ("%ULTIMA_FECHA%") do (
		for /f "tokens=2 delims=-" %%B in ("%ULTIMA_FECHA%") do (
			for /f "tokens=3 delims=-" %%C in ("%ULTIMA_FECHA%") do (
				set FECHA_ROBOCOPY=%%A%%B%%C
			)
		)
	)
	set OPCIONES_DIFF=%OPCIONES% /MAXAGE:%FECHA_ROBOCOPY%
	echo [%DATE% %TIME%] Copiando solo archivos más nuevos que: %ULTIMA_FECHA% %ULTIMA_HORA%>>"%LOG%"
)
echo Backupeando "\\%HOST%\%SHARE%" ...
robocopy "\\%HOST%\%SHARE%" "%TMP%" %OPCIONES_DIFF% /NFL /NDL /NP /LOG+:"%LOG%"
set RC=%ERRORLEVEL%


if %RC% GEQ 8 (
	echo [%DATE% %TIME%] ERROR ROBOCOPY RC=%RC%>>"%LOG%"
	rmdir /s /q "%TMP%"
	exit /b
)

:: Calcular versión
set V=1
for %%F in ("%BASE%\%FECHA%_v*_%HOST%_%SHARE%.zip") do set /a V+=1

set NombreZip=%FECHA%_v%V%_%HOST%_%SHARE%.zip
set ZIP=%BASE%\%FECHA%_v%V%_%HOST%_%SHARE%.zip

:: Compresión zip con BSDtar
%TAR% -a -c -f "%ZIP%" "%TMP%\*" >>"%LOG%"

rmdir /s /q "%TMP%"

:: ESTADÍSTICAS: Capturar hora de fin
set HORA_FIN=%TIME%

:: Obtener tamaño del ZIP
for %%F in ("%ZIP%") do set TAMANIO_ZIP=%%~zF

if not defined TAMANIO_ZIP (
		set TAMANIO_FORMATO=0 bytes
) else (
		if !TAMANIO_ZIP! GEQ 1048576 (
				set /a TAMANIO_MB=!TAMANIO_ZIP! / 1048576
				set TAMANIO_FORMATO=!TAMANIO_MB! MB
		) else (
				if !TAMANIO_ZIP! GEQ 1024 (
						set /a TAMANIO_KB=!TAMANIO_ZIP! / 1024
						set TAMANIO_FORMATO=!TAMANIO_KB! KB
				) else (
						set TAMANIO_FORMATO=!TAMANIO_ZIP! bytes
				)
		)
)

:: Cuenta caracteres
set "temp_str=%NombreZip%"
set contador=0
:loop
if defined temp_str (
	set "temp_str=%temp_str:~1%"
	set /a contador+=1
	goto loop
)



:: Guardar estadísticas en LOG
echo.>>"%LOG%"
echo === ESTADISTICAS DE BACKUP ===>>"%LOG%"
echo Hora inicio: %HORA_INICIO%>>"%LOG%"
echo Hora fin: %HORA_FIN%>>"%LOG%"
echo Tipo: %TIPO_BACKUP%>>"%LOG%"
echo Peso Archivo ZIP: %TAMANIO_FORMATO%>>"%LOG%"
echo Archivo: %ZIP%>>"%LOG%"
echo.>>"%LOG%"

echo [%DATE% %TIME%] BACKUP OK - TIPO: %TIPO_BACKUP% - TAMAÑO: %TAMANIO_FORMATO% - %SHARE% -> %ZIP%>>"%LOG%"

echo.
echo ╔════════════════════════════════════════════════╗
echo ║        BACKUP COMPLETADO EXITOSAMENTE          ║
echo ╚════════════════════════════════════════════════╝
echo.
echo [HOST]      %HOST%
echo [RECURSO]   %SHARE%
echo [TIPO]      %TIPO_BACKUP%
echo [PESO]    %TAMANIO_FORMATO%
echo [INICIO]    %HORA_INICIO%
echo [FIN]       %HORA_FIN%
echo [ARCHIVO]   %ZIP%
echo.
:: Dibujo de la caja corregido
set /p ".=┌─" < nul
for /l %%i in (1,1,%contador%) do <nul set /p ".=─"
echo ^─^┐
echo ^│ %NombreZip% ^│
set /p ".=└─" < nul
for /l %%i in (1,1,%contador%) do <nul set /p ".=─"
echo ^─^┘
echo.
echo [LOG] %LOG%
echo.

:: Guardar fecha y hora de este backup para futuras diferenciales (archivo único por SHARE)
echo %FECHA_COMPLETA% > "%LASTBACKUP_FILE%"

:: Enviar email de notificación
call send_mail.bat "%HOST%" "%SHARE%" "%TIPO_BACKUP%" "%TAMANIO_FORMATO%" "%ZIP%" "%HORA_INICIO%" "%HORA_FIN%"

:: Guardar resultado en la PC EDGAR
set "TAB=	"
set "RUTA=\\EDGAR\Escritorio\resumen_backups.csv"

:: Crea el encabezado si el archivo no existe
if not exist "%RUTA%" (
    echo HOST%TAB%ARCHIVO ZIP%TAB%TAMAÑO%TAB%TIPO BACKUP%TAB%ULTIMO BK FULL%TAB%HORA INICIO%TAB%HORA FIN> "%RUTA%"
)

:: Agrega la línea de datos
echo %HOST%%TAB%%NombreZip%%TAB%%TAMANIO_FORMATO%%TAB%%TIPO_BACKUP%%TAB%%FECHA_COMPLETA%%TAB%%HORA_INICIO%%TAB%%HORA_FIN%>> "%RUTA%"
exit /b