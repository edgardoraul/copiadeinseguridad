@echo off
call config.bat

for /f "tokens=1,2,3 delims=|" %%A in (hosts.txt) do (
  call backup_host.bat %%A %%B %%C
)
