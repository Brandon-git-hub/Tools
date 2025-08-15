@echo off
chcp 65001 >nul

@REM Build date string as yyMMdd (e.g., 2025/8/14 -- 250814)
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format yyMMdd"') do set "DATE_YYMMDD=%%A"

rem 初始化 repo（若尚未存在）
if exist ".git" (
    echo [INFO] existing git repo

    rem 關閉CRLF warning
    git config --local core.safecrlf false

    rem add + commit（只有有變更才 commit）
    git add -A || (echo [FAIL] git add failed & exit /b 12)

    git diff --cached --quiet
    if errorlevel 2 (
        echo [FAIL] git diff --cached failed & exit /b 14
    ) else if errorlevel 1 (
        git commit -m "%date%" >nul || (echo [FAIL] git commit failed & exit /b 13)
        echo [OK]   git commit "%date%"
    ) else (
        echo [INFO] nothing to commit
    )
) else (
    git init >nul || (echo [FAIL] git init failed & exit /b 10)
    echo [OK]   git init

    rem 關閉CRLF warning
    git config --local core.safecrlf false

    rem add + commit（只有有變更才 commit）
    git add -A || (echo [FAIL] git add failed & exit /b 12)

    git diff --cached --quiet
    if errorlevel 2 (
        echo [FAIL] git diff --cached failed & exit /b 14
    ) else if errorlevel 1 (
        git commit -m "first commit %DATE_YYMMDD%" >nul || (echo [FAIL] git commit failed & exit /b 13)
        echo [OK]   git commit "first commit %DATE_YYMMDD%"
    ) else (
        echo [INFO] nothing to commit
    )
)

pause