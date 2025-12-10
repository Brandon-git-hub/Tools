@echo off
setlocal

REM  由 .bat 所在位置組出 .ps1 的絕對路徑（把 .. 正規化）===
set "REL_PS1=%~dp0.\CF.ps1"
for %%I in ("%REL_PS1%") do set "PS1=%%~fI"

echo [DEBUG] BAT DIR   : "%~dp0"
echo [DEBUG] PS1 TARGET: "%PS1%"

if not exist "%PS1%" (
    pause
)

REM 想開哪幾個資料夾就傳哪幾個（可 1 個或多個）
set P1=C:\Users\brandon_wu\Desktop\2423\After_CYC
@REM set P2=

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" "%P1%"
REM 若有多個路徑就繼續加： "%P2%" "%P3%" ...

timeout /t 5 /nobreak > nul
exit /b
