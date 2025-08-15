@echo off
setlocal EnableExtensions

rem --- 0) derive current folder and parents ---
for %%I in ("%CD%") do set "CURNAME=%%~nxI"
for %%I in ("%CD%\..")  do set "PARENTNAME=%%~nxI"
for %%I in ("%CD%\..\..") do set "GRANDNAME=%%~nxI"

if /I not "%PARENTNAME%"=="Reg" (
  echo [FAIL] Run this script inside ...\Writer_IC_RPC\Reg\{subfolder}
  echo [INFO] Current path: %CD%
  exit /b 10
)
if /I not "%GRANDNAME%"=="Writer_IC_RPC" (
  echo [FAIL] Run this script inside ...\Writer_IC_RPC\Reg\{subfolder}
  echo [INFO] Current path: %CD%
  exit /b 11
)

rem --- 1) base path ---
set "BASE=C:\Users\brandon_wu\Documents\PDK_IDE"
if not exist "%BASE%" (
  echo [FAIL] Base not found: "%BASE%"
  exit /b 2
)

rem --- 2) pick latest yyMMdd_version under BASE ---
set "LATEST="
for /f "delims=" %%F in ('
  dir "%BASE%" /ad /b ^| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9]_version$" ^| sort
') do set "LATEST=%%F"

if not defined LATEST (
  echo [FAIL] No yyMMdd_version folder found under: "%BASE%"
  exit /b 3
)

rem --- 3) destination: ...\Writer_IC_RPC\tool\Runner\{CURNAME} ---
set "DST=%BASE%\%LATEST%\Writer_IC_RPC\tool\Runner\%CURNAME%"
if not exist "%DST%" mkdir "%DST%" 2>nul

echo [INFO] Current subfolder : %CURNAME%
echo [INFO] Latest snapshot   : %LATEST%
echo [INFO] Dest              : %DST%

rem --- 4) copy .json from current folder only (no subdirs) ---
robocopy "%CD%" "%DST%" *.json /R:1 /W:1 /NFL /NDL /NP
set "RC=%ERRORLEVEL%"

if %RC% lss 8 (
  echo [OK] Copy finished. robocopy exit code: %RC%
  if exist "%DST%" start "" explorer.exe "%DST%"
  pause
  @REM   exit /b 0
) else (
  echo [FAIL] robocopy failed with exit code: %RC%
  pause
  @REM exit /b %RC%
)
