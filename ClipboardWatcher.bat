@echo off
chcp 65001 > nul

powershell.exe -ExecutionPolicy Unrestricted -File "%~dp0%~n0.ps1"

if %ERRORLEVEL%==1 (
    cmd /k
)