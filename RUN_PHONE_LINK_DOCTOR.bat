@echo off
setlocal
cd /d "%~dp0"
set "SCRIPT=%~dp0scripts\PhoneLink-Bluetooth-Doctor.ps1"

if not exist "%SCRIPT%" (
  echo Missing script:
  echo %SCRIPT%
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%SCRIPT%"
exit /b %ERRORLEVEL%
