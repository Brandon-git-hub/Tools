$VMRUN_PATH = "C:\Program Files\VMware\VMware Workstation\vmrun.exe"
$VM_PATH = "$env:USERPROFILE\Documents\Virtual Machines\Ubuntu 64-bit\Ubuntu 64-bit.vmx"

Write-Host "Sending graceful shutdown signal to VM..." -ForegroundColor Cyan

& $VMRUN_PATH -T ws stop $VM_PATH soft

Write-Host "VM has been safely shut down." -ForegroundColor Green

Start-Sleep -Seconds 3