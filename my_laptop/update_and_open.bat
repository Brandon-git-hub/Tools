@echo off
REM 建議檔案以 UTF-8 儲存；若中文顯示亂碼，可取消下一行註解使用 UTF-8 主控台
REM chcp 65001 >nul

setlocal EnableExtensions EnableDelayedExpansion

REM === 需要 git pull 確認更新的路徑 ===
for %%P in (
"C:\Users\User\Documents\Docs"
"C:\Users\User\Documents\PDK_Works\Wifi_system"
"C:\Users\User\Documents\PDK_Works\Wifi_system_MQTT_Broker"
"C:\Users\User\Documents\Tools\"
) do (
    echo === Git Pull: %%~fP ===

    if exist "%%~fP" (
        pushd "%%~fP"

        if exist ".git\" (
            echo Running: git fetch --all --prune
            git fetch --all --prune

            echo Running: git status -sb
            git status -sb

            echo Running: git pull --rebase --autostash
            git pull --rebase --autostash
        ) else (
            echo Not a git repo, skipping git pull.
        )

        popd
    ) else (
        echo Path not found: %%~fP
    )

    echo.
)

REM === VS Code 開啟區（用副程式，避免括號群組回顯） ===
where code >nul 2>&1
if errorlevel 1 (
    echo VS Code 'code' command not found in PATH. Skipping VS Code section.
) else (
    for %%P in (
    "C:\Users\User\Documents\Docs"
    "C:\Users\User\Documents\Blog"
    ) do call :OpenInCode "%%~fP"
)
goto :after_vscode

:OpenInCode
echo === Open in VS Code: %~1 ===
if exist "%~1" (
    pushd "%~1"
    code .
    echo Opening in VS Code...
    popd
) else (
    echo Path not found: %~1
)
echo.
exit /b

:after_vscode

