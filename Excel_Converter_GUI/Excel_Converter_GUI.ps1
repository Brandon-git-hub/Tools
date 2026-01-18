# Add the required .NET assembly to use the file dialog
Add-Type -AssemblyName System.Windows.Forms

# Create and configure the Open File Dialog
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Title = "Please select the Excel file to convert"
$openFileDialog.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
$openFileDialog.Filter = "Excel Files (*.xlsx, *.xls)|*.xlsx;*.xls|All Files (*.*)|*.*"
$openFileDialog.FilterIndex = 1 # Start with the Excel filter selected
$openFileDialog.RestoreDirectory = $true

# Show the dialog and wait for the user to select a file
$result = $openFileDialog.ShowDialog()

# Check if the user clicked "OK"
if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    
    $excelFilePath = $openFileDialog.FileName
    
    # Construct the output path by adding '_utf8' before the extension
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($excelFilePath)
    $directory = [System.IO.Path]::GetDirectoryName($excelFilePath)
    $csvFilePath = [System.IO.Path]::Combine($directory, "${baseName}_utf8.csv")

    Write-Host "Reading file: $excelFilePath"
    Write-Host "Output file will be: $csvFilePath"
    Write-Host "Please wait, starting Excel for conversion..."

    # --- Excel Conversion Logic ---
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $workbook = $null

    try {
        $workbook = $excel.Workbooks.Open($excelFilePath)
        # 62 corresponds to the xlCSVUTF8 file format
        $workbook.SaveAs($csvFilePath, 62)
        Write-Host "Conversion successful! File saved to:" -ForegroundColor Green
        Write-Host $csvFilePath -ForegroundColor Green
        
        $openFile = Read-Host "Do you want to open the converted CSV file? (Y/N)"
        if ($openFile -eq "Y" -or $openFile -eq "y") {
            Start-Process -FilePath $csvFilePath
        }
    }
    catch {
        Write-Host "An error occurred during conversion:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    finally {
        if ($workbook) {
            $workbook.Close($false)
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) | Out-Null
        }
        $excel.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
        
        # Clean up variables and force garbage collection
        Remove-Variable excel, workbook -ErrorAction SilentlyContinue
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
    }

} else {
    Write-Host "Operation cancelled."
}

# Keep the window open to see the result, unless running in a non-interactive shell
if ($Host.UI.RawUI.KeyAvailable -and ($Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp").VirtualKeyCode -eq 13)) {
    # If a key was pressed, it might be the Enter key from launching the script.
    # In an interactive shell, you might want to uncomment the line below.
    # Read-Host "Press Enter to exit..."
} elseif ($psISE -eq $null) {
    # If not running in the ISE, and no key was pressed, pause for the user.
    Read-Host "Process finished. Press Enter to exit..."
}
