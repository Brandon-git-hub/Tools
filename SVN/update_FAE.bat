@echo off
setlocal
REM === ps1 位置 ===
set "PS1=C:\Users\brandon_wu\Desktop\Tools\WindowsPowerShell\update_svn_folder.ps1"

REM === 在這裡加/減路徑；每行一個 call :ADD "路徑" ===
call :ADD "C:\FAE"
REM call :ADD "D:\more\paths\here"

REM === 交給 PS1（%ARGS% 會展開成多個參數） ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"  %ARGS%
if exist %ARGS% start "" explorer.exe %ARGS%
exit /b %ERRORLEVEL%

:ADD
set "ARGS=%ARGS% "%~1""
exit /b
