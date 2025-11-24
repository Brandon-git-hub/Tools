@echo off

call conda activate rpc_tool

if "%CONDA_DEFAULT_ENV%"=="rpc_tool" (
    echo.
    echo ** Conda Eviroment 'rpc_tool' activate Success! Start Python scrpt...
    echo.
    
    python dump_data_tool.py
    
    echo.
    echo ** Python Scrpt run finished.
) else (
    echo.
    echo ** Error: Conda Eviroment 'rpc_tool' activate failed
)

pause