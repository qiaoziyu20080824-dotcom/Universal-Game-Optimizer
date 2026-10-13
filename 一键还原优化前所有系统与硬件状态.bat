@echo off
chcp 65001 >nul
title Windows 底层优化 - 还原优化前系统与硬件原始状态 (Pre-State Restorer)

:: 自动申请管理员权限
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [i] 正在请求管理员权限以精准还原底层系统与硬件状态...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath cmd -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

pushd "%CD%"
CD /D "%~dp0"

echo ==========================================================================
echo   ★ 正在启动 Windows 底层优化状态无损精准还原大师 (100%% 恢复优化前原貌) ★
echo ==========================================================================
echo.

if exist "%~dp0Restore-PreOptimizationState.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Restore-PreOptimizationState.ps1"
) else if exist "%ProgramData%\UniversalGameOptimizer\Restore-PreOptimizationState.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ProgramData%\UniversalGameOptimizer\Restore-PreOptimizationState.ps1"
) else if exist "%~dp0Restore-PreOptimizationState-Factory.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Restore-PreOptimizationState-Factory.ps1"
) else if exist "%ProgramData%\UniversalGameOptimizer\Restore-PreOptimizationState-Factory.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ProgramData%\UniversalGameOptimizer\Restore-PreOptimizationState-Factory.ps1"
) else if exist "%~dp0Universal_Game_Optimizer_GUI\Restore-PreOptimizationState.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Universal_Game_Optimizer_GUI\Restore-PreOptimizationState.ps1"
) else (
    echo [!] 错误：未在当前目录或系统目录中找到 Restore-PreOptimizationState.ps1 还原脚本！
    echo     请确保解压了完整文件夹，或者优化曾正常生成过快照与还原脚本。
    pause
    exit /b
)

echo.
echo 还原流程结束。按任意键关闭此窗口...
pause >nul

