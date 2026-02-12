param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Paths
)

if (-not $Paths -or $Paths.Count -eq 0) {
    Write-Host "No paths passed from caller;"
    exit 0
}

# 定義
$FolderNumbers = "00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "0A", `
"0B", "0C", "0D", "0E", "0F", "10", "11", "12", "13", "14", "15", "16", "17", "18", `
"19", "1A", "1B", "1C", "1D", "1E", "1F", "20"

# 定義每個資料夾內的子資料夾名稱
# $SubFolder = "Scan_VPP"
$SubFolder = "dump"

foreach ($p in $Paths) {
    $TargetDir = $p
    
    Write-Host "Creating folders in: $TargetDir"

    foreach ($i in $FolderNumbers) {
        # 1. 組合成主要資料夾名稱 (例如: #30)
        # $FolderName = "#" + $i
        $FolderName = $i

        # 2. 組合完整的路徑，直接包含子資料夾，並用 New-Item -Force 建立
        # 範例路徑: C:\Users\brandon_wu\...\#30\dump
        # $FullPathWithSubFolder1 = Join-Path -Path $TargetDir -ChildPath "$FolderName\$SubFolder\3_12V"
        # $FullPathWithSubFolder2 = Join-Path -Path $TargetDir -ChildPath "$FolderName\$SubFolder\11_3V"
        # $FullPathWithSubFolder = Join-Path -Path $TargetDir -ChildPath "$FolderName\$SubFolder\"
        $FullPathWithSubFolder = Join-Path -Path $TargetDir -ChildPath "$FolderName\"

        # New-Item 加上 -Force 會自動建立所有不存在的父目錄和子目錄
        New-Item -ItemType Directory -Path $FullPathWithSubFolder -Force | Out-Null
        # New-Item -ItemType Directory -Path $FullPathWithSubFolder1 -Force | Out-Null
        # New-Item -ItemType Directory -Path $FullPathWithSubFolder2 -Force | Out-Null
    }
}
