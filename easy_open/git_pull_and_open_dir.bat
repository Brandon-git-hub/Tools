@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\brandon_wu\Desktop\Tools\WindowsPowerShell\update_and_open.ps1"
timeout /t 2 /nobreak > nul
exit /b 0
