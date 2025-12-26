@echo off
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
set BASE=%DISCO%\%HOST%
set TMP=%BASE%\%SHARE%
set LOG=%BASE%\%HOST%.log

:: Controla si existe la carpeta base
if not exist "%BASE%" mkdir "%BASE%"

:: PASO 2: Detectar si es primer backup o diferencial
set TIPO_BACKUP=FULL
if exist "%BASE%\last_full_backup.txt" (
  for /f "tokens=1,2 delims= " %%L in (%BASE%\last_full_backup.txt) do (
    set ULTIMA_FECHA=%%L
    set ULTIMA_HORA=%%M
  )
  set TIPO_BACKUP=DIFERENCIAL
  echo [%DATE% %TIME%] Backup diferencial - Ultima fecha/hora: %ULTIMA_FECHA% %ULTIMA_HORA%>>"%LOG%"
  echo.
  echo === BACKUP DIFERENCIAL ===
  echo Ultimos cambios desde: %ULTIMA_FECHA% %ULTIMA_HORA%
  echo.
) else (
  echo [%DATE% %TIME%] Primer backup - COMPLETO>>"%LOG%"
  echo.
  echo === BACKUP COMPLETO (FULL) ===
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
  echo [%DATE% %TIME%] Copiando solo archivos mas nuevos que: %ULTIMA_FECHA% %ULTIMA_HORA%>>"%LOG%"
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

echo [%DATE% %TIME%] BACKUP OK - TIPO: %TIPO_BACKUP% - %SHARE% -> %ZIP%>>"%LOG%"

echo.
echo ============================================
echo BACKUP COMPLETADO - TIPO: %TIPO_BACKUP%
echo Recurso: %SHARE%
echo Archivo: %ZIP%
echo ============================================
echo.

:: Guardar fecha y hora de este backup para futuras diferenciales
echo %FECHA_COMPLETA% > "%BASE%\last_full_backup.txt"

exit /b