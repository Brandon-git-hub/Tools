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
# Advanced Commands Sub-Menu
# ---------------------------------------------------------
function Show-AdvancedMenu {
    param (
        [string]$VmKey,
        [string]$VmPath
    )

    while ($true) {
        Clear-Host
        Write-Host "=========================================" -ForegroundColor Yellow
        Write-Host "         Advanced / Other Commands       " -ForegroundColor Yellow
        Write-Host "=========================================" -ForegroundColor Yellow
        Write-Host "Active VM: $VmKey" -NoNewline
        Write-Host " ($VmPath)" -ForegroundColor DarkGray
        Write-Host "-----------------------------------------"
        Write-Host "1.  Start VM (gui - Windowed)"
        Write-Host "2.  Stop VM (hard - Power Off)"
        Write-Host "3.  Reset VM (soft)"
        Write-Host "4.  Reset VM (hard)"
        Write-Host "5.  Suspend VM (hard)"
        Write-Host "6.  Pause VM"
        Write-Host "7.  Resume VM"
        Write-Host "8.  Return to Main Menu"
        Write-Host "========================================="

        $advChoice = Read-Host "Enter your choice (1-8)"

        switch ($advChoice) {
            "1" { Invoke-VmrunCommand "start" $VmPath "gui" }
            "2" { Invoke-VmrunCommand "stop" $VmPath "hard" }
            "3" { Invoke-VmrunCommand "reset" $VmPath "soft" }
            "4" { Invoke-VmrunCommand "reset" $VmPath "hard" }
            "5" { Invoke-VmrunCommand "suspend" $VmPath "hard" }
            "6" { Invoke-VmrunCommand "pause" $VmPath }
            "7" { Invoke-VmrunCommand "unpause" $VmPath }
            "8" { return }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
                continue
            }
        }

        if ($advChoice -match '^[1-7]$') {
            Write-Host "`nPress any key to return to Advanced Menu..." -ForegroundColor Gray
            [void]$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
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
        Write-Host "2.  Suspend VM (soft)"
        Write-Host "3.  Stop VM (soft - Graceful Shutdown)"
        Write-Host "4.  List all running VMs"
        Write-Host "5.  Choose/Switch default VM"
        Write-Host "6.  Enter custom .vmx path"
        Write-Host "7.  Advanced / Other commands"
        Write-Host "8.  Exit"
        Write-Host "========================================="
        
        $choice = Read-Host "Enter your choice (1-8)"
        
        switch ($choice) {
            "1"  { Invoke-VmrunCommand "start" $selectedVmPath "nogui" }
            "2"  { Invoke-VmrunCommand "suspend" $selectedVmPath "soft" }
            "3"  { Invoke-VmrunCommand "stop" $selectedVmPath "soft" }
            "4"  { Invoke-VmrunCommand "list" }
            "5"  {
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
            "6" {
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
            "7" {
                Show-AdvancedMenu $selectedVmKey $selectedVmPath
            }
            "8" {
                Write-Host "Goodbye!" -ForegroundColor Green
                return
            }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }

        if ($choice -match '^[1-4]$') {
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
