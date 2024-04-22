@echo off

chcp 932 > nul

start /wait /b "%~n0" powershell.exe -ExecutionPolicy RemoteSigned -File "%~dp0%~n0.ps1" %*

if %errorlevel% neq 0 pause