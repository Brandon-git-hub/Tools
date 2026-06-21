param (
    [string]$Action,
    [string]$VmNameOrPath,
    [string]$Mode
)

# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------
$VMRUN_PATH = "C:\Program Files\VMware\VMware Workstation\vmrun.exe"

# Default VM mapping
$DefaultVMs = [ordered]@{
    "Ubuntu" = "$env:USERPROFILE\Documents\Virtual Machines\Ubuntu 64-bit\Ubuntu 64-bit.vmx"
}

# ---------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------

# Validate vmrun.exe path
function Test-VmrunPath {
    if (-not (Test-Path $VMRUN_PATH)) {
        Write-Host "Error: vmrun.exe not found at: $VMRUN_PATH" -ForegroundColor Red
        Write-Host "Please check if VMware Workstation is installed, or modify `$VMRUN_PATH in this script." -ForegroundColor Yellow
        return $false
    }
    return $true
}

# Resolve VM Name or Path
function Resolve-VmPath {
    param (
        [string]$InputPath
    )
    if ([string]::IsNullOrWhiteSpace($InputPath)) {
        if ($DefaultVMs.Count -eq 1) {
            return $DefaultVMs.Values[0]
        }
        return $null
    }

    if ($DefaultVMs.ContainsKey($InputPath)) {
        return $DefaultVMs[$InputPath]
    }

    try {
        return Resolve-Path $InputPath -ErrorAction Stop
    }
    catch {
        return $InputPath
    }
}

# Invoke vmrun Command
function Invoke-VmrunCommand {
    param (
        [string]$Act,
        [string]$VmPath,
        [string]$Opt
    )

    if (-not (Test-VmrunPath)) { return }

    if ($Act -eq "list") {
        Write-Host "Listing running VMs..." -ForegroundColor Cyan
        & $VMRUN_PATH list
        return
    }

    if ([string]::IsNullOrWhiteSpace($VmPath)) {
        Write-Host "Error: This action requires a VM path (.vmx file)." -ForegroundColor Red
        return
    }

    if (-not (Test-Path $VmPath)) {
        Write-Host "Error: VM file not found: $VmPath" -ForegroundColor Red
        return
    }

    $vmName = Split-Path $VmPath -Leaf

    switch ($Act) {
        "start" {
            $runMode = if ([string]::IsNullOrWhiteSpace($Opt)) { "nogui" } else { $Opt }
            Write-Host "Starting VM ($runMode mode): $vmName ..." -ForegroundColor Cyan
            & $VMRUN_PATH -T ws start $VmPath $runMode
            if ($LASTEXITCODE -eq 0) {
                if ($runMode -eq "nogui") {
                    Write-Host "VM started successfully in background (Headless). You can connect via SSH/VS Code now." -ForegroundColor Green
                } else {
                    Write-Host "VM started successfully with GUI." -ForegroundColor Green
                }
            }
        }
        "stop" {
            $stopMode = if ([string]::IsNullOrWhiteSpace($Opt)) { "soft" } else { $Opt }
            Write-Host "Stopping VM ($stopMode mode): $vmName ..." -ForegroundColor Cyan
            & $VMRUN_PATH -T ws stop $VmPath $stopMode
            if ($LASTEXITCODE -eq 0) {
                Write-Host "VM stopped successfully." -ForegroundColor Green
            }
        }
        "reset" {
            $resetMode = if ([string]::IsNullOrWhiteSpace($Opt)) { "soft" } else { $Opt }
            Write-Host "Resetting VM ($resetMode mode): $vmName ..." -ForegroundColor Cyan
            & $VMRUN_PATH -T ws reset $VmPath $resetMode
            if ($LASTEXITCODE -eq 0) {
                Write-Host "VM reset successfully." -ForegroundColor Green
            }
        }
        "suspend" {
            $suspendMode = if ([string]::IsNullOrWhiteSpace($Opt)) { "soft" } else { $Opt }
            Write-Host "Suspending VM ($suspendMode mode): $vmName ..." -ForegroundColor Cyan
            & $VMRUN_PATH -T ws suspend $VmPath $suspendMode
            if ($LASTEXITCODE -eq 0) {
                Write-Host "VM suspended successfully." -ForegroundColor Green
            }
        }
        "pause" {
            Write-Host "Pausing VM: $vmName ..." -ForegroundColor Cyan
            & $VMRUN_PATH -T ws pause $VmPath
            if ($LASTEXITCODE -eq 0) {
                Write-Host "VM paused successfully." -ForegroundColor Green
            }
        }
        "unpause" {
            Write-Host "Unpausing VM: $vmName ..." -ForegroundColor Cyan
            & $VMRUN_PATH -T ws unpause $VmPath
            if ($LASTEXITCODE -eq 0) {
                Write-Host "VM resumed successfully." -ForegroundColor Green
            }
        }
        default {
            Write-Host "Error: Unknown action '$Act'" -ForegroundColor Red
        }
    }
}

