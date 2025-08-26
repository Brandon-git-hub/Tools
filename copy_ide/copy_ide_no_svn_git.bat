@REM copy_ide_no_svn.bat
@echo off
setlocal EnableExtensions

@REM Build date string as yyMMdd (e.g., 2025/8/14 -- 250814)
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format yyMMdd"') do set "DATE_YYMMDD=%%A"

@REM Define bases
set "SRC_BASE=C:\Users\brandon_wu\Documents\PDK_IDE\Newest_IDE"
set "DST_BASE=C:\Users\brandon_wu\Documents\PDK_IDE\%DATE_YYMMDD%_version"
@REM Request Accept
@REM gui or cli
set "PROMPT_MODE=gui"


@REM List of folders to copy
set "DIRS=PADAUK_IDE Writer_All Writer_IC_RPC"

@REM Copy each folder using robocopy, excluding .svn
setlocal EnableDelayedExpansion
for %%D in (%DIRS%) do (
    set "SRC=%SRC_BASE%\%%D"
    if not exist "!SRC!" (
        echo [WARN] Source not found: "!SRC!" - skipping.
        @REM continue to next
    ) else (
        @REM Accept? 
        call :RequireSource "%SRC_DIR%" || pause
        call :Confirm "%PROMPT_MODE%" || (echo [ABORT] User Cancel Actions. & timeout /t 2 /nobreak > nul & exit /b 2 )

        @REM Build DST
        echo [INFO] Snapshot date: %DATE_YYMMDD%
        echo [INFO] Dest root   : "%DST_BASE%"
        if not exist "%DST_BASE%" (
            mkdir "%DST_BASE%" || (echo [FAIL] Cannot create "%DST_BASE%" & timeout /t 2 /nobreak > nul & exit /b 10 )
        ) 
        @REM else (
        @REM   echo [INFO] Exist DST, Please Check first.
        @REM   timeout /t 5 /nobreak > nul
        @REM   exit /b 2
        @REM )

        set "DST=%DST_BASE%\%%D"
        echo.
        echo [INFO] Copying "%%D"

        robocopy "!SRC!" "!DST!" /E /XD .svn /R:2 /W:2 /DCOPY:T /COPY:DAT /MT:16 /NFL /NDL /NJH /NJS /NP
        set "RC=!ERRORLEVEL!"
        @REM robocopy success codes are 0–7
        if !RC! GEQ 8 (
            echo [FAIL] robocopy failed for "%%D" with code !RC!
            exit /b !RC!
        ) else (
            echo [OK]   Done "%%D" (robocopy code !RC!)
        )

        rem === git init / add / commit (per-destination folder) ===
        pushd "!DST!" >nul
        if errorlevel 1 (
            echo [FAIL] Cannot enter "!DST!"
        ) else (
          rem 2) 初始化 repo（若尚未存在）
          if exist ".git" (
            echo [INFO] existing git repo
          ) else (
            git init >nul || (echo [FAIL] git init failed & popd & exit /b 10)
            echo [OK]   git init
          )

          rem 關閉warning
          git config --local core.safecrlf false

          rem 3) 準備 .gitignore（若不存在就建立空檔）
          if not exist ".gitignore" (
            type nul > ".gitignore"
            echo [OK]   created empty .gitignore
          ) else (
            echo [INFO] .gitignore exists
          )
          
          rem 4) add + commit（只有有變更才 commit）
          git add -A || (echo [FAIL] git add failed & popd & exit /b 12)
          echo [OK]   git add .

          git diff --cached --quiet
          if errorlevel 2 (
            echo [FAIL] git diff --cached failed & popd & exit /b 14
          ) else if errorlevel 1 (
            git commit -m "first commit %DATE_YYMMDD%" >nul || (echo [FAIL] git commit failed & popd & exit /b 13)
            echo [OK]   git commit "first commit %DATE_YYMMDD%"
          ) else (
            echo [INFO] nothing to commit
          )
        )
        popd
    )
)

echo.
echo [ALL DONE] Output under: "%DST_BASE%"
endlocal
timeout /t 5 /nobreak > nul
exit /b 0

REM ================== Helpers: file check + one-time confirmation ==================

:RequireSource
REM Usage: call :RequireSource "source_folder" "file_glob"
setlocal
set "dir=%~1"
set "glob=%~2"

if not exist "%dir%\" (
  echo [FAIL] Source folder not found: %dir%
  endlocal & exit /b 2
)

for /f "delims=" %%F in ('dir /b /a-d "%dir%\%glob%" 2^>nul') do (
  endlocal & exit /b 0
)

echo [FAIL] No files matching "%glob%" in: %dir%
endlocal & exit /b 3

:Confirm
REM Usage: call :Confirm gui|cli
setlocal
set "mode=%~1"

REM Already confirmed in this run?
if /i "%CONFIRMED%"=="1" (
  endlocal & exit /b 0
)

REM Force CLI if requested
if /i "%mode%"=="cli" goto conf_cli

REM --- GUI (preferred) PowerShell MessageBox ---
where powershell >nul 2>nul && (
  powershell -NoProfile -Command ^
    "[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms');" ^
    "$r=[System.Windows.Forms.MessageBox]::Show('Proceed with the operation?','Confirm','YesNo','Question');" ^
    "if($r -eq 'Yes'){exit 0}else{exit 1}"
  if errorlevel 1 (
    endlocal & exit /b 1
  ) else (
    endlocal & set "CONFIRMED=1" & exit /b 0
  )
)

REM --- GUI fallback: mshta + VBScript ---
where mshta >nul 2>nul && (
  mshta "vbscript:close(msgbox(""Proceed with the operation?"",36,""Confirm""))"
  set "rc=%ERRORLEVEL%"
  if "%rc%"=="6" (
    endlocal & set "CONFIRMED=1" & exit /b 0
  ) else (
    endlocal & exit /b 1
  )
)

REM --- CLI mode, or when GUI is unavailable ---
:conf_cli
choice /C YN /N /M "Proceed with the operation? [Y/N] " /T 30 /D N
if errorlevel 2 (
  endlocal & exit /b 1
) else (
  endlocal & set "CONFIRMED=1" & exit /b 0
)
