@echo off
setlocal

echo ===============================================
echo  SU2 Windows environment setup
echo ===============================================
echo.
echo This script does NOT download SU2.
echo Please download and extract SU2 inside this repository first.
echo It will only configure SU2_RUN and the user Path.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_su2_windows.ps1"

echo.
if errorlevel 1 (
    echo Environment setup did not complete successfully.
    echo Please read the message above.
) else (
    echo Environment setup finished.
    echo Open a NEW Command Prompt, then run:
    echo   echo %%SU2_RUN%%
    echo   where SU2_CFD
    echo   SU2_CFD
)

echo.
pause
endlocal
