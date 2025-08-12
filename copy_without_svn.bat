@REM copy_without_svn.bat
@echo off
setlocal EnableExtensions

rem === paths ===  (PADAUK_IDE, Writer_All, Writer_IC_RPC)
set "SRC=C:\Users\brandon_wu\Documents\PDK_IDE\Newest_IDE\Writer_IC_RPC"
set "DST=C:\Users\brandon_wu\Documents\PDK_IDE\250808_version\Writer_IC_RPC"

rem === normalize & guards ===
for %%I in ("%SRC%") do set "SRC_FULL=%%~fI"
for %%I in ("%DST%") do set "DST_FULL=%%~fI" & set "DST_DRIVE=%%~dI"
if /I "%DST_FULL%"=="%SRC_FULL%"  (echo [FAIL] DST equals SRC & exit /b 20)
if /I "%DST_FULL%"=="%DST_DRIVE%\" (echo [FAIL] DST is drive root & exit /b 21)

echo [INFO] FROM: "%SRC_FULL%"
echo [INFO] TO  : "%DST_FULL%"
echo [INFO] EXCL: .svn
echo.

rem === HARD CLEAR TARGET (do not touch source) ===
if exist "%DST_FULL%" (
  echo [INFO] clearing target...
  rem  正常路徑屬性清除與刪除（重試）
  attrib -r -s -h "%DST_FULL%\*" /s /d >nul 2>&1
  for /l %%R in (1,1,5) do (
    rd /s /q "%DST_FULL%" >nul 2>&1
    if not exist "%DST_FULL%" break
    timeout /t 1 >nul
  )
)



rem === HARD CLEAR TARGET (do not touch source) ===
if exist "%DST_FULL%" (
  echo [WARN] "%DST_FULL%" is exist.
) else (
  mkdir "%DST_FULL%" || (echo [FAIL] cannot recreate target & exit /b 23)
)


rem === COPY (exclude .svn), quiet, long-path aware ===
setlocal EnableDelayedExpansion

set "LOG=%TEMP%\robocopy_%RANDOM%.log"
echo [INFO] Start Copy ...
robocopy "%SRC_FULL%" "%DST_FULL%" /E /XD .svn /R:3 /W:1 /XJ /NFL /NDL /NP /NJH /NJS > "%LOG%" 2>&1
set "RC=!ERRORLEVEL!"
echo [INFO] robocopy rc=!RC!
if !RC! GEQ 8 (
  echo [FAIL] robocopy exit=!RC!
  echo ----- robocopy output -----
  type "%LOG%"
  del "%LOG%" >nul 2>&1
  exit /b !RC!
)
del "%LOG%" >nul 2>&1
echo [OK]   robocopy exit=!RC! (0=NoChange,1=Copied)
endlocal & set "RC=%RC%"


rem === git init / add / commit ===
pushd "%DST_FULL%"
git --version >nul 2>&1 || (echo [WARN] git not found; skipping git steps & popd & exit /b 0)

if exist ".git" (
  echo [INFO] existing git repo
) else (
  git init >nul || (echo [FAIL] git init failed & popd & exit /b 10)
  echo [OK]   git init
)

if not exist ".gitignore" (
  type nul > ".gitignore"
  echo [OK]   created empty .gitignore
) else (
  echo [INFO] .gitignore exists
)

git add -A || (echo [FAIL] git add failed & popd & exit /b 12)
echo [OK]   git add .

git diff --cached --quiet
if errorlevel 2 (
  echo [FAIL] git diff --cached failed & popd & exit /b 14
) else if errorlevel 1 (
  git commit -m "first commit" >nul || (echo [FAIL] git commit failed & popd & exit /b 13)
  echo [OK]   git commit "first commit"
) else (
  echo [INFO] nothing to commit
)

popd
exit /b 0