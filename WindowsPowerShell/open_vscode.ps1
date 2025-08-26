param(
    # 第 0 個參數：開窗模式（預設共用同一視窗）
    [Parameter(Position=0)]
    [ValidateSet('reuse','new')]
    [string]$Window = 'new',

    # 從第 1 個參數開始：要開啟的所有路徑
    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Paths
)

if (-not $Paths -or $Paths.Count -eq 0) {
    Write-Host "No paths passed from caller; skip launching VS Code."
    exit 0
}

# 解析 Code.exe（避免殘留 C:\Windows\System32\cmd.exe 視窗）
$codeExe = $null
$codeCmd = Get-Command code -ErrorAction SilentlyContinue
if ($codeCmd) {
    $binDir  = Split-Path $codeCmd.Source -Parent
    $rootDir = Split-Path $binDir -Parent
    $candidate = Join-Path $rootDir 'Code.exe'
    if (Test-Path $candidate) { $codeExe = $candidate }
}
if (-not $codeExe) {
    $candidate = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'
    if (Test-Path $candidate) { $codeExe = $candidate }
}

$openArg = if ($Window -eq 'new') { '-n' } else { '-r' }

if ($codeExe) {
    foreach ($p in $Paths) {
        if (Test-Path $p) {
            # Start-Process -FilePath $codeExe -ArgumentList @($openArg, $p)
            $cmd = 'start "" "{0}" {1} "{2}"' -f $codeExe, $openArg, $p
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -WindowStyle Hidden

            Write-Host "Opening in VS Code (Code.exe): $p"
        } else {
            Write-Host "Path not found: $p"
        }
    }
} elseif ($codeCmd) {
    Write-Host "Code.exe not found, fallback to 'code' shim (hide cmd window)."
    foreach ($p in $Paths) {
        if (Test-Path $p) {
            # Start-Process -FilePath $codeCmd.Source -ArgumentList "." -WorkingDirectory $p -WindowStyle Hidden
            $cmd = 'start "" "{0}" .' -f $codeCmd.Source
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -WorkingDirectory $p -WindowStyle Hidden

            Write-Host "Opening via shim: $p"
        } else {
            Write-Host "Path not found: $p"
        }
    }
} else {
    Write-Host "Neither Code.exe nor 'code' found in PATH."
    exit 1
}

Write-Host "All done."
