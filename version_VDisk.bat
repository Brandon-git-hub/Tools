@echo off
setlocal EnableExtensions

rem 1) 設定根目錄
set "BASE=C:\Users\brandon_wu\Documents\PDK_IDE"

if not exist "%BASE%" (
  echo [FAIL] Base not found: "%BASE%"
  exit /b 2
)

rem 2) 在 BASE 底下尋找符合 6 碼日期 + "_version" 的資料夾，取字串排序最後一個
set "LATEST="
for /f "delims=" %%F in ('
  dir "%BASE%" /ad /b ^| findstr /r "^[0-9][0-9][0-9][0-9][0-9][0-9]_version$" ^| sort
') do set "LATEST=%%F"

if not defined LATEST (
  echo [FAIL] No yyMMdd_version folder found under: "%BASE%"
  exit /b 3
)

echo [INFO] Latest snapshot: %LATEST%

rem 3) 進入該目錄
pushd "%BASE%\%LATEST%" || (
  echo [FAIL] Cannot cd into "%BASE%\%LATEST%"
  exit /b 4
)

rem 4) 解除舊的 O: 對應（若沒有就忽略錯誤）
subst O: /D >nul 2>&1

rem 5) 輸出實體路徑到 __VDisk.txt
> "__VDisk.txt" echo %cd%

rem 6) 把 O: 指到目前目錄
subst O: "%cd%"
if errorlevel 1 (
  echo [FAIL] subst failed. Is drive O: already in use?
  popd & exit /b 5
) else (
  echo [OK]   O: -> %cd%
)

popd
exit /b 0
