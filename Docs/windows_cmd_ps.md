# 路徑與瀏覽

* **顯示目前路徑**
  CMD：`cd`　|　PowerShell：`pwd`
* **列出檔案/資料夾**
  CMD：`dir`　|　PowerShell：`ls`（= `Get-ChildItem`）
* **切換資料夾**
  `cd 路徑`　例：`cd "D:\Work\Project"`
  提示：`cd ..` 回上層、`cd \` 回磁碟根目錄、`D:` 切到 D 槽

# 建立 / 重新命名 / 刪除

* **建立資料夾**
  CMD：`mkdir 新資料夾`（= `md`）
  PowerShell：`New-Item -ItemType Directory -Path 新資料夾`
* **重新命名**
  CMD：`ren 舊名 新名`
  PowerShell：`Rename-Item 舊名 -NewName 新名`
* **刪除檔案/資料夾**
  檔案：`del 檔案`　|　`Remove-Item 檔案`
  資料夾（含其內容）：`rmdir /s /q 資料夾`　|　`Remove-Item 資料夾 -Recurse -Force`

# 複製 / 移動（含整個資料夾）

* **複製檔案**
  CMD：`copy a.txt D:\Backup\`
  PowerShell：`Copy-Item a.txt -Destination D:\Backup`
* **複製整個資料夾（穩、適合大量檔案）**
  👉 `robocopy "D:\Src" "E:\Dst" /E`  （/E 含空資料夾）
* **移動（或改名）檔案/資料夾（同槽很快；跨槽=複製+刪除）**
  CMD：`move "D:\Src\資料夾" "E:\Dst\"`
  PowerShell：`Move-Item "D:\Src\資料夾" -Destination "E:\Dst\"`
* **移動整個資料夾（大量檔案/跨磁碟，建議用這個）**

  ```cmd
  robocopy "D:\Src\BigFolder" "E:\Archive\BigFolder" /E /MOVE /R:1 /W:1
  ```

  說明：`/MOVE` ＝ 複製完成後刪除來源；`/R:1 /W:1` 失敗重試 1 次、等待 1 秒（避免卡太久）。

# 搜尋與內容

* **找檔名**
  CMD：`dir /s /b *.log`（在當前路徑遞迴找 .log）
  PowerShell：`Get-ChildItem -Recurse -Filter *.log`
* **在檔案裡找關鍵字**
  CMD：`findstr /s /n "keyword" *.txt`
  PowerShell：`Select-String -Path *.txt -Pattern "keyword"`

# 進階常用

* **建立符號連結（把資料移走後留捷徑路徑）**
  以系統管理員開啟 CMD：
  `mklink /D "C:\Data\Cache" "D:\Cache"`
  （之後程式存取 `C:\Data\Cache` 其實用到 D 槽）
* **檢視/變更檔案屬性**
  `attrib`　|　PowerShell：`Get-Item` / `Set-ItemProperty`

# 移動資料夾的小提醒

* 路徑有空白請加引號：`"D:\My Projects\X"`
* 跨磁碟大量檔案 → 用 `robocopy /E /MOVE` 比 `move` 穩定又可續傳。
* 每個命令都能加 `/?` 看說明：`robocopy /?`、`move /?`；PowerShell 用 `Get-Help Move-Item -Full`。