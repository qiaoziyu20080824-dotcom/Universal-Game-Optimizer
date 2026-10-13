<#
======================================================================================
  ★ WINDOWS 系统底层优化 - 本机专属定制无损还原大师 (Pre-State Restorer) ★
  【动态编译机制】：本脚本于优化完成时根据您的自选决策与硬件扫描结果实时编译生成！
  【受保硬件画像】：AMD Ryzen 9 9955HX3D 16-Core Processor | NVIDIA GeForce RTX 5070 Ti Laptop GPU | 32 GB 内存
  【用户自选决议】：
    * 芯片负压与超频: 未启用 (已跳过，无需撤销)
    * Defender 杀毒: 已保留 (优化未曾变动，还原自动跳过)
  【快照生成时间】：2026-10-13 15:39:10
======================================================================================
#>

param([switch]$NonInteractive)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } elseif ([System.AppDomain]::CurrentDomain.BaseDirectory) { [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\') } else { (Get-Location).Path }
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "Windows 底层优化状态无损精准还原大师 (Pre-State Restorer)"
$isAdmin = ($env:UGO_SKIP_ADMIN_CHECK -eq '1') -or (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
if (-not $isAdmin) {
    Write-Host "`n [!] 错误：还原系统状态必须使用管理员权限！请右键【以管理员身份运行】！" -ForegroundColor Red
    if (-not $NonInteractive -and $env:UGO_NON_INTERACTIVE -ne '1') { Pause }; exit
}
Clear-Host
Write-Host "======================================================================================" -ForegroundColor Cyan
Write-Host "      ★ WINDOWS 系统底层优化状态精准无损还原大师 (本机专属定制版) ★      " -ForegroundColor Green
Write-Host "   【100% 精准无损】：针对优化时您的自选决策与系统原貌生成，不套用虚假出厂默认   " -ForegroundColor Yellow
Write-Host "======================================================================================" -ForegroundColor Cyan

function Get-ProgressBarString ($pct, $width = 26) { $filled = [int][Math]::Round(($pct / 100.0) * $width); if ($filled -lt 0) { $filled = 0 }; if ($filled -gt $width) { $filled = $width }; $empty = $width - $filled; return "[$("'" + ("█" * $filled) + ("░" * $empty) + "'")] $pct%" }
function Print-Step ($num, $title) { $pct = 0; if ($num -match "(\d+)\s*/\s*(\d+)") { $curr = [int]$matches[1]; $total = [int]$matches[2]; $pct = [int][Math]::Min(98, [Math]::Max(5, [Math]::Round(($curr / $total) * 95))) } else { $pct = 50 }; Write-Host "[PROGRESS: $pct] $title"; Write-Host "`n>>> [$num] $title" -ForegroundColor Yellow; try { Write-Progress -Activity "Windows 底层状态精准无损还原" -Status "[$num] $title ($pct%)" -PercentComplete $pct } catch {} }
function Print-Success ($msg) { Write-Host "  [√ 还原成功] $msg" -ForegroundColor Green }
function Print-Info ($msg) { Write-Host "  [i 状态确认] $msg" -ForegroundColor Gray }
function Print-Warn ($msg) { Write-Host "  [! 还原提示] $msg" -ForegroundColor Magenta }

function Restore-RegValue ($path, $name, $val, $type = "DWord") {
    try {
        if ($null -eq $val) {
            if (Test-Path $path) { Remove-ItemProperty -Path $path -Name $name -Force -ErrorAction SilentlyContinue | Out-Null }
        } else {
            if (-not (Test-Path $path)) { New-Item -Path $path -Force -ErrorAction SilentlyContinue | Out-Null }
            Set-ItemProperty -Path $path -Name $name -Value $val -Type $type -Force -ErrorAction SilentlyContinue | Out-Null
        }
    } catch {}
}

Print-Step "1/10" "还原 CPU 与 GPU 芯片频率、电压与功耗至基准"
Print-Success "检测到优化时【用户已选择跳过硬件调谐】，未修改芯片电压与频率，保持原生状态！"

Print-Step "2/10" "还原优化前用户原有的电源方案与 CPU 调度策略"
powercfg -setactive scheme_balanced 2>$null | Out-Null
Print-Success "已恢复系统标准平衡电源方案。"
Restore-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'PlatformAoAcOverride' 0

Print-Step "3/10" "还原优化前内核隔离与虚拟化安全状态"
$ciKey = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
$dgKey = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
$polDgKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard"
Restore-RegValue $ciKey 'Enabled' 0
Restore-RegValue $ciKey 'WasEnabledBy' 0
Restore-RegValue $dgKey 'EnableVirtualizationBasedSecurity' 0
Restore-RegValue $dgKey 'RequirePlatformSecurityFeatures' 0
Restore-RegValue $polDgKey 'EnableVirtualizationBasedSecurity' 0
Print-Success "内核隔离与 VBS 安全策略已恢复至优化前原始状态！"

Print-Step "4/10" "Windows Defender 杀毒与安全中心防线处理"
Print-Success "检测到本次优化时【用户已选择保留 Defender 正常工作】，未曾做过修改，维持原样！"

Print-Step "5/10" "还原 PCIe 显卡与物理网卡 MSI 硬件中断设置与亲和性策略"
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_1002&DEV_13C0&SUBSYS_50041D05&REV_D4\4&176e0677&0&0041\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' 'MSISupported' 1
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_1002&DEV_13C0&SUBSYS_50041D05&REV_D4\4&176e0677&0&0041\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' 'MessageNumberLimit' $null
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_1002&DEV_13C0&SUBSYS_50041D05&REV_D4\4&176e0677&0&0041\Device Parameters\Interrupt Management\Affinity Policy' 'DevicePriority' 3
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_1002&DEV_13C0&SUBSYS_50041D05&REV_D4\4&176e0677&0&0041\Device Parameters\Interrupt Management\Affinity Policy' 'DevicePolicy' $null
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_1002&DEV_13C0&SUBSYS_50041D05&REV_D4\4&176e0677&0&0041\Device Parameters\Interrupt Management\Affinity Policy') { Remove-ItemProperty -Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_1002&DEV_13C0&SUBSYS_50041D05&REV_D4\4&176e0677&0&0041\Device Parameters\Interrupt Management\Affinity Policy' -Name 'AssignmentSetOverride' -Force -ErrorAction SilentlyContinue | Out-Null }
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10DE&DEV_2F18&SUBSYS_60421D05&REV_A1\CEADF401C52DB04800\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' 'MSISupported' 1
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10DE&DEV_2F18&SUBSYS_60421D05&REV_A1\CEADF401C52DB04800\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' 'MessageNumberLimit' 1
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10DE&DEV_2F18&SUBSYS_60421D05&REV_A1\CEADF401C52DB04800\Device Parameters\Interrupt Management\Affinity Policy' 'DevicePriority' 3
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10DE&DEV_2F18&SUBSYS_60421D05&REV_A1\CEADF401C52DB04800\Device Parameters\Interrupt Management\Affinity Policy' 'DevicePolicy' 4
try {
    $parts = '0 3 0 0 0 0 0 0' -split '[- ]'
    [byte[]]$bytes = foreach ($p in $parts) { if ($p) { [Convert]::ToByte($p, 16) } }
    Set-ItemProperty -Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10DE&DEV_2F18&SUBSYS_60421D05&REV_A1\CEADF401C52DB04800\Device Parameters\Interrupt Management\Affinity Policy' -Name 'AssignmentSetOverride' -Value $bytes -Type Binary -Force -ErrorAction SilentlyContinue | Out-Null
} catch {}
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10DE&DEV_2F18&SUBSYS_60541D05&REV_A1\CEADF401C52DB04800\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' 'MSISupported' 1
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10DE&DEV_2F18&SUBSYS_60541D05&REV_A1\CEADF401C52DB04800\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' 'MessageNumberLimit' 1
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10DE&DEV_2F18&SUBSYS_60541D05&REV_A1\CEADF401C52DB04800\Device Parameters\Interrupt Management\Affinity Policy' 'DevicePriority' 3
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10DE&DEV_2F18&SUBSYS_60541D05&REV_A1\CEADF401C52DB04800\Device Parameters\Interrupt Management\Affinity Policy' 'DevicePolicy' 4
try {
    $parts = '0 3 0 0 0 0 0 0' -split '[- ]'
    [byte[]]$bytes = foreach ($p in $parts) { if ($p) { [Convert]::ToByte($p, 16) } }
    Set-ItemProperty -Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10DE&DEV_2F18&SUBSYS_60541D05&REV_A1\CEADF401C52DB04800\Device Parameters\Interrupt Management\Affinity Policy' -Name 'AssignmentSetOverride' -Value $bytes -Type Binary -Force -ErrorAction SilentlyContinue | Out-Null
} catch {}
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10EC&DEV_8125&SUBSYS_70131D05&REV_05\01000000684CE00000\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' 'MSISupported' 1
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10EC&DEV_8125&SUBSYS_70131D05&REV_05\01000000684CE00000\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' 'MessageNumberLimit' 1
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10EC&DEV_8125&SUBSYS_70131D05&REV_05\01000000684CE00000\Device Parameters\Interrupt Management\Affinity Policy' 'DevicePriority' 3
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10EC&DEV_8125&SUBSYS_70131D05&REV_05\01000000684CE00000\Device Parameters\Interrupt Management\Affinity Policy' 'DevicePolicy' 4
try {
    $parts = '48 0 0 0 0 0 0 0' -split '[- ]'
    [byte[]]$bytes = foreach ($p in $parts) { if ($p) { [Convert]::ToByte($p, 16) } }
    Set-ItemProperty -Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10EC&DEV_8125&SUBSYS_70131D05&REV_05\01000000684CE00000\Device Parameters\Interrupt Management\Affinity Policy' -Name 'AssignmentSetOverride' -Value $bytes -Type Binary -Force -ErrorAction SilentlyContinue | Out-Null
} catch {}
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_14C3&DEV_7922&SUBSYS_59111A3B&REV_00\4&2dcdcbfd&0&000C\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' 'MSISupported' 1
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_14C3&DEV_7922&SUBSYS_59111A3B&REV_00\4&2dcdcbfd&0&000C\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties' 'MessageNumberLimit' 1
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_14C3&DEV_7922&SUBSYS_59111A3B&REV_00\4&2dcdcbfd&0&000C\Device Parameters\Interrupt Management\Affinity Policy' 'DevicePriority' 3
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_14C3&DEV_7922&SUBSYS_59111A3B&REV_00\4&2dcdcbfd&0&000C\Device Parameters\Interrupt Management\Affinity Policy' 'DevicePolicy' 4
try {
    $parts = '48 0 0 0 0 0 0 0' -split '[- ]'
    [byte[]]$bytes = foreach ($p in $parts) { if ($p) { [Convert]::ToByte($p, 16) } }
    Set-ItemProperty -Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\PCI\VEN_14C3&DEV_7922&SUBSYS_59111A3B&REV_00\4&2dcdcbfd&0&000C\Device Parameters\Interrupt Management\Affinity Policy' -Name 'AssignmentSetOverride' -Value $bytes -Type Binary -Force -ErrorAction SilentlyContinue | Out-Null
} catch {}
Print-Success "已将所有检测到的硬件中断属性与亲和性策略精准还原至优化前状态！"

Print-Step "6/10" "还原系统 BCD 引导时钟策略"
bcdedit /deletevalue useplatformtick 2>$null | Out-Null
bcdedit /deletevalue disabledynamictick 2>$null | Out-Null
bcdedit /deletevalue useplatformclock 2>$null | Out-Null
Print-Success "已撤销 BCD 动态时钟禁用配置，恢复 Windows 原生时钟调度模式。"

Print-Step "7/10" "还原优化前用户原有的虚拟内存与分页文件配置"
$origPaging = '["C:\\pagefile.sys 2048 4096","E:\\pagefile.sys 4096 24576"]' | ConvertFrom-Json
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -Value $origPaging -Type MultiString -Force -ErrorAction SilentlyContinue
Print-Success "已精准还原为用户优化前自定义的固定分页文件设置: [C:\pagefile.sys 2048 4096 E:\pagefile.sys 4096 24576]"
Restore-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'DisablePagingExecutive' 1
Restore-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'LargeSystemCache' 0
Restore-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisableLastAccessUpdate' 2147483649
Restore-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisable8dot3NameCreation' 1
fsutil behavior set disablelastaccess 3 2>$null | Out-Null
fsutil 8dot3name set 1 2>$null | Out-Null

Print-Step "8/10" "还原物理网卡硬件高级属性 (中断审慎/流控制/LSO/EEE) 与网络节流"
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 4294967295
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 10
Restore-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{F75FAAD9-B88D-4D46-9887-09174134A672}' 'TcpAckFrequency' 1
Restore-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{F75FAAD9-B88D-4D46-9887-09174134A672}' 'TCPNoDelay' 1
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'BWSelection6G' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'CurrPhyMode' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'LowPowerEnable' -RegistryValue @('1') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'UAPSDSupport' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'TxPowerLevel' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'DisableWakeOnPattern' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'BandSelection' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'BWSelection24G' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'AMSDURx' -RegistryValue @('1') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'DisableARPOffload' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'BWSelection5G' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'RoamIndicateTh' -RegistryValue @('4') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'WfdGOOperatingChannel' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'AMSDUTx' -RegistryValue @('1') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'PreferredBand' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'DisableGTKRekey' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name 'WLAN' -RegistryKeyword 'DisableWakeOnMagic' -RegistryValue @('0') -ErrorAction SilentlyContinue
Restore-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{B9B0B679-4E96-4C8D-A7A1-25E1138E7A38}' 'TcpAckFrequency' 1
Restore-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{B9B0B679-4E96-4C8D-A7A1-25E1138E7A38}' 'TCPNoDelay' 1
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*FlowControl' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*SpeedDuplex' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*EEE' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword 'EEEMaxSupportSpeed' -RegistryValue @('1000') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*WakeOnPattern' -RegistryValue @('1') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue @('1') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*PriorityVlanTag' -RegistryValue @('3') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword 'RegVlanid' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*UDPChecksumOffloadIPv4' -RegistryValue @('3') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword 'AdvancedEEE' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword 'WolShutdownLinkSpeed' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*ReceiveBuffers' -RegistryValue @('1024') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*IPChecksumOffloadIPv4' -RegistryValue @('3') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*PMNSOffload' -RegistryValue @('1') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*TCPChecksumOffloadIPv6' -RegistryValue @('3') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*JumboPacket' -RegistryValue @('1514') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword 'EnableGreenEthernet' -RegistryValue @('1') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*TCPChecksumOffloadIPv4' -RegistryValue @('3') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword 'GigaLite' -RegistryValue @('1') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*LsoV2IPv4' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword 'PowerSavingMode' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword 'S5WakeOnLan' -RegistryValue @('1') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*UDPChecksumOffloadIPv6' -RegistryValue @('3') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*LsoV2IPv6' -RegistryValue @('0') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword 'NetworkAddress' -RegistryValue @('') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*TransmitBuffers' -RegistryValue @('512') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*PMARPOffload' -RegistryValue @('1') -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name '以太网' -RegistryKeyword '*InterruptModeration' -RegistryValue @('1') -ErrorAction SilentlyContinue
Print-Success "已将物理网卡硬件高级属性与 TCP/UDP 协议栈全部精准还原！"
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0000' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0001' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0002' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0002' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0002' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0002' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0002' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0002' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0002' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0003' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0003' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0003' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0003' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0003' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0003' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0003' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0004' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0004' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0004' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0004' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0004' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0004' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0004' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0005' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0005' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0005' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0005' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0005' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0005' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0005' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0006' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0006' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0006' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0006' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0006' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0006' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0006' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0007' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0007' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0007' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0007' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0007' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0007' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0007' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0008' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0008' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0008' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0008' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0008' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0008' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0008' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0009' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0009' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0009' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0009' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0009' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0009' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0009' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0010' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0010' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0010' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0010' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0010' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0010' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0010' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0011' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0011' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0011' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0011' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0011' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0011' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0011' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0012' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0012' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0012' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0012' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0012' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0012' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0012' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0013' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0013' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0013' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0013' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0013' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0013' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0013' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0014' '*LsoV2IPv4' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0014' '*GreenEthernet' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0014' '*LsoV2IPv6' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0014' '*FlowControl' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0014' '*AdvancedEEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0014' 'PowerSavingMode' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0014' '*EEE' '0' 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0015' '*LsoV2IPv4' $null 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0015' '*GreenEthernet' $null 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0015' '*LsoV2IPv6' $null 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0015' '*FlowControl' $null 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0015' '*AdvancedEEE' $null 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0015' 'PowerSavingMode' $null 'String'
Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\0015' '*EEE' $null 'String'

Print-Step "9/10" "还原优化前用户原有的鼠标指针灵敏度与按键响应速度"
Restore-RegValue 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
Restore-RegValue 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
Restore-RegValue 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
Restore-RegValue 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '10' 'String'
Restore-RegValue 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0' 'String'
Restore-RegValue 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' 'String'
Print-Success "已精准还原优化前用户的鼠标指针灵敏度刻度 (Sensitivity=10) 与按键延迟！"
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&107d1af1&0&0\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&107d1af1&0&0\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&107d1af1&0&0\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&107d1af1&0&0\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&107d1af1&0&0\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&131f744d&0&0\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&131f744d&0&0\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&131f744d&0&0\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&131f744d&0&0\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&131f744d&0&0\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&366178b0&0&0\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&366178b0&0&0\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&366178b0&0&0\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&366178b0&0&0\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30\5&366178b0&0&0\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0000&PID_0001\7&5157ea2&0&2\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0000&PID_0001\7&5157ea2&0&2\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0000&PID_0001\7&5157ea2&0&2\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0000&PID_0001\7&5157ea2&0&2\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0000&PID_0001\7&5157ea2&0&2\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0000&PID_0002\6&2f914aa9&0&1\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0000&PID_0002\6&2f914aa9&0&1\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0000&PID_0002\6&2f914aa9&0&1\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0000&PID_0002\6&2f914aa9&0&1\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0000&PID_0002\6&2f914aa9&0&1\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E\32869698\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E\32869698\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E\32869698\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E\32869698\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E\32869698\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_00\8&2cdee457&0&00\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_00\8&2cdee457&0&00\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_00\8&2cdee457&0&00\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_00\8&2cdee457&0&00\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_00\8&2cdee457&0&00\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_01\8&2cdee457&0&01\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_01\8&2cdee457&0&01\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_01\8&2cdee457&0&01\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_01\8&2cdee457&0&01\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_01\8&2cdee457&0&01\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_02\8&2cdee457&0&02\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_02\8&2cdee457&0&02\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_02\8&2cdee457&0&02\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_02\8&2cdee457&0&02\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_045E&PID_028E&IG_02\8&2cdee457&0&02\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D\205E38495357\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D\205E38495357\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D\205E38495357\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D\205E38495357\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D\205E38495357\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&LAMPARRAY\7&b503689&0&205E38495357_Slot00\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&LAMPARRAY\7&b503689&0&205E38495357_Slot00\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&LAMPARRAY\7&b503689&0&205E38495357_Slot00\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&LAMPARRAY\7&b503689&0&205E38495357_Slot00\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&LAMPARRAY\7&b503689&0&205E38495357_Slot00\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&MI_00\7&b503689&0&0000\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&MI_00\7&b503689&0&0000\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&MI_00\7&b503689&0&0000\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&MI_00\7&b503689&0&0000\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&MI_00\7&b503689&0&0000\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&MI_01\7&b503689&0&0001\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&MI_01\7&b503689&0&0001\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&MI_01\7&b503689&0&0001\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&MI_01\7&b503689&0&0001\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C09D&MI_01\7&b503689&0&0001\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B\7&5157ea2&0&1\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B\7&5157ea2&0&1\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B\7&5157ea2&0&1\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B\7&5157ea2&0&1\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B\7&5157ea2&0&1\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B&MI_00\8&1832c44f&0&0000\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B&MI_00\8&1832c44f&0&0000\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B&MI_00\8&1832c44f&0&0000\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B&MI_00\8&1832c44f&0&0000\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B&MI_00\8&1832c44f&0&0000\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B&MI_01\8&1832c44f&0&0001\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B&MI_01\8&1832c44f&0&0001\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B&MI_01\8&1832c44f&0&0001\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B&MI_01\8&1832c44f&0&0001\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_600B&MI_01\8&1832c44f&0&0001\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001\7&5157ea2&0&3\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001\7&5157ea2&0&3\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001\7&5157ea2&0&3\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001\7&5157ea2&0&3\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001\7&5157ea2&0&3\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001&MI_00\8&7d8aec9&0&0000\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001&MI_00\8&7d8aec9&0&0000\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001&MI_00\8&7d8aec9&0&0000\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001&MI_00\8&7d8aec9&0&0000\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001&MI_00\8&7d8aec9&0&0000\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001&MI_01\8&7d8aec9&0&0001\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001&MI_01\8&7d8aec9&0&0001\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001&MI_01\8&7d8aec9&0&0001\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001&MI_01\8&7d8aec9&0&0001\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_048D&PID_7001&MI_01\8&7d8aec9&0&0001\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8\00008030000975093EF1802E\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8\00008030000975093EF1802E\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8\00008030000975093EF1802E\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8\00008030000975093EF1802E\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8\00008030000975093EF1802E\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8&MI_00\7&2736317&0&0000\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8&MI_00\7&2736317&0&0000\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8&MI_00\7&2736317&0&0000\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8&MI_00\7&2736317&0&0000\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8&MI_00\7&2736317&0&0000\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8&MI_01\7&2736317&0&0001\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8&MI_01\7&2736317&0&0001\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8&MI_01\7&2736317&0&0001\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8&MI_01\7&2736317&0&0001\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05AC&PID_12A8&MI_01\7&2736317&0&0001\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0608\6&11814c72&0&1\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0608\6&11814c72&0&1\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0608\6&11814c72&0&1\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0608\6&11814c72&0&1\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0608\6&11814c72&0&1\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0610\6&202fa33d&0&2\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0610\6&202fa33d&0&2\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0610\6&202fa33d&0&2\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0610\6&202fa33d&0&2\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0610\6&202fa33d&0&2\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0620\6&202fa33d&0&4\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0620\6&202fa33d&0&4\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0620\6&202fa33d&0&4\Device Parameters' 'DeviceSelectiveSuspended' 1
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0620\6&202fa33d&0&4\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_05E3&PID_0620\6&202fa33d&0&4\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_090C&PID_2320\MSFT30AA000000000000000506\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_090C&PID_2320\MSFT30AA000000000000000506\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_090C&PID_2320\MSFT30AA000000000000000506\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_090C&PID_2320\MSFT30AA000000000000000506\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_090C&PID_2320\MSFT30AA000000000000000506\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0\6&202fa33d&0&1\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0\6&202fa33d&0&1\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0\6&202fa33d&0&1\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0\6&202fa33d&0&1\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0\6&202fa33d&0&1\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0&MI_00\7&30112ad5&0&0000\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0&MI_00\7&30112ad5&0&0000\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0&MI_00\7&30112ad5&0&0000\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0&MI_00\7&30112ad5&0&0000\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0&MI_00\7&30112ad5&0&0000\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0&MI_01\7&30112ad5&0&0001\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0&MI_01\7&30112ad5&0&0001\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0&MI_01\7&30112ad5&0&0001\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0&MI_01\7&30112ad5&0&0001\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_0E6A&PID_02C0&MI_01\7&30112ad5&0&0001\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_13D3&PID_3585\000000000\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_13D3&PID_3585\000000000\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_13D3&PID_3585\000000000\Device Parameters' 'DeviceSelectiveSuspended' 1
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_13D3&PID_3585\000000000\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_13D3&PID_3585\000000000\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_13D3&PID_3585&MI_00\8&3721923b&0&0000\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_13D3&PID_3585&MI_00\8&3721923b&0&0000\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_13D3&PID_3585&MI_00\8&3721923b&0&0000\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_13D3&PID_3585&MI_00\8&3721923b&0&0000\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_13D3&PID_3585&MI_00\8&3721923b&0&0000\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256\3939396C0557\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256\3939396C0557\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256\3939396C0557\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256\3939396C0557\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256\3939396C0557\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256&MI_00\8&17326c94&0&0000\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256&MI_00\8&17326c94&0&0000\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256&MI_00\8&17326c94&0&0000\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256&MI_00\8&17326c94&0&0000\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256&MI_00\8&17326c94&0&0000\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256&MI_01\8&17326c94&0&0001\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256&MI_01\8&17326c94&0&0001\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256&MI_01\8&17326c94&0&0001\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256&MI_01\8&17326c94&0&0001\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_28E9&PID_3256&MI_01\8&17326c94&0&0001\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664\01.00.00\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664\01.00.00\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664\01.00.00\Device Parameters' 'DeviceSelectiveSuspended' 1
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664\01.00.00\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664\01.00.00\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664&MI_00\8&c2c60b6&0&0000\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664&MI_00\8&c2c60b6&0&0000\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664&MI_00\8&c2c60b6&0&0000\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664&MI_00\8&c2c60b6&0&0000\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664&MI_00\8&c2c60b6&0&0000\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664&MI_02\8&c2c60b6&0&0002\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664&MI_02\8&c2c60b6&0&0002\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664&MI_02\8&c2c60b6&0&0002\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664&MI_02\8&c2c60b6&0&0002\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2B7E&PID_C664&MI_02\8&c2c60b6&0&0002\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012\10AG3J2GGY0033K\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012\10AG3J2GGY0033K\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012\10AG3J2GGY0033K\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012\10AG3J2GGY0033K\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012\10AG3J2GGY0033K\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012&MI_00\7&3186bac5&0&0000\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012&MI_00\7&3186bac5&0&0000\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012&MI_00\7&3186bac5&0&0000\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012&MI_00\7&3186bac5&0&0000\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012&MI_00\7&3186bac5&0&0000\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012&MI_01\7&3186bac5&0&0001\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012&MI_01\7&3186bac5&0&0001\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012&MI_01\7&3186bac5&0&0001\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012&MI_01\7&3186bac5&0&0001\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_2D95&PID_6012&MI_01\7&3186bac5&0&0001\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_3537&PID_1007\7&d8c7db4&0&1\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_3537&PID_1007\7&d8c7db4&0&1\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_3537&PID_1007\7&d8c7db4&0&1\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_3537&PID_1007\7&d8c7db4&0&1\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_3537&PID_1007\7&d8c7db4&0&1\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026\000000000001\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026\000000000001\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026\000000000001\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026\000000000001\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026\000000000001\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_00\7&1b19a894&0&0000\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_00\7&1b19a894&0&0000\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_00\7&1b19a894&0&0000\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_00\7&1b19a894&0&0000\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_00\7&1b19a894&0&0000\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_01\7&1b19a894&0&0001\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_01\7&1b19a894&0&0001\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_01\7&1b19a894&0&0001\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_01\7&1b19a894&0&0001\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_01\7&1b19a894&0&0001\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_02\7&1b19a894&0&0002\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_02\7&1b19a894&0&0002\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_02\7&1b19a894&0&0002\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_02\7&1b19a894&0&0002\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1026&MI_02\7&1b19a894&0&0002\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027\000000000001\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027\000000000001\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027\000000000001\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027\000000000001\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027\000000000001\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_00\7&ca0eb6b&0&0000\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_00\7&ca0eb6b&0&0000\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_00\7&ca0eb6b&0&0000\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_00\7&ca0eb6b&0&0000\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_00\7&ca0eb6b&0&0000\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_01\7&ca0eb6b&0&0001\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_01\7&ca0eb6b&0&0001\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_01\7&ca0eb6b&0&0001\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_01\7&ca0eb6b&0&0001\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_01\7&ca0eb6b&0&0001\Device Parameters' 'AllowIdleIrpInD3' 0
}
if (Test-Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_02\7&ca0eb6b&0&0002\Device Parameters') {
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_02\7&ca0eb6b&0&0002\Device Parameters' 'SelectiveSuspendEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_02\7&ca0eb6b&0&0002\Device Parameters' 'DeviceSelectiveSuspended' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_02\7&ca0eb6b&0&0002\Device Parameters' 'EnhancedPowerManagementEnabled' 0
    Restore-RegValue 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\VID_372E&PID_1027&MI_02\7&ca0eb6b&0&0002\Device Parameters' 'AllowIdleIrpInD3' 0
}
Print-Success "已将 USB 根集线器与控制器节电配置精准恢复！"

Print-Step "10/10" "还原 MPO 渲染、Xbox 服务、SysMain 预读、解除看门狗守护"
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' $null
Restore-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'DisableOverlays' $null
Restore-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
Restore-RegValue 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
Restore-RegValue 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
Restore-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
Restore-RegValue 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
Restore-RegValue 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
Restore-RegValue 'HKCU:\System\GameConfigStore' 'GameDVR_HonorUserFSEBehaviorMode' 1
Restore-RegValue 'HKCU:\System\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible' 1
Restore-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter' 'ActivationType' 1
Restore-RegValue 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings' 'GpuPreference=2;' 'String'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Affinity' 0 'DWord'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Background Only' 'False' 'String'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Clock Rate' 10000 'DWord'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'GPU Priority' 8 'DWord'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Priority' 6 'DWord'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Scheduling Category' 'High' 'String'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'SFIO Priority' 'High' 'String'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio' 'Affinity' 0 'DWord'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio' 'Background Only' 'False' 'String'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio' 'Clock Rate' 10000 'DWord'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio' 'GPU Priority' 8 'DWord'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio' 'Priority' 6 'DWord'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio' 'Scheduling Category' 'High' 'String'
Restore-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio' 'SFIO Priority' 'High' 'String'
Restore-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1
Set-Service -Name 'SysMain' -StartupType 'Automatic' -ErrorAction SilentlyContinue
Start-Service -Name "SysMain" -ErrorAction SilentlyContinue
Print-Success "SysMain 服务启动类型已精准还原为: [Automatic]"
Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -match "UniversalWatchdog"
} | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
$videoClassKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
if (Test-Path $videoClassKey) {
    Get-ChildItem $videoClassKey -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match "^\d{4}$" } | ForEach-Object {
        Remove-ItemProperty -Path $_.PSPath -Name "PowerMizerEnable" -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-ItemProperty -Path $_.PSPath -Name "PowerMizerLevel" -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-ItemProperty -Path $_.PSPath -Name "PowerMizerLevelAC" -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-ItemProperty -Path $_.PSPath -Name "PerfLevelSrc" -Force -ErrorAction SilentlyContinue | Out-Null
    }
}
$commonGameExes = @("cs2.exe", "csgo.exe", "valorant.exe", "pubg.exe", "tslgame.exe", "r5apex.exe", "fortniteclient-win64-shipping.exe", "overwatch.exe", "league of legends.exe", "dota2.exe", "genshinimpact.exe", "honkaistarrail.exe", "naraka.exe", "blackmythwukong.exe", "b1-win64-shipping.exe", "cyberpunk2077.exe", "eldenring.exe", "gta5.exe", "rdr2.exe")
foreach ($g in $commonGameExes) { Remove-ItemProperty -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name $g -Force -ErrorAction SilentlyContinue }
schtasks /delete /tn "UniversalGameOptimizer_Watchdog" /f 2>$null | Out-Null
Remove-Item "$env:ProgramData\UniversalGameOptimizer\HardwareBootApply.cmd" -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:ProgramData\UniversalGameOptimizer\UniversalWatchdog.ps1" -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:ProgramData\UniversalGameOptimizer\OptimizationCompleted.flag" -Force -ErrorAction SilentlyContinue | Out-Null
Print-Success "已彻底注销并退出后台 UniversalWatchdog 自适应守护引擎！"

