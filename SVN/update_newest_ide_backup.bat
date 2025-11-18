@echo off
setlocal
REM === ps1 位置 ===
set "PS1=C:\Users\brandon_wu\Desktop\Tools\WindowsPowerShell\update_svn_folder.ps1"

REM === 在這裡加/減路徑；每行一個 call :ADD "路徑" ===
call :ADD "C:\Users\brandon_wu\Documents\PDK_IDE\Newest_IDE_backup\PADAUK_IDE"
call :ADD "C:\Users\brandon_wu\Documents\PDK_IDE\Newest_IDE_backup\Writer_All"
call :ADD "C:\Users\brandon_wu\Documents\PDK_IDE\Newest_IDE_backup\Writer_IC_RPC"
REM call :ADD "D:\more\paths\here"

REM === 交給 PS1（%ARGS% 會展開成多個參數） ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"  %ARGS%
exit /b %ERRORLEVEL%

:ADD
set "ARGS=%ARGS% "%~1""
exit /b
