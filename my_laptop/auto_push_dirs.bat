@echo off
setlocal

set DIR1=C:\Users\User\Documents\Tools
set DIR2=C:\Users\User\Documents\Docs
set DIR3=C:\Users\User\Documents\Blog

echo [INFO] 執行 %DIR1%\auto_git_push.bat
pushd %DIR1%
call "%DIR1%\auto_git_push.bat"
popd

echo [INFO] 執行 %DIR2%\auto_git_push.bat
pushd %DIR2%
call "%DIR2%\auto_git_push.bat"
popd

echo [INFO] 執行 %DIR3%\blog_push.bat
pushd %DIR3%
call "%DIR3%\blog_push.bat"
popd

echo [INFO] 全部執行完成
pause
endlocal
