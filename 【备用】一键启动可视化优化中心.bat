@echo off
chcp 65001 >nul
title Universal Game Optimizer Pro Visual Launcher (Fallback)
cd /d "%~dp0"

:: 检查是否具备管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [i] 正在请求管理员权限以启动可视化优化大师...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo [i] 正在以管理员模式启动可视化优化中心...
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0GameOptimizer_GUI.ps1"
exit /b
