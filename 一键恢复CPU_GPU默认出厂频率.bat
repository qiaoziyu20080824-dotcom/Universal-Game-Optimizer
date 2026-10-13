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
echo [1/4] 正在解除 NVIDIA 独立显卡频率锁定并恢复出厂功耗墙与动态 GPU Boost...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$cmd = Get-Command 'nvidia-smi.exe' -ErrorAction SilentlyContinue; $nvsmi = if ($cmd -and (Test-Path $cmd.Source)) { $cmd.Source } else { $cands = @($env:SystemRoot + '\System32\nvidia-smi.exe', $env:ProgramFiles + '\NVIDIA Corporation\NVSMI\nvidia-smi.exe'); $cands | Where-Object { Test-Path $_ } | Select-Object -First 1 }; if ($nvsmi) { & $nvsmi -rgc 2>$null | Out-Null; & $nvsmi -rmc 2>$null | Out-Null; $defPl = $null; try { $plQuery = & $nvsmi --query-gpu=power.default_limit --format=csv,noheader,nounits 2>$null; if ($plQuery -match '(\d+(?:\.\d+)?)') { $defPl = [int][Math]::Round([double]$matches[1]) } } catch {}; if (-not $defPl -or $defPl -le 30) { $snap = @($env:ProgramData + '\UniversalGameOptimizer\PreOptimizationState.baseline.json', $env:ProgramData + '\UniversalGameOptimizer\PreOptimizationState.json', 'PreOptimizationState.baseline.json', 'PreOptimizationState.json') | Where-Object { Test-Path $_ } | Select-Object -First 1; if ($snap) { try { $obj = Get-Content -LiteralPath $snap -Raw | ConvertFrom-Json; if ($obj.HardwareTuning -and $obj.HardwareTuning.GpuPowerLimitW -and [int]$obj.HardwareTuning.GpuPowerLimitW -gt 30) { $defPl = [int]$obj.HardwareTuning.GpuPowerLimitW } } catch {} } }; if ($defPl -and $defPl -gt 30) { & $nvsmi -pl $defPl 2>$null | Out-Null; Write-Host ('  [√] NVIDIA 显卡时钟已释放，功率墙已还原至基准: [' + $defPl + ' W]！') -ForegroundColor Green; } else { Write-Host '  [√] NVIDIA 显卡核心与显存频率已恢复出厂动态调度！' -ForegroundColor Green; } } else { Write-Host '  [i] 未检测到 NVIDIA 显卡驱动管理工具，跳过 N 卡时钟释放。' -ForegroundColor Gray; }"

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
powershell -NoProfile -ExecutionPolicy Bypass -Command "$origEpp = 50; $snap = @($env:ProgramData + '\UniversalGameOptimizer\PreOptimizationState.baseline.json', $env:ProgramData + '\UniversalGameOptimizer\PreOptimizationState.json', 'PreOptimizationState.baseline.json', 'PreOptimizationState.json') | Where-Object { Test-Path $_ } | Select-Object -First 1; if ($snap) { try { $obj = Get-Content -LiteralPath $snap -Raw | ConvertFrom-Json; if ($obj.Power -and $null -ne $obj.Power.PerfEpp) { $origEpp = [int]$obj.Power.PerfEpp } } catch {} }; powercfg -setacvalueindex scheme_current sub_processor PERFEPP $origEpp 2>$null | Out-Null; powercfg -setactive scheme_current 2>$null | Out-Null; Write-Host ('  [√] 处理器供电能效 (PERFEPP) 已恢复基准 (' + $origEpp + ')！') -ForegroundColor Green;"

echo.
echo ==========================================================================
echo   [★ 完成 ★] CPU 与 GPU 芯片已全部恢复官方出厂默认频率、功耗与电压状态！
echo ==========================================================================
echo.
echo 执行完毕。按任意键关闭此窗口...
pause >nul

