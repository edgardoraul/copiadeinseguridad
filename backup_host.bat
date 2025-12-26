@echo off
chcp 65001 >nul
:: Host a copiar
set HOST=%1

:: Su carpeta o recurso compartido
set SHARE=%2

:: Disco donde se guardará la copia
set DISCO=%~3

:: Fecha actual, disco base, carpeta temporal y log
set FECHA=%DATE:~6,4%-%DATE:~3,2%-%DATE:~0,2%
set FECHA_ROBOCOPY=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%
set HORA=%TIME:~0,2%:%TIME:~3,2%
set FECHA_COMPLETA=%FECHA% %HORA%
set HORA_INICIO=%TIME%
set BASE=%DISCO%\%HOST%
set TMP=%BASE%\%SHARE%
set LOG=%BASE%\%HOST%.log

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
call check_host.bat %HOST%
if errorlevel 1 (
  echo [%DATE% %TIME%] HOST APAGADO>>"%LOG%"
  exit /b
)

:: Controla si el recurso compartido está disponible
if not exist "\\%HOST%\%SHARE%" (
  echo [%DATE% %TIME%] SHARE NO DISPONIBLE \\%HOST%\%SHARE%>>"%LOG%"
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

robocopy "\\%HOST%\%SHARE%" "%TMP%" %OPCIONES_DIFF% /LOG+:"%LOG%"
set RC=%ERRORLEVEL%


if %RC% GEQ 8 (
  echo [%DATE% %TIME%] ERROR ROBOCOPY RC=%RC%>>"%LOG%"
  rmdir /s /q "%TMP%"
  exit /b
)

:: Calcular versión
set V=1
for %%F in ("%BASE%\%FECHA%_v*_%HOST%_%SHARE%.zip") do set /a V+=1

set ZIP=%BASE%\%FECHA%_v%V%_%HOST%_%SHARE%.zip

:: Compresión zip con BSDtar
%TAR% -a -c -f "%ZIP%" "%TMP%\*" >>"%LOG%"

rmdir /s /q "%TMP%"

:: ESTADÍSTICAS: Capturar hora de fin
set HORA_FIN=%TIME%

:: Obtener tamaño del ZIP
for %%F in ("%ZIP%") do set TAMANIO_ZIP=%%~zF
if %TAMANIO_ZIP% GEQ 1048576 (
  set /a TAMANIO_MB=%TAMANIO_ZIP% / 1048576
  set TAMANIO_FORMATO=%TAMANIO_MB% MB
) else if %TAMANIO_ZIP% GEQ 1024 (
  set /a TAMANIO_KB=%TAMANIO_ZIP% / 1024
  set TAMANIO_FORMATO=%TAMANIO_KB% KB
) else (
  set TAMANIO_FORMATO=%TAMANIO_ZIP% bytes
)

:: Guardar estadísticas en LOG
echo.>>"%LOG%"
echo === ESTADÍSTICAS DE BACKUP ===>>"%LOG%"
echo Hora inicio: %HORA_INICIO%>>"%LOG%"
echo Hora fin: %HORA_FIN%>>"%LOG%"
echo Tipo: %TIPO_BACKUP%>>"%LOG%"
echo Tamaño ZIP: %TAMANIO_FORMATO%>>"%LOG%"
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
echo [TAMAÑO]    %TAMANIO_FORMATO%
echo [INICIO]    %HORA_INICIO%
echo [FIN]       %HORA_FIN%
echo.
echo [ARCHIVO]   %ZIP%
echo.
echo ┌────────────────────────────────────────────────┐
echo │ %ZIP%
echo └────────────────────────────────────────────────┘
echo.
echo [LOG] %LOG%
echo.

:: Guardar fecha y hora de este backup para futuras diferenciales (archivo único por SHARE)
echo %FECHA_COMPLETA% > "%LASTBACKUP_FILE%"

call send_mail.bat "%HOST%" "%SHARE%" "%TIPO_BACKUP%" "%TAMANIO_FORMATO%" "%ZIP%" "%HORA_INICIO%" "%HORA_FIN%"

exit /b