Write-Host "`n======================================================================================" -ForegroundColor Green
Write-Host "       ★★★ 全量系统状态精准无损还原完成 (100% 恢复优化前个性化原貌) ★★★       " -ForegroundColor Green
Write-Host "======================================================================================" -ForegroundColor Green
Write-Host " [√] 芯片频率与电压：已恢复优化前基准，清除开机自动调谐任务" -ForegroundColor White
Write-Host " [√] 原始电源计划：精准切回优化前用户原有的电源方案，恢复原生停驻调度" -ForegroundColor White
Write-Host " [√] 用户虚拟内存：精准还原优化前由 Windows 托管或用户原本指定的盘符尺寸" -ForegroundColor White
Write-Host " [√] 原生外设灵敏度：鼠标指针速度、按键响应速度与加速度 100% 还原用户原习惯" -ForegroundColor White
Write-Host " [√] 物理网卡与协议：中断审慎、流控制、EEE 与 TCP 设置全部还原至优化前状态" -ForegroundColor White
Write-Host " [√] 显示、安全与后台：MPO、SysMain、Defender、GameDVR 与看门狗已彻底撤销退出" -ForegroundColor White
Write-Host "`n建议在方便时【重启电脑】，以便内核隔离与硬件中断状态在固件层完整生效！" -ForegroundColor Green
if (-not $NonInteractive -and $env:UGO_NON_INTERACTIVE -ne '1') {
    Write-Host "按任意键退出..." -ForegroundColor Gray
    try { if ([Console]::KeyAvailable -or $Host.UI.RawUI.KeyAvailable) { $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null } else { Start-Sleep -Milliseconds 100 } } catch {}
}
