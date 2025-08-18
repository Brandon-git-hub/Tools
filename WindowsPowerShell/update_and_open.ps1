# 需要 git pull 確認更新的路徑
$gitPaths = @(
    "C:\Users\brandon_wu\Documents\P005\Docs",
    "C:\Users\brandon_wu\Documents\esp_idf\Wifi_system_v2",
    "C:\Users\brandon_wu\Desktop\Tools",
    "C:\Users\brandon_wu\Documents\PersonalDrive",
    "C:\Users\brandon_wu\Documents\Wifi_system_MQTT_Broker"
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
    foreach ($path in $codePaths) {
        Write-Host "=== Open in VS Code: $path ==="

        if (Test-Path $path) {
            # 在指定資料夾內開啟 VS Code
            Start-Process -FilePath $codeCmd.Source -ArgumentList "." -WorkingDirectory $path
            Write-Host "Opening in VS Code..."
            # code .
        } else {
            Write-Host "Path not found: $path"
        }

        Write-Host ""
    }
}

Write-Host "All done."
Start-Sleep -Seconds 10
