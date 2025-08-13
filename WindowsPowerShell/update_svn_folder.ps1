param(
#   [Parameter(Mandatory=$true, Position=0)]
#   [string[]]$Paths
# 把 -File 後面所有參數都當成路徑清單吃進來
  [Parameter(Position=0, ValueFromRemainingArguments=$true)]
  [string[]]$Paths
)

$ErrorActionPreference = 'Stop'

# TortoiseSVN 可執行檔
$TortoiseProc = "C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe"
if (-not (Test-Path $TortoiseProc)) {
  throw "Cannot find TortoiseProc.exe at $TortoiseProc"
}

# function Invoke-TortoiseProc {
#   param([string[]]$ArgList)

#   Write-Host "RUN:" $TortoiseProc ($ArgList -join ' ')
#   & $TortoiseProc @ArgList
#   $code = $LASTEXITCODE
#   if ($code -ne 0) {
#     throw "TortoiseProc failed (ExitCode=$code) : $($ArgList -join ' ')"
#   }
# }

function Invoke-TortoiseProc {
  param([string[]]$ArgList)

  Write-Host "RUN:" $TortoiseProc ($ArgList -join ' ')

  # 用 Start-Process 可靠拿 ExitCode；ArgumentList 用陣列就好，讓 PowerShell 自動處理引號
  $p = Start-Process -FilePath $TortoiseProc `
                     -ArgumentList $ArgList `
                     -WindowStyle Hidden `
                     -Wait -PassThru

  # 有些版本會回傳 0=成功；極少數情況 ExitCode 可能是 $null（仍可當成功）
  $code = $p.ExitCode
  if ($null -eq $code -or $code -eq 0) { return }

  throw "TortoiseProc failed (ExitCode=$code) : $($ArgList -join ' ')"
}


foreach ($path in $Paths) {
  Write-Host "`n=== Processing: $path ==="

  if (-not (Test-Path -LiteralPath $path)) {
    Write-Warning "Path not found. Skipped."
    continue
  }

  # 找工作拷貝根 (往上找 .svn)
  $wc = Get-Item -LiteralPath $path
  while ($wc -and -not (Test-Path (Join-Path $wc.FullName ".svn"))) {
    $wc = $wc.Parent
  }

  if (-not $wc) {
    Write-Warning "Not an SVN working copy. Skipped."
    continue
  }

  $wcRoot = $wc.FullName

  # 1~3) revert + 刪除 unversioned/ignored
  Invoke-TortoiseProc @(
    "/command:cleanup",
    "/path:$wcRoot",
    "/cleanup",
    "/revert",
    "/delunversioned",
    "/delignored",
    "/externals",
    "/noui", "/noprogressui", "/nodlg",
    "/closeonend:1"
  )
  Write-Host "  Revert + delete unversioned/ignored: OK"

  # 4) update
  Invoke-TortoiseProc @(
    "/command:update",
    "/path:$wcRoot",
    "/closeonend:1"
  )
  Write-Host "  Update: OK"
}

Write-Host "`nAll done."
