# ==== USB Write-Block Diagnostic Tool ====
$report = [ordered]@{}

# 1) Registry: StorageDevicePolicies\WriteProtect
$reg1 = 'HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies'
try {
    $rp = Get-ItemProperty -Path $reg1 -ErrorAction Stop
    $report['Registry_WriteProtect'] = @{
        Key   = $reg1
        Value = $rp.WriteProtect
        Note  = if ($rp.WriteProtect -eq 1) {'WriteProtect=1 -> Write blocked by registry'} else {'Not set or 0 -> Not registry based'}
    }
} catch {
    $report['Registry_WriteProtect'] = @{
        Key   = $reg1
        Value = $null
        Note  = 'Key not found -> likely not registry based (could be GPO or DLP)'
    }
}

# 2) GPO related keys for Removable Storage Access
$gpoPaths = @(
  'HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices',
  'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions',
  'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
)
$gpoFindings = @()
foreach ($p in $gpoPaths) {
  if (Test-Path $p) {
    $vals = (Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
      try { Get-ItemProperty -Path $_.PsPath -ErrorAction Stop } catch {}
    }) + @(try { Get-ItemProperty -Path $p -ErrorAction Stop } catch {})
    foreach ($v in $vals) {
      $props = $v.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }
      foreach ($prop in $props) {
        $gpoFindings += [pscustomobject]@{
          Path  = $v.PSPath
          Name  = $prop.Name
          Value = $prop.Value
        }
      }
    }
  }
}
$report['GPO_RemovableStorage'] = if ($gpoFindings.Count) { $gpoFindings } else { 'No obvious GPO keys found (does not mean none, could be elsewhere or DLP)' }

# 3) Current USB disks and ReadOnly flags
$usbDisks = Get-Disk | Where-Object BusType -eq 'USB'
$report['USB_Disks'] = if ($usbDisks) {
  $usbDisks | Select-Object Number, FriendlyName, OperationalStatus, IsReadOnly, IsBoot, IsSystem, PartitionStyle, Size
} else { 'No USB disks detected' }

# 4) Look for common DLP/EDR/Security agent services
$vendors = @('symantec','broadcom','dlp','forcepoint','websense','mcafee','trellix','trend','sophos','digital guardian','digitalguardian','check point','checkpoint','carbon black','crowdstrike','ens','tanium','bitdefender')
$services = Get-Service | Where-Object {
  $n = $_.Name + ' ' + $_.DisplayName
  $vendors | ForEach-Object { $n -match $_ } | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
}
$report['Security_Agent_Services_Matched'] = if ($services) {
  $services | Select-Object Status, Name, DisplayName
} else { 'No obvious DLP/EDR service matches (may still exist under different names)' }

# 5) Check loaded file system filter drivers (may block writes)
try {
  $flt = & fltmc filters 2>$null
  $report['Filter_Drivers'] = if ($LASTEXITCODE -eq 0) { $flt } else { 'Could not list filters (restricted or unavailable)' }
} catch { $report['Filter_Drivers'] = 'fltmc failed or blocked' }

# 6) Recent System log entries mentioning write protect / readonly
try {
  $ev = Get-WinEvent -LogName System -MaxEvents 200 | Where-Object {
    $_.Message -match '(write[-\s]?protect|readonly|denied)'
  }
  $report['SystemLog_WriteProtect_Recent'] = if ($ev) {
    $ev | Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message
  } else { 'No matching events in last 200 system log entries' }
} catch { $report['SystemLog_WriteProtect_Recent'] = 'Could not read system log (permissions or policy)' }

# Print report
"==== USB Write-Block Diagnostic Report ===="
$report.GetEnumerator() | ForEach-Object {
  "`n## $($_.Key)`n"
  if ($_.Value -is [System.Collections.IEnumerable] -and -not ($_.Value -is [string])) {
    $_.Value | Format-Table -AutoSize | Out-String | Write-Output
  } else {
    ($_.Value | Out-String)
  }
}
"==== End of Report ===="
