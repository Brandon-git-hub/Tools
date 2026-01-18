# GEMINI 專案情境：工具儲存庫

本文件為 `Tools` 目錄提供情境說明，這是一個包含實用腳本和自動化工具的個人集合。

## 目錄概覽

這個儲存庫是一個個人工具箱，包含各種用於自動化重複性任務、處理數據和輔助開發工作流程的腳本。它不是一個單一、統一的軟體專案，而是一個獨立工具的集合。

這些腳本主要以多種語言編寫：
*   **批次檔 (`.bat`)**：用於簡單的自動化和命令列任務。
*   **PowerShell (`.ps1`)**：用於更進階的 Windows 自動化和圖形化使用者介面 (GUI)。
*   **Python (`.py`)**：用於數據處理、網路爬蟲和圖形化使用者介面 (GUI) 應用程式。

此儲存庫根據功能劃分為不同的子目錄。文件和提交訊息主要使用繁體中文。

## 主要檔案與功能區

這不是一個詳盡的列表，但涵蓋了此儲存庫中工具的主要功能。

*   **Git 自動化 (`auto_git_push.bat`)**:
    *   一個可快速加入所有變更、以當前日期為訊息進行提交，並推送到遠端儲存庫的腳本。

*   **資料比對 (`Compare/`)**:
    *   包含 Python 腳本，特別是 `compare_16mask_gui_v4.py`，它提供一個基於 `PySimpleGUI` 的介面，用於比對兩個位址資料檔案，將差異視覺化為 16-bit mask 網格，並匯出報告。

*   **檔案轉換**:
    *   **`Excel_Converter_GUI/`**: 一個 PowerShell 腳本，會開啟檔案對話框讓使用者選取 Excel 檔案，並將其轉換為 UTF-8 CSV 檔案。需要安裝 Microsoft Excel。
    *   **`Word_to_PDF_Converter_GUI/`**: 一個功能類似的 PowerShell 腳本，用於將 Word 文件轉換為 PDF。
    *   **`Image/png_to_ico.py`**: 一個用於將 PNG 圖片轉換為 ICO 格式的 Python 腳本。

*   **網路爬蟲 (`Web_Crawler/`)**:
    *   包含一個 Python 腳本 (`104_job_search_dft.py`)，用於從台灣的求職網站 104.com.tw 爬取 DFT 工程師的職缺。它會篩選結果並將其儲存為 CSV 和 Markdown 檔案。

*   **開發環境 (`Gemini/`, `open_vscode.bat`)**:
    *   透過啟用特定的 Conda 環境來啟動 Gemini CLI 的腳本 (`run_gemini.bat`)。
    *   用於在 VS Code 中開啟特定專案或整個 `Tools` 工作區的批次檔。

*   **系統工具 (`Geek/`, `Create_Folders/`)**:
    *   `geek.exe` 是一個可攜式工具，用於搜尋和移除程式解除安裝後殘留的登錄檔項目。
    *   用於批次建立資料夾結構的腳本。

## 使用方式

此儲存庫中的工具旨在作為獨立腳本，從命令列介面（如命令提示字元或 PowerShell）執行。

*   **批次檔 (`.bat`)**：可直接執行。
*   **PowerShell 腳本 (`.ps1`)**：可從 PowerShell 終端機執行。請注意，您可能需要調整執行原則 (`Set-ExecutionPolicy`)。
*   **Python 腳本 (`.py`)**：需要安裝 Python 及必要的函式庫（例如 `pandas`, `PySimpleGUI`, `requests`）。建議使用虛擬環境。

某些腳本，特別是那些位於以 GUI 為主的目錄中的腳本，會啟動自己的圖形化使用者介面。
