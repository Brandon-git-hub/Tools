$VMRUN_PATH = "C:\Program Files\VMware\VMware Workstation\vmrun.exe"
$VM_PATH = "$env:USERPROFILE\Documents\Virtual Machines\Ubuntu 64-bit\Ubuntu 64-bit.vmx"

Write-Host "Sending power off signal to VM..." -ForegroundColor Cyan

& $VMRUN_PATH -T ws stop $VM_PATH hard

Write-Host "VM has been powered off." -ForegroundColor Green

Start-Sleep -Seconds 3