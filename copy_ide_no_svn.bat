@REM copy_ide_no_svn.bat
@echo off
setlocal EnableExtensions

@REM Build date string as yyMMdd (e.g., 2025/8/14 -- 250814)
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format yyMMdd"') do set "DATE_YYMMDD=%%A"

@REM Define bases
set "SRC_BASE=C:\Users\brandon_wu\Documents\PDK_IDE\Newest_IDE"
set "DST_BASE=C:\Users\brandon_wu\Documents\PDK_IDE\%DATE_YYMMDD%_version"

@REM List of folders to copy
set "DIRS=PADAUK_IDE Writer_All Writer_IC_RPC"

echo [INFO] Snapshot date: %DATE_YYMMDD%
echo [INFO] Dest root   : "%DST_BASE%"
if not exist "%DST_BASE%" (
    mkdir "%DST_BASE%" || (echo [FAIL] Cannot create "%DST_BASE%" & exit /b 10)
)

@REM Copy each folder using robocopy, excluding .svn
setlocal EnableDelayedExpansion
for %%D in (%DIRS%) do (
    set "SRC=%SRC_BASE%\%%D"
    set "DST=%DST_BASE%\%%D"
    echo.
    echo [INFO] Copying "%%D"
    if not exist "!SRC!" (
        echo [WARN] Source not found: "!SRC!" - skipping.
        @REM continue to next
    ) else (
        robocopy "!SRC!" "!DST!" /E /XD .svn /R:2 /W:2 /DCOPY:T /COPY:DAT /MT:16 /NFL /NDL /NJH /NJS /NP
        set "RC=!ERRORLEVEL!"
        @REM robocopy success codes are 0–7
        if !RC! GEQ 8 (
            echo [FAIL] robocopy failed for "%%D" with code !RC!
            exit /b !RC!
        ) else (
            echo [OK]   Done "%%D" (robocopy code !RC!)
        )
    )
)

echo.
echo [ALL DONE] Output under: "%DST_BASE%"
endlocal
exit /b 0
