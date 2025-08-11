@echo off
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path 'O:\PADAUK_IDE' -Recurse -File -Include *.sln,*.vcxproj,*.vcproj,*.dsw,*.dsp,*.mak |  Select-Object FullName, LastWriteTime | Format-Table -AutoSize"
pause
