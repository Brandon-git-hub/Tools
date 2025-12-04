@echo off
setlocal

REM  由 .bat 所在位置組出 .ps1 的絕對路徑（把 .. 正規化）===
set "REL_PS1=%~dp0..\..\WindowsPowerShell\open_vscode.ps1"
for %%I in ("%REL_PS1%") do set "PS1=%%~fI"

echo [DEBUG] BAT DIR   : "%~dp0"
echo [DEBUG] PS1 TARGET: "%PS1%"

if not exist "%PS1%" (
  echo [ERROR] .ps1 not found: "%PS1%"
  echo 提示：確認 open_in_code.ps1 是否真的在 ..\WindowsPowerShell\ 底下，
  echo 或者調整上面 REL_PS1 的相對路徑。
  pause
@REM   exit /b 1
)

REM 視窗模式：reuse 或 new
set MODE=new

REM 想開哪幾個資料夾就傳哪幾個（可 1 個或多個）
set P1=O:\PADAUK_IDE
@REM set P2=

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %MODE% "%P1%"
REM 若有多個路徑就繼續加： "%P2%" "%P3%" ...

timeout /t 5 /nobreak > nul
exit /b
