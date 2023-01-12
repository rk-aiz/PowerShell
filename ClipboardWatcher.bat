@echo off
chcp 65001 > nul

if "%~1"=="-?" (
    echo 起動オプション
    echo -AlwaysOnTop 最前面状態で起動
    echo -ShowConsole コンソール表示 (デバッグ用)
    echo -UserDebug デバッグメッセージ表示
    exit /b
)

powershell.exe -ExecutionPolicy Unrestricted -File "%~dp0%~n0.ps1"

if %ERRORLEVEL%==1 (
    cmd /k
)