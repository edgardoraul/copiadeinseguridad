@echo off
ping -n 1 -w 1000 %1 >nul
if errorlevel 1 exit /b 1
exit /b 0
