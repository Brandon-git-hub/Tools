@echo off
cd C:\Users\brandon_wu\Documents\PersonalDrive

echo Activating conda environment...
call conda activate gemini-cli 2> error.log
if %errorlevel% neq 0 (
    echo Failed to activate conda environment. See error.log for details.
    goto end
)

echo Starting Gemini CLI...
call gemini 2>> error.log
if %errorlevel% neq 0 (
    echo Gemini CLI failed to start. See error.log for details.
)

:end
pause