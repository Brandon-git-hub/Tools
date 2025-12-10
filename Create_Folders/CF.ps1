param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Paths
)

if (-not $Paths -or $Paths.Count -eq 0) {
    Write-Host "No paths passed from caller;"
    exit 0
}

# 定義
$FolderNumbers = "0B", "0C", "0D"

# 定義每個資料夾內的子資料夾名稱
$SubFolder = "dump"

foreach ($p in $Paths) {
    $TargetDir = $p
    
    Write-Host "Creating folders in: $TargetDir"

    foreach ($i in $FolderNumbers) {
        # 1. 組合成主要資料夾名稱 (例如: #30)
        $FolderName = "#" + $i

        # 2. 組合完整的路徑，直接包含子資料夾，並用 New-Item -Force 建立
        # 範例路徑: C:\Users\brandon_wu\...\#30\dump
        $FullPathWithSubFolder = Join-Path -Path $TargetDir -ChildPath "$FolderName\$SubFolder"

        # New-Item 加上 -Force 會自動建立所有不存在的父目錄和子目錄
        New-Item -ItemType Directory -Path $FullPathWithSubFolder -Force | Out-Null
    }
}
