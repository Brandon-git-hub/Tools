@echo off

:: 1. 設定 Anaconda 或 Miniconda 的環境路徑
:: 確保將 'C:\Users\YourName\anaconda3' 替換為您電腦上 Anaconda/Miniconda 的實際安裝路徑。
:: 如果您不確定路徑，通常只需保留 'call conda.bat activate' 即可，但明確指定路徑更可靠。
@REM call "C:\Users\YourName\anaconda3\Scripts\conda.bat" activate

:: 2. 啟動 conda 環境
call conda activate rpc_tool

:: 3. 檢查環境是否成功啟動
if "%CONDA_DEFAULT_ENV%"=="rpc_tool" (
    echo.
    echo ** Conda 環境 'rpc_tool' 啟動成功，開始執行 Python 腳本...
    echo.
    
    :: 4. 執行 Python 腳本
    :: 假設您的 Python 腳本路徑是從執行 .bat 檔案的當前目錄開始計算的
    python compare_16mask_gui_v4.py
    
    :: 5. 腳本執行完成後的提示
    echo.
    echo ** Python 腳本執行完畢。
) else (
    echo.
    echo ** 錯誤：Conda 環境 'rpc_tool' 啟動失敗！
    echo ** 請檢查您的環境名稱是否正確，或 Anaconda/Miniconda 路徑設定是否正確。
)

:: 讓視窗保持開啟，直到使用者按下任意鍵，方便查看執行結果和錯誤訊息
pause