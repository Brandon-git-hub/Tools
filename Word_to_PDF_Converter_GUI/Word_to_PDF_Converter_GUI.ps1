# Add the required .NET assembly to use the file dialog
Add-Type -AssemblyName System.Windows.Forms

# Create and configure the Open File Dialog
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Title = "Please select the Word file to convert"
$openFileDialog.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
$openFileDialog.Filter = "Word Files (*.docx, *.doc)|*.docx;*.doc|All Files (*.*)|*.*"
$openFileDialog.FilterIndex = 1 # Start with the Word filter selected
$openFileDialog.RestoreDirectory = $true

# Show the dialog and wait for the user to select a file
$result = $openFileDialog.ShowDialog()

# Check if the user clicked "OK"
if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    
    $wordFilePath = $openFileDialog.FileName
    
    # Construct the output path by changing the extension to .pdf
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($wordFilePath)
    $directory = [System.IO.Path]::GetDirectoryName($wordFilePath)
    $pdfFilePath = [System.IO.Path]::Combine($directory, "${baseName}.pdf")

    Write-Host "Reading file: $wordFilePath"
    Write-Host "Output file will be: $pdfFilePath"
    Write-Host "Please wait, starting Word for conversion..."

    # --- Word Conversion Logic ---
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0 # wdAlertsNone
    $document = $null

    try {
        $document = $word.Documents.Open($wordFilePath)
        # 17 corresponds to the wdFormatPDF file format
        $document.SaveAs($pdfFilePath, 17)
        Write-Host "Conversion successful! File saved to:" -ForegroundColor Green
        Write-Host $pdfFilePath -ForegroundColor Green

        $openFile = Read-Host "Do you want to open the converted PDF file? (Y/N)"
        if ($openFile -eq "Y" -or $openFile -eq "y") {
            Start-Process -FilePath $pdfFilePath
        }
    }
    catch {
        Write-Host "An error occurred during conversion:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    finally {
        if ($document) {
            $document.Close($false)
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($document) | Out-Null
        }
        $word.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
        
        # Clean up variables and force garbage collection
        Remove-Variable word, document -ErrorAction SilentlyContinue
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
