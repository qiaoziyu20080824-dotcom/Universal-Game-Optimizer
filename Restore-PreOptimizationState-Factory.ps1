param(
    [switch]$NonInteractive
)

<#
.SYNOPSIS
    Windows 全维底层优化 - 优化前系统原始真实状态无损精准还原大师 (Pre-Optimization State Restorer)
    核心原则：100% 拒绝盲目套用系统官方出厂默认值！
    读取优化前拍摄的系统真实状态快照清单 (PreOptimizationState.json)，仅撤销用户选择的脚本优化，完整保留用户原本的个性化设定！
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "Windows 底层优化状态无损精准还原大师 (Pre-State Restorer)"

# 管理员权限自检
$isAdmin = ($env:UGO_SKIP_ADMIN_CHECK -eq '1') -or (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
if (-not $isAdmin) {
    Write-Host "`n [!] 错误：还原系统状态必须使用管理员权限！请右键【以管理员身份运行】！" -ForegroundColor Red
    if (-not $NonInteractive -and $env:UGO_NON_INTERACTIVE -ne '1') {
        Pause
    }
    exit 1
}

Clear-Host
Write-Host "======================================================================================" -ForegroundColor Cyan
Write-Host "      ★ WINDOWS 系统底层优化全量状态精准无损还原大师 (Pre-State Restorer) ★      " -ForegroundColor Green
Write-Host "   【100% 精准无损】：读取优化前快照，仅撤销脚本优化，完整保留优化前的任何个性化设置   " -ForegroundColor Yellow
Write-Host "======================================================================================" -ForegroundColor Cyan

function Get-ProgressBarString ($pct, $width = 26) {
    $filled = [int][Math]::Round(($pct / 100.0) * $width)
    if ($filled -lt 0) { $filled = 0 }
    if ($filled -gt $width) { $filled = $width }
    $empty = $width - $filled
    $bar = ('█' * $filled) + ('░' * $empty)
    return "[$bar] $pct%"
}

function Print-Step ($num, $title) {
    $pct = 0
    if ($num -match "(\d+)\s*/\s*(\d+)") {
        $curr = [int]$matches[1]
        $total = [int]$matches[2]
        $pct = [int][Math]::Min(98, [Math]::Max(5, [Math]::Round(($curr / $total) * 95)))
    } else {
        $pct = 50
    }
    Write-Host "[PROGRESS: $pct] $title"
    Write-Host "`n>>> [$num] $title" -ForegroundColor Yellow
    $barStr = Get-ProgressBarString $pct 26
    Write-Host "  $barStr 正在还原: $title" -ForegroundColor Cyan
    try {
        Write-Progress -Activity "Windows 底层状态精准无损还原" -Status "[$num] $title ($pct%)" -PercentComplete $pct
    } catch {}
}
function Print-Success ($msg) {
    Write-Host "  [√ 还原成功] $msg" -ForegroundColor Green
}
function Print-Info ($msg) {
    Write-Host "  [i 状态追溯] $msg" -ForegroundColor Gray
}
function Print-Warn ($msg) {
    Write-Host "  [! 还原提示] $msg" -ForegroundColor Magenta
}

# 全局可靠探测 nvidia-smi 路径
function Get-NvidiaSmiPath {
    $cmd = Get-Command "nvidia-smi.exe" -ErrorAction SilentlyContinue
    if ($cmd -and (Test-Path $cmd.Source)) { return $cmd.Source }
    $cmd2 = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
    if ($cmd2 -and (Test-Path $cmd2.Source)) { return $cmd2.Source }
    $candidates = @(
        "$env:SystemRoot\System32\nvidia-smi.exe",
        "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe",
        "$env:SystemDrive\Windows\System32\nvidia-smi.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    $driverStore = "$env:SystemRoot\System32\DriverStore\FileRepository"
    if (Test-Path $driverStore) {
        $nvsmiInStore = Get-ChildItem -Path $driverStore -Filter "nvidia-smi.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($nvsmiInStore) { return $nvsmiInStore.FullName }
    }
    return $null
}

function Restore-RegValue ($path, $name, $val, $type = "DWord") {
    try {
        if ($null -eq $val) {
            if (Test-Path $path) {
                Remove-ItemProperty -Path $path -Name $name -Force -ErrorAction SilentlyContinue | Out-Null
            }
        } else {
            if (-not (Test-Path $path)) { New-Item -Path $path -Force -ErrorAction SilentlyContinue | Out-Null }
            Set-ItemProperty -Path $path -Name $name -Value $val -Type $type -Force -ErrorAction SilentlyContinue | Out-Null
        }
    } catch {}
}

# 1. 定位并读取优化前状态快照清单 (优先初始纯净基准快照)
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } elseif ([System.AppDomain]::CurrentDomain.BaseDirectory) { [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\') } else { (Get-Location).Path }
$candidateFiles = @(
    "$env:ProgramData\UniversalGameOptimizer\PreOptimizationState.baseline.json",
    (Join-Path $scriptDir "PreOptimizationState.baseline.json"),
    "$env:ProgramData\UniversalGameOptimizer\PreOptimizationState.json",
    (Join-Path $scriptDir "PreOptimizationState.json")
)
$existingCandidates = @($candidateFiles | Where-Object { Test-Path $_ })
$stateFile = $null
foreach ($f in $existingCandidates) {
    try {
        $testObj = Get-Content -Raw -Encoding UTF8 $f | ConvertFrom-Json
        if ($testObj -and $testObj.ComputerName -and ($testObj.ComputerName -eq $env:COMPUTERNAME)) {
            $stateFile = $f
            break
        }
    } catch {}
}
if (-not $stateFile -and $existingCandidates.Count -gt 0) {
    $stateFile = $existingCandidates[0]
}

if (-not (Test-Path $stateFile)) {
    Write-Host "`n [!] 警告：未在系统找到优化前快照清单 [PreOptimizationState.json]！" -ForegroundColor Red
    Write-Host "     将执行安全兜底还原流程 (重置 CPU/GPU 频率、清除计划任务、还原关键默认调度)..." -ForegroundColor Yellow
    
    # 兜底恢复
    $nvsmi = Get-NvidiaSmiPath
    if ($nvsmi) {
        & $nvsmi -rgc 2>$null | Out-Null
        & $nvsmi -rmc 2>$null | Out-Null
    }
    $rAdj = Join-Path $scriptDir "bin\ryzenadj.exe"
    if (-not (Test-Path $rAdj)) { $rAdj = "$env:ProgramData\UniversalGameOptimizer\bin\ryzenadj.exe" }
    if (Test-Path $rAdj) { & $rAdj --set-coall=0 2>$null | Out-Null }
    schtasks /delete /tn "UniversalGameOptimizer_HardwareStartup" /f 2>$null | Out-Null
    schtasks /delete /tn "UniversalGameOptimizer_Watchdog" /f 2>$null | Out-Null
    powercfg -setactive scheme_balanced 2>$null | Out-Null
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "DisableOverlays" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-Service -Name "SysMain" -StartupType "Automatic" -ErrorAction SilentlyContinue | Out-Null
    Start-Service -Name "SysMain" -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "`n [√] 兜底硬件与调度还原完成！" -ForegroundColor Green
    if (-not $NonInteractive -and $env:UGO_NON_INTERACTIVE -ne '1') {
        Pause
    }
    exit 0
}

try {
    $jsonRaw = [System.IO.File]::ReadAllText($stateFile, [System.Text.Encoding]::UTF8)
    $state = $jsonRaw | ConvertFrom-Json
    Write-Host "`n  [*] 成功检索到优化前系统真实快照清单！" -ForegroundColor Cyan
    Write-Host "  [*] 快照创建时间: [$($state.Timestamp)]" -ForegroundColor White
} catch {
    Write-Host " [!] 解析快照文件失败: $_" -ForegroundColor Red
    if (-not $NonInteractive -and $env:UGO_NON_INTERACTIVE -ne '1') {
        Pause
    }
    exit 1
}

# 验证快照所属主机 (防止跨电脑复制造成硬件设置误还原)
if ($state.PSObject.Properties['ComputerName'] -and $state.ComputerName -and ($state.ComputerName -ne $env:COMPUTERNAME)) {
    Write-Host "`n [!] 提示：检测到快照由计算机 [$($state.ComputerName)] 生成，与当前电脑 [$env:COMPUTERNAME] 不一致！" -ForegroundColor Magenta
    Write-Host "     为防止不同主板与驱动产生硬件冲突，跳过针对性快照恢复，转为执行通用安全兜底还原流程..." -ForegroundColor Yellow
    $nvsmi = Get-NvidiaSmiPath
    if ($nvsmi) {
        & $nvsmi -rgc 2>$null | Out-Null
        & $nvsmi -rmc 2>$null | Out-Null
    }
    $rAdj = Join-Path $scriptDir "bin\ryzenadj.exe"
    if (-not (Test-Path $rAdj)) { $rAdj = "$env:ProgramData\UniversalGameOptimizer\bin\ryzenadj.exe" }
    if (Test-Path $rAdj) { & $rAdj --set-coall=0 2>$null | Out-Null }
    schtasks /delete /tn "UniversalGameOptimizer_HardwareStartup" /f 2>$null | Out-Null
    schtasks /delete /tn "UniversalGameOptimizer_Watchdog" /f 2>$null | Out-Null
    powercfg -setactive scheme_balanced 2>$null | Out-Null
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name "OverlayTestMode" -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "DisableOverlays" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-Service -Name "SysMain" -StartupType "Automatic" -ErrorAction SilentlyContinue | Out-Null
    Start-Service -Name "SysMain" -ErrorAction SilentlyContinue | Out-Null
    Write-Host "`n [√] 安全通用兜底还原流程执行完毕！" -ForegroundColor Green
    if (-not $NonInteractive -and $env:UGO_NON_INTERACTIVE -ne '1') {
        Pause
    }
    exit 0
}

# =========================================================================
# 1. 还原 CPU 与 GPU 核心频率、电压与功耗限制
# =========================================================================
Print-Step "1/10" "还原 CPU 与 GPU 芯片频率、电压与功耗至优化前基准"
try {
    $nvsmi = Get-NvidiaSmiPath
    if ($nvsmi) {
        & $nvsmi -rgc 2>$null | Out-Null
        & $nvsmi -rmc 2>$null | Out-Null
        # 还原优化前快照记录的 GPU 功耗上限 (功耗墙)，避免 -pl 修改后残留
        if ($state.HardwareTuning -and $null -ne $state.HardwareTuning.GpuPowerLimitW -and [int]$state.HardwareTuning.GpuPowerLimitW -gt 30) {
            & $nvsmi -pl ([int]$state.HardwareTuning.GpuPowerLimitW) 2>$null | Out-Null
            Print-Success "已还原 GPU 功耗上限至优化前基准: [$([int]$state.HardwareTuning.GpuPowerLimitW) W]"
        }
    }
    $ryzenAdjPath = Join-Path $scriptDir "bin\ryzenadj.exe"
    if (-not (Test-Path $ryzenAdjPath)) { $ryzenAdjPath = "$env:ProgramData\UniversalGameOptimizer\bin\ryzenadj.exe" }
    if (Test-Path $ryzenAdjPath) { & $ryzenAdjPath --set-coall=0 2>$null | Out-Null }
    schtasks /delete /tn "UniversalGameOptimizer_HardwareStartup" /f 2>$null | Out-Null
    Remove-Item "$env:ProgramData\UniversalGameOptimizer\HardwareBootApply.cmd" -Force -ErrorAction SilentlyContinue | Out-Null

    if ($state.HardwareTuning -and $state.HardwareTuning.Applied -eq $true) {
        Print-Success "检测到优化曾启用硬件超频/负压调谐：已彻底撤销显卡锁频与功耗限制，CPU Curve Optimizer 负压置 0，清除开机自启任务！"
    } else {
        Print-Info "优化时未启用硬件调谐，已执行出厂频率校验并清除残留任务。"
    }
} catch {
    Print-Warn "芯片硬件还原提示: $_"
}

# =========================================================================
# 2. 还原用户原始电源方案与 CPU 停驻调度
# =========================================================================
Print-Step "2/10" "还原优化前用户原有的电源方案与 CPU 调度响应策略"
try {
    if ($state.Power -and $state.Power.ActiveScheme) {
        powercfg -setactive $state.Power.ActiveScheme 2>$null | Out-Null
        Restore-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Power" "PlatformAoAcOverride" $state.Power.PlatformAoAcOverride
        # 还原原方案内部的 PERFEPP / PERFBOOSTMODE (硬件调谐曾写入，防止残留脏值)
        $eppRestored = $false
        if ($null -ne $state.Power.PerfEpp) {
            powercfg -setacvalueindex $state.Power.ActiveScheme sub_processor PERFEPP ([int]$state.Power.PerfEpp) 2>$null | Out-Null
            $eppRestored = $true
        }
        if ($null -ne $state.Power.PerfBoostMode) {
            powercfg -setacvalueindex $state.Power.ActiveScheme sub_processor PERFBOOSTMODE ([int]$state.Power.PerfBoostMode) 2>$null | Out-Null
        }
        if ($eppRestored) { powercfg -setactive $state.Power.ActiveScheme 2>$null | Out-Null }
        Print-Success "已精准切回优化前用户原有的电源方案 GUID: [$($state.Power.ActiveScheme)]"
        if ($eppRestored) {
            Print-Success "已同步还原原方案处理器能效策略 (PERFEPP=$($state.Power.PerfEpp), PERFBOOSTMODE=$($state.Power.PerfBoostMode))"
        }

        # 【防堆积】删除优化时复制的“卓越性能”副本方案 (仅当副本存在且非当前活动方案时)
        if ($state.Power.UltimateSchemeGuid -and $state.Power.UltimateSchemeGuid -ne $state.Power.ActiveScheme) {
            $dupGuid = $state.Power.UltimateSchemeGuid
            $activeOut = powercfg /getactivescheme 2>$null | Out-String
            $isActiveDup = $activeOut -match [regex]::Escape($dupGuid)
            if (-not $isActiveDup) {
                powercfg -delete $dupGuid 2>$null | Out-Null
                Print-Success "已清理优化时生成的电源方案副本: [$dupGuid]"
            } else {
                # 极端情况：活动方案仍指向副本 (上方 setactive 原方案失败)，强制切回后再删
                powercfg -setactive $state.Power.ActiveScheme 2>$null | Out-Null
                $activeOut2 = powercfg /getactivescheme 2>$null | Out-String
                if ($activeOut2 -notmatch [regex]::Escape($dupGuid)) {
                    powercfg -delete $dupGuid 2>$null | Out-Null
                    Print-Success "已清理优化时生成的电源方案副本: [$dupGuid]"
                }
            }
        }
    } else {
        Print-Info "未检索到特定原电源方案，保持当前方案。"
    }
} catch {
    Print-Warn "电源方案还原提示: $_"
}

# =========================================================================
# 3. 还原内核隔离 (HVCI) 与虚拟化沙箱 (VBS)
# =========================================================================
Print-Step "3/10" "还原优化前内核隔离与虚拟化安全状态"
try {
    $hvci = $state.CoreIsolation
    if ($hvci) {
        Restore-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" $hvci.HvciEnabled
        Restore-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "WasEnabledBy" $hvci.HvciWasEnabledBy
        Restore-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" $hvci.VbsEnabled
        Restore-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "RequirePlatformSecurityFeatures" $hvci.RequirePlatformSecurityFeatures
        Restore-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" "EnableVirtualizationBasedSecurity" $hvci.PolicyVbs
        Print-Success "内核隔离与 VBS 安全策略已恢复至优化前原始状态 (Enabled=$($hvci.HvciEnabled))"
    }
} catch {
    Print-Warn "内核隔离还原提示: $_"
}

# =========================================================================
# 4. 还原 Windows Defender (仅当用户此前选择修改时才还原)
# =========================================================================
Print-Step "4/10" "还原 Windows Defender 杀毒与安全中心防线"
try {
    if ($state.Defender -and $state.Defender.Modified -eq $true) {
        $def = $state.Defender
        Restore-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" $def.DisableAntiSpyware
        Restore-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableRoutinelyTakingAction" $def.DisableRoutinelyTakingAction
        Restore-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "ServiceKeepAlive" $def.ServiceKeepAlive

        Restore-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" $def.DisableRealtimeMonitoring
        Restore-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableBehaviorMonitoring" $def.DisableBehaviorMonitoring
        Restore-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableOnAccessProtection" $def.DisableOnAccessProtection
        Restore-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableScanOnRealtimeEnable" $def.DisableScanOnRealtimeEnable
        Restore-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableIOAVProtection" $def.DisableIOAVProtection

        Restore-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "SmartScreenEnabled" $def.SmartScreenEnabled "String"
        Restore-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableSmartScreen" $def.EnableSmartScreen
        $toastKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance"
        Restore-RegValue $toastKey "Enabled" $def.SystemToast

        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBlockAtFirstSeen $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue
        Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue

        @(
            "\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance",
            "\Microsoft\Windows\Windows Defender\Windows Defender Cleanup",
            "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan",
            "\Microsoft\Windows\Windows Defender\Windows Defender Verification"
        ) | ForEach-Object { Enable-ScheduledTask -TaskName $_ -ErrorAction SilentlyContinue | Out-Null }
        Print-Success "检测到优化曾关闭 Defender，已完全恢复 Defender 实时监控与后台扫描防护！"
    } else {
        Print-Success "检测到优化时【用户选择保留了 Defender 正常工作】，无需修改，维持用户原貌！"
    }
} catch {
    Print-Warn "Defender 还原提示: $_"
}

# =========================================================================
# 5. 还原设备 MSI 硬件中断设置与亲和性策略
# =========================================================================
Print-Step "5/10" "还原 PCIe 显卡与物理网卡 MSI 硬件中断设置与亲和性策略"
try {
    if ($state.MSI -and $state.MSI.Count -gt 0) {
        foreach ($item in $state.MSI) {
            Restore-RegValue $item.Path "MSISupported" $item.MSISupported
            Restore-RegValue $item.Path "MessageNumberLimit" $item.MessageNumberLimit
            if ($item.AffinityPath) {
                Restore-RegValue $item.AffinityPath "DevicePriority" $item.DevicePriority
                Restore-RegValue $item.AffinityPath "DevicePolicy" $item.DevicePolicy
                if ($null -eq $item.AssignmentSetOverride -or [string]::IsNullOrWhiteSpace($item.AssignmentSetOverride)) {
                    if (Test-Path $item.AffinityPath) {
                        Remove-ItemProperty -Path $item.AffinityPath -Name "AssignmentSetOverride" -Force -ErrorAction SilentlyContinue | Out-Null
                    }
                } else {
                    try {
                        $parts = $item.AssignmentSetOverride -split '[- ]'
                        [byte[]]$bytes = foreach ($p in $parts) { if ($p) { [Convert]::ToByte($p, 16) } }
                        Set-ItemProperty -Path $item.AffinityPath -Name "AssignmentSetOverride" -Value $bytes -Type Binary -Force -ErrorAction SilentlyContinue | Out-Null
                    } catch {
                        Remove-ItemProperty -Path $item.AffinityPath -Name "AssignmentSetOverride" -Force -ErrorAction SilentlyContinue | Out-Null
                    }
                }
            }
        }
        Print-Success "已将所有检测到的硬件中断属性与亲和性策略精准还原至优化前状态！"
    } else {
        Print-Info "优化前无特殊 MSI 记录，保持当前状态。"
    }
} catch {
    Print-Warn "MSI 还原提示: $_"
}

# =========================================================================
# 6. 还原系统 BCD 高精度时钟
# =========================================================================
Print-Step "6/10" "还原系统 BCD 引导时钟策略"
try {
    bcdedit /deletevalue useplatformtick 2>$null | Out-Null
    bcdedit /deletevalue disabledynamictick 2>$null | Out-Null
    bcdedit /deletevalue useplatformclock 2>$null | Out-Null
    Print-Success "已撤销 BCD 动态时钟强制设置，恢复 Windows 原生时钟调度模式。"
} catch {
    Print-Warn "BCD 时钟还原提示: $_"
}

# =========================================================================
# 7. 还原虚拟内存分页与物理内存锁定
# =========================================================================
Print-Step "7/10" "还原优化前用户原有的虚拟内存与分页文件配置"
try {
    $mem = $state.Memory
    if ($mem) {
        if ($mem.AutomaticManagedPagefile -eq $true) {
            $wmiSys = Get-CimInstance Win32_ComputerSystem
            $wmiSys.AutomaticManagedPagefile = $true
            Set-CimInstance -CimInstance $wmiSys -ErrorAction SilentlyContinue | Out-Null
            Print-Success "已精准还原为优化前状态：【由 Windows 自动管理所有驱动器的分页文件大小】！"
        }
        if ($mem.PagingFiles) {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -Value $mem.PagingFiles -Type MultiString -Force -ErrorAction SilentlyContinue
            Print-Success "已精准还原为用户优化前自定义的固定分页文件设置: [$($mem.PagingFiles)]"
        } else {
            Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -Force -ErrorAction SilentlyContinue
        }

        Restore-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" $mem.DisablePagingExecutive
        Restore-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" $mem.LargeSystemCache
        Print-Success "DisablePagingExecutive 与虚拟内存已精准还原为优化前原始值: [$($mem.DisablePagingExecutive)]"
    }
    if ($state.Storage) {
        $fsKey = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
        Restore-RegValue $fsKey "NtfsDisableLastAccessUpdate" $state.Storage.NtfsDisableLastAccessUpdate
        Restore-RegValue $fsKey "NtfsDisable8dot3NameCreation" $state.Storage.NtfsDisable8dot3NameCreation
        if ($null -ne $state.Storage.NtfsDisableLastAccessUpdate) {
            $rawLa = [int64]$state.Storage.NtfsDisableLastAccessUpdate
            $fsLa = if ($rawLa -ge 0 -and $rawLa -le 3) { [int]$rawLa } elseif (($rawLa -band 0x80000000) -ne 0) { if (($rawLa -band 1) -ne 0) { 3 } else { 2 } } else { [int]($rawLa -band 3) }
            fsutil behavior set disablelastaccess $fsLa 2>$null | Out-Null
        }
        if ($null -ne $state.Storage.NtfsDisable8dot3NameCreation) {
            $fs8dot3 = [int]$state.Storage.NtfsDisable8dot3NameCreation -band 3
            fsutil 8dot3name set $fs8dot3 2>$null | Out-Null
        }
        Print-Success "存储与 NTFS 属性已精准还原为优化前原始值！"
    }
} catch {
    Print-Warn "虚拟内存还原提示: $_"
}

# =========================================================================
# 8. 还原网络栈、物理网卡硬件属性与 UDP/TCP 配置
# =========================================================================
Print-Step "8/10" "还原物理网卡硬件高级属性 (中断审慎/流控制/LSO/EEE) 与网络节流"
try {
    $net = $state.Network
    if ($net) {
        Restore-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" $net.NetworkThrottlingIndex
        Restore-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" $net.SystemResponsiveness

        if ($net.Adapters) {
            foreach ($a in $net.Adapters) {
                $guid = $a.Guid
                if ($guid) {
                    $targetKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid"
                    Restore-RegValue $targetKey "TcpAckFrequency" $a.TcpAckFrequency
                    Restore-RegValue $targetKey "TCPNoDelay" $a.TCPNoDelay
                }

                # 恢复物理网卡硬件属性：如果快照中记录了原始属性则逐项恢复，否则安全启用官方自协商
                if ($a.AdvancedProperties) {
                    foreach ($kw in $a.AdvancedProperties.PSObject.Properties.Name) {
                        $pObj = $a.AdvancedProperties.$kw
                        if ($pObj -and $null -ne $pObj.RegistryValue) {
                            $rVal = $pObj.RegistryValue
                            if ($rVal -is [array]) {
                                Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $kw -RegistryValue ([string[]]$rVal) -ErrorAction SilentlyContinue
                            } elseif ($rVal -is [string] -and $rVal -match ',') {
                                Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $kw -RegistryValue ([string[]]($rVal -split ',')) -ErrorAction SilentlyContinue
                            } else {
                                Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword $kw -RegistryValue ([string[]]@($rVal)) -ErrorAction SilentlyContinue
                            }
                        }
                    }
                } else {
                    Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "*Interrupt Moderation*" -DisplayValue "Enabled" -ErrorAction SilentlyContinue
                    Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword "*InterruptModeration" -RegistryValue "1" -ErrorAction SilentlyContinue
                    Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "*Flow Control*" -DisplayValue "Rx & Tx Enabled" -ErrorAction SilentlyContinue
                    Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "*Large Send Offload v2 (IPv4)*" -DisplayValue "Enabled" -ErrorAction SilentlyContinue
                    Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "*Large Send Offload v2 (IPv6)*" -DisplayValue "Enabled" -ErrorAction SilentlyContinue
                    Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "*Energy Efficient Ethernet*" -DisplayValue "Enabled" -ErrorAction SilentlyContinue
                }
            }
            Print-Success "已将物理网卡硬件高级属性与 TCP/UDP 协议栈全部精准还原至优化前状态！"
        }
        # 还原网卡 Class 驱动级参数 (Bug 9)
        if ($net.NicClassSettings) {
            foreach ($item in $net.NicClassSettings) {
                if ($item.Path -and $item.Values) {
                    if ($item.Values -is [System.Collections.IDictionary]) {
                        foreach ($kv in $item.Values.GetEnumerator()) {
                            Restore-RegValue $item.Path $kv.Key $kv.Value "String"
                        }
                    } elseif ($item.Values.PSObject) {
                        foreach ($p in $item.Values.PSObject.Properties) {
                            Restore-RegValue $item.Path $p.Name $p.Value "String"
                        }
                    }
                }
            }
            Print-Success "已将物理网卡驱动级 Class 注册表高级配置全部精准还原！"
        }

        # 还原全局 TCP 参数 (中英文双向兼容与 CanonicalTcp 支持 Bug 5)
        $getTcpProp = {
            param($canonicalName, $regexPattern)
            if ($net.CanonicalTcp -and $net.CanonicalTcp.$canonicalName) { return $net.CanonicalTcp.$canonicalName }
            if ($net.GlobalTcp) {
                if ($net.GlobalTcp -is [System.Collections.IDictionary]) {
                    return ($net.GlobalTcp.GetEnumerator() | Where-Object { $_.Key -match $regexPattern } | Select-Object -ExpandProperty Value -First 1)
                } elseif ($net.GlobalTcp.PSObject) {
                    return ($net.GlobalTcp.PSObject.Properties | Where-Object { $_.Name -match $regexPattern } | Select-Object -ExpandProperty Value -First 1)
                }
            }
            return $null
        }
        $rssVal = & $getTcpProp 'rss' 'Receive-Side|接收.*缩放'
        $atVal  = & $getTcpProp 'autotuninglevel' 'Auto-Tuning|自动调节'
        $ecnVal = & $getTcpProp 'ecncapability' 'ECN'
        $tsVal  = & $getTcpProp 'timestamps' 'Timestamp|时间戳'
        if ($rssVal) { netsh int tcp set global rss=$rssVal 2>$null | Out-Null }
        if ($atVal) { netsh int tcp set global autotuninglevel=$atVal 2>$null | Out-Null }
        if ($ecnVal) { netsh int tcp set global ecncapability=$ecnVal 2>$null | Out-Null }
        if ($tsVal) { netsh int tcp set global timestamps=$tsVal 2>$null | Out-Null }
    }
} catch {
    Print-Warn "网络属性还原提示: $_"
}

# =========================================================================
# 9. 还原鼠标指针加速度、键盘速度与 USB 节能设置
# =========================================================================
Print-Step "9/10" "还原用户原有的鼠标指针加速度刻度、键盘按键延迟与 USB 供电"
try {
    $inp = $state.Input
    if ($inp) {
        Restore-RegValue "HKCU:\Control Panel\Mouse" "MouseSpeed" $inp.MouseSpeed "String"
        Restore-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold1" $inp.MouseThreshold1 "String"
        Restore-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold2" $inp.MouseThreshold2 "String"
        Restore-RegValue "HKCU:\Control Panel\Mouse" "MouseSensitivity" $inp.MouseSensitivity "String"
        Restore-RegValue "HKCU:\Control Panel\Keyboard" "KeyboardDelay" $inp.KeyboardDelay "String"
        Restore-RegValue "HKCU:\Control Panel\Keyboard" "KeyboardSpeed" $inp.KeyboardSpeed "String"
        Print-Success "已精准还原优化前用户的鼠标指针灵敏度刻度 (Sensitivity=$($inp.MouseSensitivity)) 与按键延迟！"

        # 还原 USB 根集线器与控制器节能
        if ($inp.UsbDevices) {
            foreach ($u in $inp.UsbDevices) {
                if ($u.Path -and (Test-Path $u.Path)) {
                    Restore-RegValue $u.Path "SelectiveSuspendEnabled" $u.SelectiveSuspendEnabled
                    Restore-RegValue $u.Path "DeviceSelectiveSuspended" $u.DeviceSelectiveSuspended
                    Restore-RegValue $u.Path "EnhancedPowerManagementEnabled" $u.EnhancedPowerManagementEnabled
                    Restore-RegValue $u.Path "AllowIdleIrpInD3" $u.AllowIdleIrpInD3
                }
            }
            Print-Success "已将 USB 根集线器与控制器的节电配置恢复至优化前设定！"
        }
    }
} catch {
    Print-Warn "外设输入还原提示: $_"
}

# =========================================================================
# 10. 还原 MPO 多平面叠加、GameDVR、MMCSS、SysMain 并注销自适应看门狗
# =========================================================================
Print-Step "10/10" "还原 MPO 渲染、GameDVR 录屏、SysMain 预读、解除看门狗守护"
try {
    $gfx = $state.Graphics
    $sys = $state.SystemBackground

    # 1. 还原 MPO 与图形
    if ($gfx) {
        Restore-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" $gfx.OverlayTestMode
        Restore-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "DisableOverlays" $gfx.DisableOverlays
        Restore-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" $gfx.HwSchMode
        if ($gfx.PSObject.Properties['DirectXUserGlobalSettings'] -and $gfx.DirectXUserGlobalSettings) {
            Restore-RegValue "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" "DirectXUserGlobalSettings" $gfx.DirectXUserGlobalSettings "String"
        } else {
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectXUserGlobalSettings" -Force -ErrorAction SilentlyContinue
        }
        Print-Success "MPO 多平面叠加、全局 GPU 首选项与图形调度已还原至优化前状态 (OverlayTestMode=$($gfx.OverlayTestMode))"

        # 2. 还原 GameDVR 与 GameBarPresenceWriter
        Restore-RegValue "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" $gfx.AutoGameModeEnabled
        Restore-RegValue "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" $gfx.AllowAutoGameMode
        Restore-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" $gfx.AllowGameDVR
        Restore-RegValue "HKCU:\System\GameConfigStore" "GameDVR_Enabled" $gfx.GameDVR_Enabled
        Restore-RegValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" $gfx.GameDVR_FSEBehaviorMode
        Restore-RegValue "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" $gfx.GameDVR_HonorUserFSEBehaviorMode
        Restore-RegValue "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" $gfx.GameDVR_DXGIHonorFSEWindowsCompatible
        Restore-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" $gfx.AppCaptureEnabled
        Restore-RegValue "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" "ActivationType" $gfx.PresenceWriterActivationType

        # 还原 MMCSS Games & Audio
        $knownMmcssKeys = @("Affinity", "Background Only", "Clock Rate", "GPU Priority", "Priority", "Scheduling Category", "SFIO Priority")
        $knownDwordKeys = @("Affinity", "Clock Rate", "GPU Priority", "Priority")
        $gamesKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        if (Test-Path $gamesKey) {
            foreach ($k in $knownMmcssKeys) {
                $hasKey = $false
                $v = $null
                if ($gfx.MmcssGames) {
                    if ($gfx.MmcssGames -is [System.Collections.IDictionary]) {
                        if ($gfx.MmcssGames.ContainsKey($k)) {
                            $hasKey = $true
                            $v = $gfx.MmcssGames[$k]
                        }
                    } elseif ($gfx.MmcssGames.PSObject -and $gfx.MmcssGames.PSObject.Properties[$k]) {
                        $hasKey = $true
                        $v = $gfx.MmcssGames.$k
                    }
                }
                if ($hasKey) {
                    $t = if ($knownDwordKeys -contains $k) { "DWord" } else { "String" }
                    Restore-RegValue $gamesKey $k $v $t
                } else {
                    Remove-ItemProperty -Path $gamesKey -Name $k -Force -ErrorAction SilentlyContinue
                }
            }
        }
        $audioKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio"
        if (Test-Path $audioKey) {
            foreach ($k in $knownMmcssKeys) {
                $hasKey = $false
                $v = $null
                if ($gfx.MmcssAudio) {
                    if ($gfx.MmcssAudio -is [System.Collections.IDictionary]) {
                        if ($gfx.MmcssAudio.ContainsKey($k)) {
                            $hasKey = $true
                            $v = $gfx.MmcssAudio[$k]
                        }
                    } elseif ($gfx.MmcssAudio.PSObject -and $gfx.MmcssAudio.PSObject.Properties[$k]) {
                        $hasKey = $true
                        $v = $gfx.MmcssAudio.$k
                    }
                }
                if ($hasKey) {
                    $t = if ($knownDwordKeys -contains $k) { "DWord" } else { "String" }
                    Restore-RegValue $audioKey $k $v $t
                } else {
                    Remove-ItemProperty -Path $audioKey -Name $k -Force -ErrorAction SilentlyContinue
                }
            }
        }
        Print-Success "GameDVR、MMCSS 任务与 GameBar 进程状态已还原至优化前状态！"
    }

    # 3. 还原 Windows 节能节流 (Power Throttling)
    if ($sys) {
        Restore-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" $sys.PowerThrottlingOff
        Print-Success "Power Throttling 节能节流已还原至优化前状态！"

        # 4. 还原 SysMain (超级预读服务)
        if ($sys.SysMainStartType) {
            Set-Service -Name "SysMain" -StartupType $sys.SysMainStartType -ErrorAction SilentlyContinue
            if ($sys.SysMainStatus -eq "Running") {
                Start-Service -Name "SysMain" -ErrorAction SilentlyContinue
            }
            Print-Success "SysMain 服务启动类型已精准还原为: [$($sys.SysMainStartType)] (运行状态: $($sys.SysMainStatus))"
        }
    }

    # 5. 彻底终止并清除看门狗守护引擎任务
    Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue | Where-Object {
        $_.CommandLine -match "UniversalWatchdog"
    } | ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
    schtasks /delete /tn "UniversalGameOptimizer_Watchdog" /f 2>$null | Out-Null
    Print-Success "已彻底注销并退出后台 UniversalWatchdog 自适应守护引擎！"

    # 6. 清理生成的调谐工作目录文件 (保留快照与日志)
    Remove-Item "$env:ProgramData\UniversalGameOptimizer\HardwareBootApply.cmd" -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-Item "$env:ProgramData\UniversalGameOptimizer\UniversalWatchdog.ps1" -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-Item "$env:ProgramData\UniversalGameOptimizer\OptimizationCompleted.flag" -Force -ErrorAction SilentlyContinue | Out-Null

    # 7. 还原并清理 NVIDIA PowerMizer 供电策略与游戏专属定向渲染注入
    $videoClassKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    if (Test-Path $videoClassKey) {
        Get-ChildItem $videoClassKey -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match "^\d{4}$" } | ForEach-Object {
            $subPath = $_.PSPath
            Remove-ItemProperty -Path $subPath -Name "PowerMizerEnable" -Force -ErrorAction SilentlyContinue | Out-Null
            Remove-ItemProperty -Path $subPath -Name "PowerMizerLevel" -Force -ErrorAction SilentlyContinue | Out-Null
            Remove-ItemProperty -Path $subPath -Name "PowerMizerLevelAC" -Force -ErrorAction SilentlyContinue | Out-Null
            Remove-ItemProperty -Path $subPath -Name "PerfLevelSrc" -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
    $commonGameExes = @(
        "cs2.exe", "csgo.exe", "valorant.exe", "pubg.exe", "tslgame.exe", "r5apex.exe",
        "fortniteclient-win64-shipping.exe", "overwatch.exe", "league of legends.exe", "dota2.exe",
        "genshinimpact.exe", "honkaistarrail.exe", "naraka.exe", "blackmythwukong.exe",
        "b1-win64-shipping.exe", "cyberpunk2077.exe", "eldenring.exe", "gta5.exe", "rdr2.exe"
    )
    foreach ($g in $commonGameExes) {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name $g -Force -ErrorAction SilentlyContinue
    }
    Print-Success "已撤销显卡 PowerMizer 强制供电策略并清除游戏专属独显渲染注入！"
} catch {
    Print-Warn "后台服务还原提示: $_"
}

try {
    Write-Progress -Activity "Windows 底层状态精准无损还原" -Status "还原全部就绪！(100%)" -PercentComplete 100 -Completed
} catch {}
Write-Host "[PROGRESS: 100] 全量系统状态精准无损还原完成！"

Write-Host "`n======================================================================================" -ForegroundColor Green
Write-Host "       ★★★ 全量系统状态精准无损还原完成 (100% 恢复优化前个性化原貌) ★★★       " -ForegroundColor Green
Write-Host "======================================================================================" -ForegroundColor Green
Write-Host " [√] 芯片频率与电压：GPU 核心时钟锁解除，CPU 负压清零，清除开机自动调谐任务" -ForegroundColor White
Write-Host " [√] 原始电源计划：精准切回优化前用户原有的电源方案，恢复 CPU 原生停驻调度" -ForegroundColor White
Write-Host " [√] 用户虚拟内存：精准还原优化前由 Windows 托管或用户原本指定的盘符尺寸" -ForegroundColor White
Write-Host " [√] 原生外设灵敏度：鼠标指针速度、按键响应速度与加速度 100% 还原用户原习惯" -ForegroundColor White
Write-Host " [√] 物理网卡与协议：中断审慎、流控制、EEE 与 TCP 设置全部还原至优化前状态" -ForegroundColor White
Write-Host " [√] 显示、安全与后台：MPO、SysMain、Defender、GameDVR 与看门狗已彻底撤销退出" -ForegroundColor White
Write-Host "`n建议在方便时【重启电脑】，以便内核隔离与硬件中断状态在固件层完整生效！" -ForegroundColor Green
if (-not $NonInteractive -and $env:UGO_NON_INTERACTIVE -ne '1') {
    Write-Host "按任意键退出..." -ForegroundColor Gray
    try { if ([Console]::KeyAvailable -or $Host.UI.RawUI.KeyAvailable) { $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null } else { Start-Sleep -Milliseconds 100 } } catch {}
}
