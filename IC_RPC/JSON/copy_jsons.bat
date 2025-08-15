@echo off
setlocal EnableExtensions
chcp 65001 >nul

set "SRC=C:\Users\brandon_wu\Documents\PDK_IDE\250814_version\Writer_IC_RPC\tool\Runner"
set "DST=C:\Users\brandon_wu\Documents\PDK_IDE\common_backup\Writer_IC_RPC\Reg"

goto :after_notes
@REM ====== 複製所有子資料夾內的 .json，保留相對路徑 ======
@REM /S      複製子資料夾(不含空資料夾)
@REM /R:1    重試 1 次
@REM /W:1    每次重試等待 1 秒
@REM /NFL    不列出檔案
@REM /NDL    不列出目錄
@REM /NP     不顯示進度
@REM 加上'/L'做模擬執行
:after_notes
robocopy "%SRC%" "%DST%" *.json /S /R:1 /W:1 /NFL /NDL /NP
set "RC=%ERRORLEVEL%"

@REM Robocopy 回傳碼 0~7 視為成功
if %RC% lss 8 (
  echo ✅ JSON 複製完成（exit code %RC%）。
  exit /b 0
) else (
  echo ❌ 複製失敗（exit code %RC%）。
  exit /b %RC%
)
