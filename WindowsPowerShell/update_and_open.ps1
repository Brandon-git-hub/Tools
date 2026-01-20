# 需要 git pull 確認更新的路徑
$gitPaths = @(
    "C:\Users\brandon_wu\Documents\P005\Docs",
    "C:\Users\brandon_wu\Documents\esp_idf\Wifi_system_v2",
    "C:\Users\brandon_wu\Desktop\Tools",
    "C:\Users\brandon_wu\Documents\PersonalDrive"
)

# 需要用 VS Code 開啟的路徑
$codePaths = @(
    "C:\Users\brandon_wu\Documents\P005\Docs"
    # "C:\Users\brandon_wu\Desktop\Tools"
)

# --- Git pull 區 ---
foreach ($path in $gitPaths) {
    Write-Host "=== Git Pull: $path ==="

    if (Test-Path $path) {
        Push-Location -Path $path

        if (Test-Path -Path (Join-Path $path ".git")) {
            Write-Host "Running: git fetch --all --prune"
            git fetch --all --prune
            Write-Host "Running: git status -sb"
            git status -sb
            Write-Host "Running: git pull --rebase --autostash"
            git pull --rebase --autostash
        } else {
            Write-Host "Not a git repo, skipping git pull."
        }

        Pop-Location
    } else {
        Write-Host "Path not found: $path"
    }

    Write-Host ""
}

# --- VS Code 開啟區 ---
$codeCmd = Get-Command code -ErrorAction SilentlyContinue
if (-not $codeCmd) {
    Write-Host "VS Code 'code' command not found in PATH. Skipping VS Code section."
} else {
    $codeExe = Join-Path (Split-Path (Split-Path $codeCmd.Source -Parent) -Parent) 'Code.exe'
    if (-not (Test-Path $codeExe)) {
        # 萬一抓不到，就試常見的安裝位置
        $codeExe = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
    }
    if (-not (Test-Path $codeExe)) {
        Write-Host "Cannot locate Code.exe, fallback to 'code' shim (may leave a cmd window)."
        foreach ($path in $codePaths) {
            if (Test-Path $path) {
                # 如果只能用 shim，至少把 shim 的視窗藏起來
                # Start-Process -FilePath $codeCmd.Source -ArgumentList "." -WorkingDirectory $path -WindowStyle Hidden
                $cmd = 'start "" "{0}" {1} "{2}"' -f $codeCmd.Source, $openArg, $path
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -WindowStyle Hidden

                Write-Host "Opening in VS Code (shim, hidden window): $path"
            } else {
                Write-Host "Path not found: $path"
            }
        }
    } else {
        foreach ($path in $codePaths) {
            Write-Host "=== Open in VS Code: $path ==="
            if (Test-Path $path) {
                # -ArgumentList 可用 -r（reuse window）或 -n（new window），選一個習慣
                # Start-Process -FilePath $codeExe -ArgumentList @("-r", $path)
                $openArg = "-r"
                $cmd = 'start "" "{0}" {1} "{2}"' -f $codeExe, $openArg, $path
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -WindowStyle Hidden

                Write-Host "Opening in VS Code..."
                # code .
            } else {
                Write-Host "Path not found: $path"
            }
            Write-Host ""
        }
    }
}

Write-Host "All done."
# Start-Sleep -Seconds 10
