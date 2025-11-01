@echo off
rem Enable delayed expansion for better handling, though not strictly needed here
setlocal enabledelayedexpansion

echo 1. Clearing potential interference settings (PowerShell Environment Variables)
powershell -Command "Remove-Item Env:GIT_SSH -ErrorAction SilentlyContinue; Remove-Item Env:GIT_SSH_COMMAND -ErrorAction SilentlyContinue"

echo 2. Unsetting local and global core.sshCommand configurations
git config --unset core.sshCommand
git config --global --unset core.sshCommand

echo 3. Permanently binding this repository to the specified ssh.exe and private key
rem Note: This command applies only to the current local Git repository
git config core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe -o IdentitiesOnly=yes -i C:/Users/brandon_wu/.ssh/id_ed25519"

if errorlevel 1 (
    echo.
    echo Execution failed! Please check if Git is installed and paths are correct.
) else (
    echo.
    echo Git SSH setup completed successfully!
    echo    This Repo is now bound to key: C:/Users/brandon_wu/.ssh/id_ed25519
)

pause
endlocal