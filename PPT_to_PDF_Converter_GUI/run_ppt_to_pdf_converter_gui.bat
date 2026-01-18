@echo off
setlocal

rem Get the directory of the current batch script. %~dp0 includes a trailing backslash.
set "scriptDir=%~dp0"

rem Define the absolute path to the PowerShell script.
set "psScriptPath=%scriptDir%PPT_to_PDF_Converter_GUI.ps1"

rem Check if the PowerShell script exists. Use quotes to handle paths with spaces.
if not exist "%psScriptPath%" (
    echo.
    echo Error: The PowerShell script 'PPT_to_PDF_Converter_GUI.ps1' was not found.
    echo Please make sure it is in the same folder as this batch file.
    echo.
    echo Expected to find it at this location:
    echo %psScriptPath%
    echo.
    pause
    goto :eof
)

rem Execute the PowerShell script.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%psScriptPath%"

endlocal
