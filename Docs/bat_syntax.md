

## 1️⃣ 基本批次檔結構

```bat
@echo off           :: 關閉指令顯示（整潔輸出）
REM 這是註解         :: 或用 "::" 做註解
echo Hello World    :: 顯示文字
pause               :: 暫停，等待按任意鍵
exit /b             :: 結束批次檔（不關閉命令提示字元）
```

---

## 2️⃣ 變數與輸入

```bat
set name=Brandon
echo %name%

set /p user_input=請輸入名稱:
echo 你輸入了 %user_input%
```

> `set /p` 可用來讓使用者輸入值。

---

## 3️⃣ 條件判斷

```bat
if "%name%"=="Brandon" (
    echo 你好，Brandon
) else (
    echo 你不是 Brandon
)

if exist file.txt (
    echo 找到檔案
) else (
    echo 檔案不存在
)
```

---

## 4️⃣ 迴圈 (FOR)

```bat
REM 遍歷資料夾內所有檔案
for %%f in (*.txt) do (
    echo 處理檔案 %%f
)

REM 遍歷資料夾及子資料夾
for /r %%f in (*.txt) do (
    echo 找到檔案 %%f
)

REM 用數字迴圈
for /l %%i in (1,1,5) do (
    echo 第 %%i 次
)
```

---

## 5️⃣ 路徑與檔名變數

```bat
set file_path=C:\Users\Brandon\test.txt
for %%A in ("%file_path%") do (
    echo 檔名：%%~nxA
    echo 目錄：%%~dpA
    echo 副檔名：%%~xA
)
```

---

## 6️⃣ 檔案與資料夾操作

```bat
md new_folder               :: 建立資料夾
rd old_folder /s /q         :: 刪除資料夾（含內容）
del file.txt /f /q          :: 刪除檔案
copy file1.txt file2.txt    :: 複製檔案
move file1.txt backup\      :: 移動檔案
```

---

## 7️⃣ 等待與延遲

```bat
timeout /t 5 /nobreak       :: 等待 5 秒
ping 127.0.0.1 -n 6 >nul    :: 等待 5 秒（1 秒 * 次數-1）
```

---

## 8️⃣ 呼叫其他程式

```bat
start notepad.exe
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" https://google.com
call other_script.bat
```

---

## 9️⃣ 錯誤處理

```bat
command || echo 發生錯誤
command && echo 執行成功
```

> `||` 代表前一個命令失敗才執行，`&&` 代表成功才執行。

---

## 🔟 範例：備份檔案批次檔

```bat
@echo off
set src=C:\MyData
set dest=D:\Backup

if not exist "%dest%" md "%dest%"

echo 正在備份...
xcopy "%src%" "%dest%" /e /i /y
echo 備份完成！
pause
```


