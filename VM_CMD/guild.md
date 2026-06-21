# VM 背景控制工具說明文件

本目錄已整合為單一核心控制腳本 `vm_control.ps1`，並提供 `vm_control.bat` 作為命令列入口。此工具支援**互動式選單模式**與**直接命令列參數模式**。

---

## 快速使用方式

### 1. 互動式選單模式（推薦）
在終端機中直接執行 `vm_control.bat`（不帶任何參數），將會開啟互動式選單：
```cmd
vm_control.bat
```
在選單中，您可以：
- **主選單**：直接進行最常用的無 GUI 背景啟動 (nogui)、安全掛起 (soft suspend)、安全關閉 (soft stop) 操作，或切換預設虛擬機、輸入自訂路徑等。
- **進階選單 (Advanced Menu)**：進入子選單執行其他進階指令（如 GUI 啟動、強制斷電、重啟、硬掛起、暫停與恢復等）。

### 2. 直接命令列參數模式
您可以透過命令列直接傳入指令來控制虛擬機。語法如下：
```cmd
vm_control.bat <Action> [VmNameOrPath] [Mode]
```
- `<Action>`: 執行的電源動作（例如 `start`, `stop`, `reset`, `suspend`, `pause`, `unpause`, `list`）。
- `[VmNameOrPath]`: 虛擬機名稱（對應腳本中的預設對照表，如 `Ubuntu`）或 `.vmx` 檔案的絕對路徑。若為 `list` 動作，此參數可省略。
- `[Mode]`: 針對特定動作的模式參數（例如啟動的 `nogui`/`gui`，關機/重啟/掛起的 `soft`/`hard`）。

#### 常用命令列範例
- **列出所有運行中的虛擬機**：
  ```cmd
  vm_control.bat list
  ```
- **在背景啟動預設的 Ubuntu 虛擬機 (Headless)**：
  ```cmd
  vm_control.bat start Ubuntu nogui
  ```
- **以視窗介面 (GUI) 啟動預設的 Ubuntu 虛擬機**：
  ```cmd
  vm_control.bat start Ubuntu gui
  ```
- **安全關閉 (軟關機) 預設的 Ubuntu 虛擬機**：
  ```cmd
  vm_control.bat stop Ubuntu soft
  ```
- **強制切斷電源 (硬關機) 預設的 Ubuntu 虛擬機**：
  ```cmd
  vm_control.bat stop Ubuntu hard
  ```

---

## `vmrun` 電源指令與參數整理

以下為核心 `vmrun` 所支援的電源狀態與說明：

| 電源指令 (`Action`) | 模式參數 (`Mode`) | 說明 |
| :--- | :--- | :--- |
| **`start`** | `[ gui \| nogui ]` | 啟動虛擬機。預設為 `nogui`（背景執行，適合 SSH/VS Code 連線）。若使用 `gui` 則會以互動方式顯示虛擬機視窗。**注意：** 啟動加密的虛擬機時必須使用 `nogui` 參數。 |
| **`stop`** | `[ hard \| soft ]` | 關閉虛擬機。`soft` 會向客體作業系統發出訊號並執行正常的關機指令碼（軟關機）；`hard` 則如同直接按下實體電源按鈕，強行關閉虛擬機電源（硬關機）。 |
| **`reset`** | `[ hard \| soft ]` | 重新啟動虛擬機。`soft` 會先執行關機指令碼後再正常重新啟動；`hard` 則強行復位並重新啟動虛擬機，不等待系統正常關閉。 |
| **`suspend`** | `[ hard \| soft ]` | 將虛擬機掛起。`soft` 會在掛起前透過 VMware Tools 執行系統腳本（例如釋放 IP、暫停網路連線）；`hard` 則直接掛起虛擬機。 |
| **`pause`** | (無額外參數) | 暫停虛擬機運作（畫面反灰），且不會發送或接收網路封包。 |
| **`unpause`** | (無額外參數) | 恢復運作。讓處於 `pause` (暫停) 狀態的虛擬機繼續正常運作。 |

---

## 向下相容腳本

為了維持與舊工具/自動化排程的相容性，本目錄保留了以下腳本。它們已被改寫為調用 `vm_control.ps1` 的轉接器：
- `vm_list.bat` / `vm_list.ps1` -> 列出運行中的虛擬機。
- `vm_start.bat` / `vm_start.ps1` -> 在背景 (nogui) 啟動預設的 Ubuntu 虛擬機。
- `vm_stop.bat` / `vm_stop.ps1` -> 安全關閉 (soft) 預設的 Ubuntu 虛擬機。
- `vm_pwr_off.bat` / `vm_pwr_off.ps1` -> 強制斷電 (hard) 預設的 Ubuntu 虛擬機。
