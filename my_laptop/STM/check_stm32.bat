@echo off

echo ============================================
echo   STM32 Device Check via CubeProgrammer
echo ============================================
echo.

set CUBEPROG="C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe"
%CUBEPROG% -c port=SWD freq=4000 > device_info.txt
type device_info.txt

echo.

pause
