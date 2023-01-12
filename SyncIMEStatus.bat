@echo off
chcp 65001 > nul

if "%~1"=="-?" (
    echo -IgnoreZenHan : 全角/半角キー無効
    echo -Disable : 無効状態で起動
    echo -ShowConsole : コンソール表示
    exit /b
)

powershell.exe -ExecutionPolicy Unrestricted -File "%~dp0%~n0.ps1" -IgnoreZenHan

if %ERRORLEVEL%==1 (
    cmd /k
)