# ---------------------------------------------------------
# Interactive Menu
# ---------------------------------------------------------
function Show-InteractiveMenu {
    $selectedVmKey = $DefaultVMs.Keys | Select-Object -First 1
    $selectedVmPath = $DefaultVMs[$selectedVmKey]

    while ($true) {
        Clear-Host
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host "      VMware Workstation Background CLI   " -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host "Active VM: " -NoNewline
        Write-Host "$selectedVmKey " -ForegroundColor Yellow -NoNewline
        Write-Host "($selectedVmPath)" -ForegroundColor DarkGray
        Write-Host "-----------------------------------------"
        Write-Host "1.  Start VM (nogui - Background)"
        Write-Host "2.  Start VM (gui - Windowed)"
        Write-Host "3.  Stop VM (soft - Graceful Shutdown)"
        Write-Host "4.  Stop VM (hard - Power Off)"
        Write-Host "5.  Reset VM (soft)"
        Write-Host "6.  Reset VM (hard)"
        Write-Host "7.  Suspend VM (soft)"
        Write-Host "8.  Suspend VM (hard)"
        Write-Host "9.  Pause VM"
        Write-Host "10. Resume VM"
        Write-Host "11. List all running VMs"
        Write-Host "12. Choose/Switch default VM"
        Write-Host "13. Enter custom .vmx path"
        Write-Host "14. Exit"
        Write-Host "========================================="
        
        $choice = Read-Host "Enter your choice (1-14)"
        
        switch ($choice) {
            "1"  { Invoke-VmrunCommand "start" $selectedVmPath "nogui" }
            "2"  { Invoke-VmrunCommand "start" $selectedVmPath "gui" }
            "3"  { Invoke-VmrunCommand "stop" $selectedVmPath "soft" }
            "4"  { Invoke-VmrunCommand "stop" $selectedVmPath "hard" }
            "5"  { Invoke-VmrunCommand "reset" $selectedVmPath "soft" }
            "6"  { Invoke-VmrunCommand "reset" $selectedVmPath "hard" }
            "7"  { Invoke-VmrunCommand "suspend" $selectedVmPath "soft" }
            "8"  { Invoke-VmrunCommand "suspend" $selectedVmPath "hard" }
            "9"  { Invoke-VmrunCommand "pause" $selectedVmPath }
            "10" { Invoke-VmrunCommand "unpause" $selectedVmPath }
            "11" { Invoke-VmrunCommand "list" }
            "12" {
                Clear-Host
                Write-Host "=== Select Default VM ===" -ForegroundColor Green
                $keys = @($DefaultVMs.Keys)
                for ($i = 0; $i -lt $keys.Count; $i++) {
                    Write-Host "$($i + 1). $($keys[$i]) ($($DefaultVMs[$keys[$i]]))"
                }
                Write-Host "$($keys.Count + 1). Return to Main Menu"
                
                $vmChoice = Read-Host "Choose VM (1-$($keys.Count + 1))"
                $vmIndex = 0
                if ([int]::TryParse($vmChoice, [ref]$vmIndex) -and $vmIndex -ge 1 -and $vmIndex -le $keys.Count) {
                    $selectedVmKey = $keys[$vmIndex - 1]
                    $selectedVmPath = $DefaultVMs[$selectedVmKey]
                }
            }
            "13" {
                $customPath = Read-Host "Enter absolute path to .vmx file"
                if (-not [string]::IsNullOrWhiteSpace($customPath)) {
                    if (Test-Path $customPath) {
                        $selectedVmKey = "Custom VM"
                        $selectedVmPath = Resolve-Path $customPath
                    } else {
                        Write-Host "Path not found. No changes made." -ForegroundColor Red
                        Start-Sleep -Seconds 2
                    }
                }
            }
            "14" {
                Write-Host "Goodbye!" -ForegroundColor Green
                return
            }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }

        if ($choice -match '^[1-9]$|^10$|^11$') {
            Write-Host "`nPress any key to return to menu..." -ForegroundColor Gray
            [void]$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

# ---------------------------------------------------------
# Main Entry Point
# ---------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($Action)) {
    Show-InteractiveMenu
} else {
    if ($Action -eq "list") {
        Invoke-VmrunCommand "list"
    } else {
        $resolvedPath = Resolve-VmPath $VmNameOrPath
        Invoke-VmrunCommand $Action $resolvedPath $Mode
    }
}
