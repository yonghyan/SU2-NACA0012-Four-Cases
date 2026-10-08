@echo off
setlocal

echo ===============================================
echo  SU2 Windows quick installer
echo ===============================================
echo.
echo This will download and install SU2 v8.5.0 for the current user.
echo No administrator privileges are required.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_su2_windows.ps1"

echo.
if errorlevel 1 (
    echo Installation did not complete successfully.
    echo Please read the error message above.
) else (
    echo Installation finished.
    echo Open a NEW Command Prompt, then run:
    echo   where SU2_CFD
)

echo.
pause
endlocal
