$VMRUN_PATH = "C:\Program Files\VMware\VMware Workstation\vmrun.exe"
$VM_PATH = "$env:USERPROFILE\Documents\Virtual Machines\Ubuntu 64-bit\Ubuntu 64-bit.vmx"

Write-Host "Listing VMs..." -ForegroundColor Cyan

& $VMRUN_PATH list

Write-Host "VM listing complete." -ForegroundColor Green

Start-Sleep -Seconds 3