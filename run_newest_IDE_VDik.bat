@echo off
pushd "C:\Users\brandon_wu\Documents\PDK_IDE\Newest_IDE" || (
  echo [FAIL] Cannot cd into "Newest_IDE"
  exit /b 4
)
rem 解除舊的 O: 對應（若沒有就忽略錯誤）
subst O: /D >nul 2>&1

rem 輸出實體路徑到 __VDisk.txt
> "__VDisk.txt" echo %cd%

rem 把 O: 指到目前目錄
subst O: "%cd%"
if errorlevel 1 (
  echo [FAIL] subst failed. Is drive O: already in use?
  popd & exit /b 5
) else (
  echo [OK]   O: -> %cd%
)

popd
exit /b 0