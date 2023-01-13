@echo off
chcp 65001 > nul

<<<<<<< HEAD
powershell.exe -ExecutionPolicy Unrestricted -File "%~dp0%~n0.ps1"
=======
powershell.exe -ExecutionPolicy Unrestricted -File "%~dp0%~n0.ps1" -Wait
>>>>>>> c92ea709080b7e711588d712a8c51de8fe73f454

if %ERRORLEVEL%==1 (
    cmd /k
)