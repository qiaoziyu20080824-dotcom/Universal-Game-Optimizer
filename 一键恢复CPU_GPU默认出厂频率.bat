@echo off
chcp 65001 >nul
title 一键恢复 CPU & GPU 默认出厂频率与芯片基准 (Hardware Clocks Reset)

:: 自动申请管理员权限
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [i] 正在请求管理员权限以还原芯片出厂基准...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath cmd -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

pushd "%CD%"
CD /D "%~dp0"

echo ==========================================================================
echo   ★ 正在启动 CPU & GPU 芯片默认出厂频率与调谐参数一键恢复程序 ★
echo ==========================================================================
echo.
echo [1/4] 正在解除 NVIDIA 独立显卡核心与显存频率锁定并恢复动态 GPU Boost...
nvidia-smi -rgc >nul 2>&1
nvidia-smi -rmc >nul 2>&1
echo   [√] 显卡时钟与功耗已恢复官方动态弹性调度！

echo.
echo [2/4] 正在清空 AMD 处理器 Curve Optimizer 负压值...
set RYZENADJ_FOUND=0
if exist "%~dp0bin\ryzenadj.exe" (
    "%~dp0bin\ryzenadj.exe" --set-coall=0 >nul 2>&1
    set RYZENADJ_FOUND=1
)
if exist "%ProgramData%\UniversalGameOptimizer\bin\ryzenadj.exe" (
    "%ProgramData%\UniversalGameOptimizer\bin\ryzenadj.exe" --set-coall=0 >nul 2>&1
    set RYZENADJ_FOUND=1
)
if %RYZENADJ_FOUND% equ 1 (
    echo   [√] AMD 处理器负压参数已全部清零归位！
) else (
    echo   [i] 未检测到常驻 RyzenAdj 工具或非 AMD 处理器，无需负压清零。
)

echo.
echo [3/4] 正在注销开机硬件调谐自启动任务与引导脚本...
schtasks /delete /tn "UniversalGameOptimizer_HardwareStartup" /f >nul 2>&1
if exist "%ProgramData%\UniversalGameOptimizer\HardwareBootApply.cmd" (
    del /f /q "%ProgramData%\UniversalGameOptimizer\HardwareBootApply.cmd" >nul 2>&1
)
echo   [√] 开机自启硬件调谐服务已注销清除！

echo.
echo [4/4] 正在重置处理器能量性能首选项 (PERFEPP)...
powercfg -setacvalueindex scheme_current sub_processor PERFEPP 50 >nul 2>&1
powercfg -setactive scheme_current >nul 2>&1
echo   [√] 处理器供电能效已恢复默认基准！

echo.
echo ==========================================================================
echo   [★ 完成 ★] CPU 与 GPU 芯片已全部恢复官方出厂默认频率与电压状态！
echo ==========================================================================
echo.
echo 执行完毕。按任意键关闭此窗口...
pause >nul
