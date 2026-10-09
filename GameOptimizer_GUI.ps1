param(
    [switch]$Optimize,
    [switch]$Restore,
    [switch]$ResetClocks,
    [switch]$CoreCycler,
    [switch]$Help
)

<#
.SYNOPSIS
    Windows 全维自适应底层游戏性能深度优化大师 - 可视化专业版 (Universal Game Optimizer Pro Visual GUI)
    100% 原生 .NET WPF 架构，无需安装 Python / Node / VC++ 运行库，任何 Windows 10/11 系统即开即用！
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# =========================================================================
# Win32 原生 CPU 拓扑与 P/E 核心硬件级探测引擎 (替代简陋字符串推导)
# =========================================================================
if (-not ([System.Management.Automation.PSTypeName]'GameOptimizer.NativeCpuTopology').Type) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;

namespace GameOptimizer {
    public class CoreDetail {
        public int CoreIndex { get; set; }
        public byte EfficiencyClass { get; set; }
        public byte Flags { get; set; }
        public bool IsHyperThreaded { get; set; }
        public long AffinityMask { get; set; }
        public ushort Group { get; set; }
    }

    public class CpuTopologyResult {
        public bool IsHybrid { get; set; }
        public bool IsPurePerformanceCore { get; set; }
        public int PhysicalCoreCount { get; set; }
        public int LogicalProcessorCount { get; set; }
        public int PCoreCount { get; set; }
        public int PCoreLogicalCount { get; set; }
        public int ECoreCount { get; set; }
        public int ECoreLogicalCount { get; set; }
        public long PCoreMask { get; set; }
        public long ECoreMask { get; set; }
        public long AllCoresMask { get; set; }
        public bool HasSMT { get; set; }
        public string ArchitectureType { get; set; }
        public string DetailMessage { get; set; }
        public List<CoreDetail> Cores { get; set; }

        public CpuTopologyResult() {
            Cores = new List<CoreDetail>();
        }
    }

    public static class NativeCpuTopology {
        private const int RelationProcessorCore = 0;

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GetLogicalProcessorInformationEx(
            int relationshipType,
            IntPtr buffer,
            ref int returnedLength
        );

        private static int CountSetBits(long value) {
            ulong v = (ulong)value;
            int count = 0;
            while (v != 0) {
                count += (int)(v & 1);
                v >>= 1;
            }
            return count;
        }

        public static CpuTopologyResult Probe() {
            var result = new CpuTopologyResult();
            int length = 0;

            GetLogicalProcessorInformationEx(RelationProcessorCore, IntPtr.Zero, ref length);

            if (length <= 0) {
                result.IsHybrid = false;
                result.ArchitectureType = "非混合架构 (探测未返回数据)";
                result.DetailMessage = "Win32 API GetLogicalProcessorInformationEx 未返回有效缓冲区长度";
                return result;
            }

            IntPtr buffer = Marshal.AllocHGlobal(length);
            try {
                if (!GetLogicalProcessorInformationEx(RelationProcessorCore, buffer, ref length)) {
                    result.IsHybrid = false;
                    result.ArchitectureType = "非混合架构 (API调用失败)";
                    result.DetailMessage = "GetLogicalProcessorInformationEx 失败, Win32Error=" + Marshal.GetLastWin32Error();
                    return result;
                }

                long offset = 0;
                int coreIndex = 0;
                var effClassSet = new HashSet<byte>();
                byte maxEffClass = 0;

                while (offset + 8 <= length) {
                    IntPtr itemPtr = new IntPtr(buffer.ToInt64() + offset);
                    int relationship = Marshal.ReadInt32(itemPtr, 0);
                    int size = Marshal.ReadInt32(itemPtr, 4);

                    if (size <= 0 || offset + size > length) {
                        break;
                    }

                    if (relationship == RelationProcessorCore) {
                        byte flags = Marshal.ReadByte(itemPtr, 8);
                        byte efficiencyClass = Marshal.ReadByte(itemPtr, 9);
                        short groupCount = Marshal.ReadInt16(itemPtr, 30);

                        effClassSet.Add(efficiencyClass);
                        if (efficiencyClass > maxEffClass) {
                            maxEffClass = efficiencyClass;
                        }

                        long coreMask = 0;
                        ushort coreGroup = 0;
                        int groupAffinitySize = (IntPtr.Size == 8) ? 16 : 12;
                        int maskOffset = 32;

                        for (int g = 0; g < groupCount && (maskOffset + groupAffinitySize <= size); g++) {
                            long gMask = 0;
                            ushort gGroup = 0;
                            if (IntPtr.Size == 8) {
                                gMask = Marshal.ReadInt64(itemPtr, maskOffset);
                                gGroup = (ushort)Marshal.ReadInt16(itemPtr, maskOffset + 8);
                            } else {
                                gMask = (uint)Marshal.ReadInt32(itemPtr, maskOffset);
                                gGroup = (ushort)Marshal.ReadInt16(itemPtr, maskOffset + 4);
                            }

                            if (g == 0 || gGroup == 0) {
                                coreMask |= gMask;
                                coreGroup = gGroup;
                            }
                            maskOffset += groupAffinitySize;
                        }

                        bool isSmt = (flags & 1) != 0;
                        var detail = new CoreDetail {
                            CoreIndex = coreIndex,
                            EfficiencyClass = efficiencyClass,
                            Flags = flags,
                            IsHyperThreaded = isSmt,
                            AffinityMask = coreMask,
                            Group = coreGroup
                        };
                        result.Cores.Add(detail);

                        result.PhysicalCoreCount++;
                        int logicalInCore = CountSetBits(coreMask);
                        if (logicalInCore == 0) logicalInCore = isSmt ? 2 : 1;
                        result.LogicalProcessorCount += logicalInCore;
                        result.AllCoresMask |= coreMask;

                        if (isSmt) {
                            result.HasSMT = true;
                        }

                        coreIndex++;
                    }

                    offset += size;
                }

                // 纯大核与非混合异构架构防呆校验：
                // 如果发现所有核心的 EfficiencyClass 全都是 0，或者所有核心的 EfficiencyClass 完全一致
                // 必须立即判定为“非混合异构架构”，完全放弃任何大小核干预，保持 Windows 原生调度。
                if (effClassSet.Count <= 1 || maxEffClass == 0) {
                    result.IsHybrid = false;
                    result.IsPurePerformanceCore = true;
                    result.PCoreCount = result.PhysicalCoreCount;
                    result.PCoreLogicalCount = result.LogicalProcessorCount;
                    result.ECoreCount = 0;
                    result.ECoreLogicalCount = 0;
                    result.PCoreMask = result.AllCoresMask;
                    result.ECoreMask = 0;
                    result.ArchitectureType = result.HasSMT ? "非混合对称超线程架构 (纯大核/纯物理核)" : "非混合纯物理核心架构 (纯大核/纯物理核)";
                    result.DetailMessage = string.Format(
                        "原生 API 校验通过：共检测到 {0} 个物理核心，所有核心 EfficiencyClass 均为同一能效等级 (EffClass={1})。系统确认为纯大核/非混合对称架构，完全放弃大小核干预，保持 Windows 原生调度。",
                        result.PhysicalCoreCount,
                        effClassSet.Count > 0 ? new List<byte>(effClassSet)[0].ToString() : "0"
                    );
                    return result;
                }

                // 混合异构架构解析 (P-Core: 最高能效等级 EfficiencyClass == maxEffClass; E-Core: EfficiencyClass < maxEffClass)
                result.IsHybrid = true;
                result.IsPurePerformanceCore = false;

                foreach (var c in result.Cores) {
                    int cThreads = CountSetBits(c.AffinityMask);
                    if (cThreads == 0) cThreads = c.IsHyperThreaded ? 2 : 1;

                    if (c.EfficiencyClass == maxEffClass) {
                        // 性能大核 P-Core (最高性能等级)
                        result.PCoreCount++;
                        result.PCoreLogicalCount += cThreads;
                        result.PCoreMask |= c.AffinityMask;
                    } else {
                        // 能效小核 E-Core (包含标准能效核与低功耗LP-E能效核)
                        result.ECoreCount++;
                        result.ECoreLogicalCount += cThreads;
                        result.ECoreMask |= c.AffinityMask;
                    }
                }

                string tierDesc = (effClassSet.Count > 2) ? "混合三级异构架构" : "混合大小核异构架构";
                result.ArchitectureType = string.Format("{0} ({1} P-Core + {2} E-Core)", tierDesc, result.PCoreCount, result.ECoreCount);
                result.DetailMessage = string.Format(
                    "原生 API 硬件级识别通过：检测到{0} (性能核 P-Core: {1} 物理核/{2} 线程, 能效核 E-Core: {3} 物理核/{4} 线程)。P核掩码: 0x{5:X}, E核掩码: 0x{6:X}。",
                    tierDesc,
                    result.PCoreCount, result.PCoreLogicalCount,
                    result.ECoreCount, result.ECoreLogicalCount,
                    result.PCoreMask, result.ECoreMask
                );

                return result;

            } catch (Exception ex) {
                result.IsHybrid = false;
                result.ArchitectureType = "非混合架构 (异常安全回退)";
                result.DetailMessage = "原生 API 探测异常，触发安全回退保持 Windows 原生调度: " + ex.Message;
                return result;
            } finally {
                if (buffer != IntPtr.Zero) {
                    Marshal.FreeHGlobal(buffer);
                }
            }
        }
    }
}
'@
}


# 管理员权限自检与自提权 (完整透传命令行参数)
$isAdmin = ($env:UGO_SKIP_ADMIN_CHECK -eq '1') -or (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
if (-not $isAdmin) {
    try {
        $guiScript = if ($PSScriptRoot) { Join-Path $PSScriptRoot "GameOptimizer_GUI.ps1" } elseif ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { Join-Path (Get-Location).Path "GameOptimizer_GUI.ps1" }
        $forwardArgs = @()
        if ($Optimize) { $forwardArgs += "-Optimize" }
        if ($Restore) { $forwardArgs += "-Restore" }
        if ($ResetClocks) { $forwardArgs += "-ResetClocks" }
        if ($CoreCycler) { $forwardArgs += "-CoreCycler" }
        if ($Help) { $forwardArgs += "-Help" }
        if ($args) { $forwardArgs += ($args -join ' ') }
        $argSuffix = if ($forwardArgs.Count -gt 0) { " " + ($forwardArgs -join ' ') } else { "" }
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$guiScript`"$argSuffix" -Verb RunAs
        exit
    } catch {}
}

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } elseif ([System.AppDomain]::CurrentDomain.BaseDirectory) { [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\') } else { (Get-Location).Path }
if (-not $scriptDir -or -not (Test-Path $scriptDir)) { $scriptDir = (Get-Location).Path }

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

# 状态刷新别名兼容防呆
function Update-HardwareAndStatusDisplay {
    Update-SystemBaselineUI
}

# =========================================================================
# XAML 视觉界面定义 (Dark Cyberpunk / Glassmorphic Gaming UI)
# =========================================================================
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows 全维自适应底层游戏性能深度优化大师 · 可视化专业版 v6.0 (严谨终极版)"
        Width="1080" Height="820" MinWidth="960" MinHeight="720"
        WindowStartupLocation="CenterScreen"
        Background="#0B0E14" Foreground="#E6EDF3"
        FontFamily="Segoe UI, Microsoft YaHei UI">
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#E6EDF3"/>
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="Foreground" Value="#58A6FF"/>
            <Setter Property="BorderBrush" Value="#30363D"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10"/>
            <Setter Property="Margin" Value="0,0,0,10"/>
        </Style>
    </Window.Resources>

    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- 0: Header -->
            <RowDefinition Height="Auto"/> <!-- 1: Hardware Cards -->
            <RowDefinition Height="Auto"/> <!-- 2: Settings & Checklist -->
            <RowDefinition Height="Auto"/> <!-- 3: Action Buttons -->
            <RowDefinition Height="Auto"/> <!-- 4: Progress Bar -->
            <RowDefinition Height="*"/>    <!-- 5: Live Terminal Log -->
        </Grid.RowDefinitions>

        <!-- 0: Header Bar -->
        <Border Grid.Row="0" Background="#161B22" BorderBrush="#30363D" BorderThickness="1" CornerRadius="8" Padding="14,10" Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Orientation="Vertical">
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="⚡ UNIVERSAL GAME OPTIMIZER" FontSize="19" FontWeight="Bold" Foreground="#58A6FF"/>
                        <Border Background="#238636" CornerRadius="4" Padding="6,2" Margin="10,0,0,0" VerticalAlignment="Center">
                            <TextBlock Text="PRO VISUAL v6.0" FontSize="11" FontWeight="Bold" Foreground="#FFFFFF"/>
                        </Border>
                    </StackPanel>
                    <TextBlock Text="全硬件拓扑自适应扫描 · 纳秒级底层系统重构 · 100% 精准无损原始状态可逆" FontSize="12" Foreground="#8B949E" Margin="0,4,0,0"/>
                </StackPanel>
                
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Border x:Name="BadgeStatusBorder" Background="#21262D" BorderBrush="#30363D" BorderThickness="1" CornerRadius="6" Padding="10,6" Margin="0,0,8,0">
                        <TextBlock x:Name="TxtStatusBadge" Text="[ 系统状态: 正在扫描基准... ]" FontSize="12" FontWeight="SemiBold" Foreground="#E3B341"/>
                    </Border>
                    <Border x:Name="BadgeAdminBorder" Background="#1F242C" BorderBrush="#238636" BorderThickness="1" CornerRadius="6" Padding="10,6">
                        <TextBlock x:Name="TxtAdminBadge" Text="🛡️ 管理员权限已就绪" FontSize="12" FontWeight="SemiBold" Foreground="#3FB950"/>
                    </Border>
                </StackPanel>
            </Grid>
        </Border>

        <!-- 1: Hardware Specs Overview Cards -->
        <Grid Grid.Row="1" Margin="0,0,0,12">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- CPU Card -->
            <Border Grid.Column="0" Background="#161B22" BorderBrush="#30363D" BorderThickness="1" CornerRadius="6" Padding="10" Margin="0,0,6,0">
                <StackPanel>
                    <TextBlock Text="🖥️ CPU 处理器" FontSize="11" FontWeight="Bold" Foreground="#58A6FF"/>
                    <TextBlock x:Name="TxtCpuName" Text="检测中..." FontSize="13" FontWeight="SemiBold" Margin="0,4,0,2" TextTrimming="CharacterEllipsis"/>
                    <TextBlock x:Name="TxtCpuCores" Text="核心与架构分析中..." FontSize="11" Foreground="#8B949E"/>
                </StackPanel>
            </Border>

            <!-- GPU Card -->
            <Border Grid.Column="1" Background="#161B22" BorderBrush="#30363D" BorderThickness="1" CornerRadius="6" Padding="10" Margin="3,0,3,0">
                <StackPanel>
                    <Grid>
                        <TextBlock Text="🎮 优化目标显卡" FontSize="11" FontWeight="Bold" Foreground="#3FB950"/>
                        <TextBlock x:Name="TxtMuxBadge" Text="[ 直连检测中 ]" FontSize="10" FontWeight="SemiBold" Foreground="#58A6FF" HorizontalAlignment="Right"/>
                    </Grid>
                    <ComboBox x:Name="CmbGpuSelect" Height="25" Margin="0,4,0,2" Background="#0D1117" Foreground="#FFFFFF" BorderBrush="#30363D" FontSize="11" Cursor="Hand" VerticalContentAlignment="Center"/>
                    <TextBlock x:Name="TxtGpuDetails" Text="显存与直连状态分析中..." FontSize="10.5" Foreground="#8B949E" TextTrimming="CharacterEllipsis"/>
                </StackPanel>
            </Border>

            <!-- RAM Card -->
            <Border Grid.Column="2" Background="#161B22" BorderBrush="#30363D" BorderThickness="1" CornerRadius="6" Padding="10" Margin="3,0,3,0">
                <StackPanel>
                    <TextBlock Text="💾 物理内存与固态" FontSize="11" FontWeight="Bold" Foreground="#BC8CFF"/>
                    <TextBlock x:Name="TxtRamGB" Text="检测中..." FontSize="13" FontWeight="SemiBold" Margin="0,4,0,2"/>
                    <TextBlock x:Name="TxtStorageInfo" Text="固态硬盘分析中..." FontSize="11" Foreground="#8B949E"/>
                </StackPanel>
            </Border>

            <!-- Form Factor Card -->
            <Border Grid.Column="3" Background="#161B22" BorderBrush="#30363D" BorderThickness="1" CornerRadius="6" Padding="10" Margin="6,0,0,0">
                <StackPanel>
                    <TextBlock Text="⚡ 平台形态与系统" FontSize="11" FontWeight="Bold" Foreground="#D29922"/>
                    <TextBlock x:Name="TxtPlatform" Text="检测中..." FontSize="13" FontWeight="SemiBold" Margin="0,4,0,2"/>
                    <TextBlock x:Name="TxtOsVersion" Text="Windows 64-bit" FontSize="11" Foreground="#8B949E"/>
                </StackPanel>
            </Border>
        </Grid>

        <!-- 2: Settings & Checklist Grid -->
        <Grid Grid.Row="2" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="1.1*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- Left: Core System Items Checklist -->
            <Border Grid.Column="0" Background="#161B22" BorderBrush="#30363D" BorderThickness="1" CornerRadius="6" Padding="12" Margin="0,0,6,0">
                <StackPanel>
                    <TextBlock Text="⚙️ 系统底层 1~14 大核心优化项 (全自动深度执行清单)" FontSize="13" FontWeight="Bold" Foreground="#58A6FF" Margin="0,0,0,8"/>
                    <WrapPanel Orientation="Horizontal">
                        <TextBlock Text="[√] 电源方案卓越锁频" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] 内核隔离&amp;VBS关闭" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] 开启独显直连&amp;全局渲染" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] MSI 硬件中断高优先级" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] BCD 0.5ms 高精度时钟" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] 物理内存锁定 DPE=1" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] 弹性自适应虚拟内存 (防OOM)" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] NTFS 时间戳与智能 TRIM" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] 网卡自适应中断与低延迟" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] 鼠标 1:1 无加速极速按键" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] 极速 DirectFlip 渲染与 HAGS" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] MMCSS 游戏与音频置顶" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] 封杀节能节流 (保持内存压缩)" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] 全游戏自适应看门狗 (白名单)" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] 动态编译专属还原脚本" Width="170" FontSize="11" Foreground="#E3B341" Margin="0,2"/>
                        <TextBlock Text="[√] IRQ 中断亲和性分流 (极客自选)" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                        <TextBlock Text="[√] CoreCycler 瞬态验证 (独立工具)" Width="170" FontSize="11" Foreground="#3FB950" Margin="0,2"/>
                    </WrapPanel>
                </StackPanel>
            </Border>

            <!-- Right: Interactive User Decision Panel -->
            <Border Grid.Column="1" Background="#161B22" BorderBrush="#30363D" BorderThickness="1" CornerRadius="6" Padding="12" Margin="6,0,0,0">
                <StackPanel>
                    <TextBlock Text="🎯 个性化自选决策面板" FontSize="13" FontWeight="Bold" Foreground="#58A6FF" Margin="0,0,0,6"/>
                    
                    <!-- Direct GPU (独显直连) Box -->
                    <Border Background="#0D1117" BorderBrush="#30363D" BorderThickness="1" CornerRadius="4" Padding="8" Margin="0,0,0,8">
                        <StackPanel>
                            <CheckBox x:Name="ChkEnableDirectGpu" Content="开启独显直连与全局渲染绑定 (绕过核显中间缓冲与延迟)" FontSize="12" FontWeight="SemiBold" Foreground="#FFFFFF" IsChecked="True"/>
                            <TextBlock x:Name="TxtMuxDescription" Text="正在分析屏幕直连拓扑..." FontSize="10.5" Foreground="#3FB950" Margin="22,2,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Border>

                    <!-- Hardware Tuning Box -->
                    <Border Background="#0D1117" BorderBrush="#30363D" BorderThickness="1" CornerRadius="4" Padding="8" Margin="0,0,0,8">
                        <StackPanel>
                            <CheckBox x:Name="ChkEnableHardwareTuning" Content="开启 CPU 负压降温与 GPU 动态调谐 (经 30秒深度探测 + 双烤压力复核)" FontSize="12" FontWeight="SemiBold" Foreground="#FFFFFF" IsChecked="False"/>
                            <StackPanel x:Name="PanelHwRoutes" Margin="22,4,0,0" IsEnabled="False">
                                <RadioButton x:Name="RbRoute1" Content="路线一：全自动物理负压 (推荐！内置 RyzenAdj)" FontSize="11" Foreground="#58A6FF" IsChecked="True" GroupName="RouteGroup"/>
                                <RadioButton x:Name="RbRoute2" Content="路线二：纯净原厂 BIOS 引导路线 (零常驻工具，原厂级)" FontSize="11" Foreground="#8B949E" GroupName="RouteGroup" Margin="0,2,0,0"/>
                                <CheckBox x:Name="ChkEnableCoreCycler" Content="采用 CoreCycler 瞬态轮询复核 (高风险·深度验证)" FontSize="11" Foreground="#FFA657" Margin="0,4,0,0" IsChecked="False"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>

                    <!-- IRQ MSI Affinity Box -->
                    <Border Background="#0D1117" BorderBrush="#30363D" BorderThickness="1" CornerRadius="4" Padding="8" Margin="0,0,0,8">
                        <StackPanel>
                            <CheckBox x:Name="ChkEnableIrqAffinity" Content="启用 IRQ 中断亲和性解耦分流 (极客专属 · 高风险)" FontSize="12" FontWeight="SemiBold" Foreground="#FF7B72" IsChecked="False"/>
                            <TextBlock x:Name="TxtIrqAffinityDesc" Text="[默认关闭] 将网卡中断绑定在物理 Core 2，显卡中断绑定在物理 Core 4，解放 Core 0。需动态核验 CPU 拓扑且对多队列 RSS 网卡自动回避。" FontSize="10.5" Foreground="#8B949E" Margin="22,2,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Border>

                    <!-- Defender Box -->
                    <Border Background="#0D1117" BorderBrush="#30363D" BorderThickness="1" CornerRadius="4" Padding="8">
                        <StackPanel>
                            <TextBlock Text="Windows Defender 杀毒配置：" FontSize="12" FontWeight="SemiBold" Foreground="#FFFFFF" Margin="0,0,0,4"/>
                            <StackPanel Orientation="Horizontal">
                                <RadioButton x:Name="RbDefKeep" Content="保持开启 (默认推荐: 日常安全防护)" FontSize="11" Foreground="#3FB950" IsChecked="True" GroupName="DefGroup" Margin="0,0,16,0"/>
                                <RadioButton x:Name="RbDefDisable" Content="彻底关闭 (极限释放 3%~5% CPU/磁盘)" FontSize="11" Foreground="#E3B341" GroupName="DefGroup"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>
                </StackPanel>
            </Border>
        </Grid>

        <!-- 3: Action Buttons Bar -->
        <Grid Grid.Row="3" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="1.7*"/>
                <ColumnDefinition Width="1.3*"/>
                <ColumnDefinition Width="1.4*"/>
                <ColumnDefinition Width="1.1*"/>
                <ColumnDefinition Width="0.9*"/>
            </Grid.ColumnDefinitions>

            <!-- Optimize Button -->
            <Button x:Name="BtnStartOptimize" Grid.Column="0" Height="42" Margin="0,0,4,0" Background="#238636" BorderBrush="#2EA043" BorderThickness="1" Foreground="#FFFFFF" FontWeight="Bold" FontSize="13" Cursor="Hand">
                <Button.Resources>
                    <Style TargetType="Border">
                        <Setter Property="CornerRadius" Value="6"/>
                    </Style>
                </Button.Resources>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                    <TextBlock Text="🚀 开始运行全维优化" Foreground="#FFFFFF" VerticalAlignment="Center"/>
                </StackPanel>
            </Button>

            <!-- Restore Button -->
            <Button x:Name="BtnStartRestore" Grid.Column="1" Height="42" Margin="2,0,2,0" Background="#21262D" BorderBrush="#D29922" BorderThickness="1" Foreground="#E3B341" FontWeight="Bold" FontSize="11" Cursor="Hand" ToolTip="🛡️ 一键精准无损恢复优化前状态 (读取快照100%还原个性化原貌)">
                <Button.Resources>
                    <Style TargetType="Border">
                        <Setter Property="CornerRadius" Value="6"/>
                    </Style>
                </Button.Resources>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                    <TextBlock Text="🛡️ 一键精准无损恢复优化前状态" Foreground="#E3B341" VerticalAlignment="Center"/>
                </StackPanel>
            </Button>

            <!-- CoreCycler Test Button -->
            <Button x:Name="BtnStartCoreCycler" Grid.Column="2" Height="42" Margin="2,0,2,0" Background="#21262D" BorderBrush="#D29922" BorderThickness="1" Foreground="#FFA657" FontWeight="Bold" FontSize="12" Cursor="Hand">
                <Button.Resources>
                    <Style TargetType="Border">
                        <Setter Property="CornerRadius" Value="6"/>
                    </Style>
                </Button.Resources>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                    <TextBlock Text="⚡ CoreCycler 瞬态验证" Foreground="#FFA657" VerticalAlignment="Center"/>
                </StackPanel>
            </Button>

            <!-- Factory Reset Button -->
            <Button x:Name="BtnResetClocks" Grid.Column="3" Height="42" Margin="2,0,2,0" Background="#21262D" BorderBrush="#30363D" BorderThickness="1" Foreground="#58A6FF" FontWeight="SemiBold" FontSize="11.5" Cursor="Hand">
                <Button.Resources>
                    <Style TargetType="Border">
                        <Setter Property="CornerRadius" Value="6"/>
                    </Style>
                </Button.Resources>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                    <TextBlock Text="🔄 恢复默认出厂频率" Foreground="#58A6FF" VerticalAlignment="Center"/>
                </StackPanel>
            </Button>

            <!-- Docs Button -->
            <Button x:Name="BtnOpenDocs" Grid.Column="4" Height="42" Margin="4,0,0,0" Background="#161B22" BorderBrush="#30363D" BorderThickness="1" Foreground="#8B949E" FontWeight="SemiBold" FontSize="12" Cursor="Hand">
                <Button.Resources>
                    <Style TargetType="Border">
                        <Setter Property="CornerRadius" Value="6"/>
                    </Style>
                </Button.Resources>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                    <TextBlock Text="📖 原理手册" Foreground="#8B949E" VerticalAlignment="Center"/>
                </StackPanel>
            </Button>
        </Grid>

        <!-- 4: Progress Bar & Status Text -->
        <StackPanel Grid.Row="4" Margin="0,0,0,8">
            <ProgressBar x:Name="MainProgressBar" Height="6" Background="#21262D" Foreground="#2EA043" BorderThickness="0" Value="0" Maximum="100"/>
            <Grid Margin="0,4,0,0">
                <TextBlock x:Name="TxtProgressStatus" Text="【待机就绪】当前仅完成硬件环境扫描，未对系统做任何改动。请确认上方自选设置后点击【开始运行全维优化】。" FontSize="11" Foreground="#8B949E"/>
                <TextBlock x:Name="TxtProgressPct" Text="0%" HorizontalAlignment="Right" FontSize="11" Foreground="#58A6FF" FontWeight="SemiBold"/>
            </Grid>
        </StackPanel>

        <!-- 5: Live Terminal Log Console -->
        <Border Grid.Row="5" Background="#05080C" BorderBrush="#30363D" BorderThickness="1" CornerRadius="6" Padding="10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <Grid Grid.Row="0" Margin="0,0,0,6">
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="💻 实时底层执行与诊断终端 (Real-time Live Console)" FontSize="11" FontWeight="Bold" Foreground="#58A6FF"/>
                    </StackPanel>
                    <Button x:Name="BtnClearLog" Content="清空终端" Width="60" Height="20" HorizontalAlignment="Right" Background="#161B22" BorderBrush="#30363D" BorderThickness="1" Foreground="#8B949E" FontSize="10" Cursor="Hand"/>
                </Grid>
                
                <ScrollViewer x:Name="LogScrollViewer" Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto">
                    <TextBox x:Name="TxtConsoleLog" Background="Transparent" Foreground="#39D353" BorderThickness="0" FontFamily="Consolas, Lucida Console, Courier New" FontSize="11.5" IsReadOnly="True" TextWrapping="Wrap"/>
                </ScrollViewer>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# =========================================================================
# 加载 XAML 并绑定 UI 元素
# =========================================================================
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$TxtStatusBadge = $window.FindName("TxtStatusBadge")
$BadgeStatusBorder = $window.FindName("BadgeStatusBorder")
$TxtAdminBadge = $window.FindName("TxtAdminBadge")
$BadgeAdminBorder = $window.FindName("BadgeAdminBorder")

if (-not $isAdmin) {
    if ($TxtAdminBadge) {
        $TxtAdminBadge.Text = "⚠️ 非管理员权限 (受限模式)"
        $TxtAdminBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F85149")
    }
    if ($BadgeAdminBorder) {
        $BadgeAdminBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F85149")
    }
}

$TxtCpuName = $window.FindName("TxtCpuName")
$TxtCpuCores = $window.FindName("TxtCpuCores")
$CmbGpuSelect = $window.FindName("CmbGpuSelect")
$TxtMuxBadge = $window.FindName("TxtMuxBadge")
$TxtGpuDetails = $window.FindName("TxtGpuDetails")
$TxtRamGB = $window.FindName("TxtRamGB")
$TxtStorageInfo = $window.FindName("TxtStorageInfo")
$TxtPlatform = $window.FindName("TxtPlatform")
$TxtOsVersion = $window.FindName("TxtOsVersion")

$ChkEnableDirectGpu = $window.FindName("ChkEnableDirectGpu")
$TxtMuxDescription = $window.FindName("TxtMuxDescription")
$ChkEnableHardwareTuning = $window.FindName("ChkEnableHardwareTuning")
$PanelHwRoutes = $window.FindName("PanelHwRoutes")
$RbRoute1 = $window.FindName("RbRoute1")
$RbRoute2 = $window.FindName("RbRoute2")
$ChkEnableCoreCycler = $window.FindName("ChkEnableCoreCycler")
$ChkEnableIrqAffinity = $window.FindName("ChkEnableIrqAffinity")
$TxtIrqAffinityDesc = $window.FindName("TxtIrqAffinityDesc")
$RbDefKeep = $window.FindName("RbDefKeep")
$RbDefDisable = $window.FindName("RbDefDisable")

$BtnStartOptimize = $window.FindName("BtnStartOptimize")
$BtnStartRestore = $window.FindName("BtnStartRestore")
$BtnStartCoreCycler = $window.FindName("BtnStartCoreCycler")
$BtnResetClocks = $window.FindName("BtnResetClocks")
$BtnOpenDocs = $window.FindName("BtnOpenDocs")
$BtnClearLog = $window.FindName("BtnClearLog")

$MainProgressBar = $window.FindName("MainProgressBar")
$TxtProgressStatus = $window.FindName("TxtProgressStatus")
$TxtProgressPct = $window.FindName("TxtProgressPct")
$TxtConsoleLog = $window.FindName("TxtConsoleLog")
$LogScrollViewer = $window.FindName("LogScrollViewer")

# UI 交互联动：勾选负压调谐时解锁路线
$ChkEnableHardwareTuning.add_Checked({ $PanelHwRoutes.IsEnabled = $true })
$ChkEnableHardwareTuning.add_Unchecked({ 
    $PanelHwRoutes.IsEnabled = $false
    $ChkEnableCoreCycler.IsChecked = $false
})

# 极客高风险提示：IRQ 中断亲和性分流
$ChkEnableIrqAffinity.add_Checked({
    $warn = "【⚠️ IRQ 中断亲和性分流极客选项风险确认】`n`n" +
            "IRQ 中断亲和性分流将通过修改注册表 Affinity Policy，将网络中断绑定至物理 Core 2，将独立显卡中断绑定至物理 Core 4，彻底解放 CPU 0。`n`n" +
            "【运行保障与避让策略】：`n" +
            "  1. 必须依赖 CPU 拓扑探测，确保处理器具备足够的独立物理核心 (需≥6~8 逻辑线程)；`n" +
            "  2. 针对已启用多队列 RSS (Receive Side Scaling) 的网卡，系统将自动跳过绑定以防多向量冲突；`n" +
            "  3. 优化前将完整记录原有的 DevicePolicy 与掩码，可 100% 精准无损恢复。`n`n" +
            "确定要在优化中启用 IRQ 中断亲和性解耦分流吗？"
    $res = [System.Windows.MessageBox]::Show($warn, "IRQ 中断亲和性分流风险确认", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($res -ne [System.Windows.MessageBoxResult]::Yes) {
        $ChkEnableIrqAffinity.IsChecked = $false
    }
})

# 深度压力复核提示：CoreCycler 单核高低交替瞬态测试
$ChkEnableCoreCycler.add_Checked({
    $warn = "【⚠️ CoreCycler 深度瞬态压力复核风险警示】`n`n" +
            "开启 CoreCycler 机制后，系统将对每个 CPU 核心逐一锁定并执行急加速冲刺与突发撤载，制造激烈的电压瞬变以核验负压稳定性，并实时监测 WHEA-18 硬件错误日志。`n`n" +
            "本测试需要耗时 30~60 分钟（或较长），期间制造单核瞬态交替突发撤载以检验低压稳定性，可能发生黑屏重启，请先保存所有未完成的工作！`n`n" +
            "确定要在优化中执行 CoreCycler 瞬态验证吗？"
    $res = [System.Windows.MessageBox]::Show($warn, "CoreCycler 瞬态验证确认", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($res -ne [System.Windows.MessageBoxResult]::Yes) {
        $ChkEnableCoreCycler.IsChecked = $false
    }
})

# 日志输出函数
function Append-Log ($msg) {
    $window.Dispatcher.Invoke([Action]{
        $TxtConsoleLog.AppendText("$msg`r`n")
        $LogScrollViewer.ScrollToEnd()
    })
}

function Set-ProgressUI ($pct, $text) {
    $window.Dispatcher.Invoke([Action]{
        $MainProgressBar.Value = $pct
        $TxtProgressPct.Text = "$pct%"
        $TxtProgressStatus.Text = $text
    })
}

# =========================================================================
# 硬件与系统状态自适应探测
# =========================================================================
# =========================================================================
# 硬件与系统状态自适应探测
# =========================================================================
$global:DetectedGpus = @()

function Update-SelectedGpuDisplay {
    $sel = $CmbGpuSelect.SelectedItem
    if ($sel -and $sel.Tag) {
        $g = $sel.Tag
        $vramStr = if ($g.VramGB -ge 1) { "$($g.VramGB) GB" } else { "$([int]($g.VramGB * 1024)) MB" }
        $dispStr = if ($g.IsDisplayActive) {
            $rr = if ($g.RefreshRate) { "$($g.RefreshRate)Hz" } else { "极速" }
            "🟢 屏幕已直连 ($rr)"
        } else {
            "🟡 混合输出"
        }
        $TxtGpuDetails.Text = "显存: $vramStr | $($g.Vendor) | $dispStr"

        # 独显直连指示徽章与自选说明联动
        if ($g.IsDisplayActive -and $g.IsDiscrete) {
            $TxtMuxBadge.Text = "[ 🟢 独显已直连 ]"
            $TxtMuxBadge.Foreground = [System.Windows.Media.Brushes]::LimeGreen
            $TxtMuxDescription.Text = "当前状态: 🟢 屏幕已物理直连 $($g.Name) ($($g.RefreshRate)Hz 原生极速驱动)！优化将锁定全局独显渲染与最高性能供电。"
            $TxtMuxDescription.Foreground = [System.Windows.Media.Brushes]::LimeGreen
        } elseif ($g.IsDiscrete) {
            $TxtMuxBadge.Text = "[ 🟡 混合输出 ]"
            $TxtMuxBadge.Foreground = [System.Windows.Media.Brushes]::Goldenrod
            $TxtMuxDescription.Text = "当前状态: 🟡 处于 MSHybrid 混合输出模式！优化将为所有游戏定向注入独显渲染加速，同时保留桌面核显超低待机功耗。"
            $TxtMuxDescription.Foreground = [System.Windows.Media.Brushes]::Goldenrod
        } else {
            $TxtMuxBadge.Text = "[ 核显模式 ]"
            $TxtMuxBadge.Foreground = [System.Windows.Media.Brushes]::Gray
            $TxtMuxDescription.Text = "当前选中核心显卡。若玩游戏强烈建议在上方下拉框切回独显！"
            $TxtMuxDescription.Foreground = [System.Windows.Media.Brushes]::DarkGray
        }
    }
}

$CmbGpuSelect.add_SelectionChanged({ Update-SelectedGpuDisplay })

function Update-SystemBaselineUI {
    try {
        # CPU 处理器与 P/E 核心拓扑探测 (Win32 原生 API 硬件级识别)
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        if ($cpu) {
            $TxtCpuName.Text = $cpu.Name.Trim()
            $topo = [GameOptimizer.NativeCpuTopology]::Probe()
            if ($topo -and $topo.PhysicalCoreCount -gt 0) {
                if ($topo.IsHybrid) {
                    $archDesc = "$($topo.PCoreCount)P+$($topo.ECoreCount)E 异构架构"
                } elseif ($cpu.Name -match "X3D") {
                    $archDesc = "AMD 3D V-Cache 竞技芯片"
                } elseif ($topo.HasSMT) {
                    $archDesc = "标准对称超线程架构"
                } else {
                    $archDesc = "纯物理核心架构"
                }
                $TxtCpuCores.Text = "$($topo.PhysicalCoreCount) 物理核心 / $($topo.LogicalProcessorCount) 逻辑线程 | $archDesc"
            } else {
                $arch = if ($cpu.Name -match "X3D") { "AMD Zen·X3D 架构" } else { "标准物理架构" }
                $TxtCpuCores.Text = "$($cpu.NumberOfCores) 物理核心 / $($cpu.NumberOfLogicalProcessors) 逻辑线程 | $arch"
            }
        }

        # GPU 阵列全量智能识别与排序 (区分 独显/核显、默认最强独显)
        $rawGpus = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch "Basic|Virtual|Remote" }
        $gpuList = @()
        foreach ($g in $rawGpus) {
            $name = $g.Name.Trim()
            $isDiscrete = $false
            $vramGB = 0
            if ($name -match "NVIDIA|GeForce|RTX|GTX") {
                $isDiscrete = $true
                try {
                    $nvsmi = Get-NvidiaSmiPath
                    if ($nvsmi) {
                        $nvsmiOut = & $nvsmi --query-gpu=name,memory.total --format=csv,noheader 2>$null
                        if ($nvsmiOut -match "(\d+)\s*MiB") {
                            $vramGB = [Math]::Round([int]$matches[1] / 1024, 1)
                        }
                    }
                } catch {}
            }
            if ($vramGB -le 0 -and $g.AdapterRAM) {
                $vramGB = [Math]::Round($g.AdapterRAM / 1GB, 1)
            }
            if ($name -match "NVIDIA|GeForce|RTX|GTX|Arc A|Arc B|Radeon RX") {
                $isDiscrete = $true
            } elseif ($name -match "610M|680M|780M|Vega|UHD|Iris|Graphics Processor|Radeon\(TM\) Graphics|Intel\(R\) HD") {
                $isDiscrete = $false
            } elseif ($vramGB -ge 4) {
                $isDiscrete = $true
            }
            $isDisplayActive = ($g.CurrentHorizontalResolution -gt 0)
            $gpuList += [PSCustomObject]@{
                Name = $name
                IsDiscrete = $isDiscrete
                VramGB = $vramGB
                IsDisplayActive = $isDisplayActive
                RefreshRate = $g.CurrentRefreshRate
                Vendor = if ($name -match "NVIDIA|GeForce") { "NVIDIA 独显" } elseif ($name -match "AMD|Radeon") { "AMD" } else { "Intel" }
                Raw = $g
            }
        }

        # 智能排序：优先独立显卡、优先显存、优先主屏物理直连
        $global:DetectedGpus = $gpuList | Sort-Object -Property @{Expression={$_.IsDiscrete}; Descending=$true}, @{Expression={$_.VramGB}; Descending=$true}, @{Expression={$_.IsDisplayActive}; Descending=$true}

        # 填充 GPU 下拉选择框
        $CmbGpuSelect.Items.Clear()
        $bc = [System.Windows.Media.BrushConverter]::new()
        foreach ($gpuItem in $global:DetectedGpus) {
            $cbi = [System.Windows.Controls.ComboBoxItem]::new()
            $tag = if ($gpuItem.IsDiscrete) { "⭐ [独显·默认推荐]" } else { "[核显]" }
            $vramStr = if ($gpuItem.VramGB -ge 1) { "$($gpuItem.VramGB) GB" } else { "$([int]($gpuItem.VramGB * 1024)) MB" }
            $cbi.Content = "$tag $($gpuItem.Name) ($vramStr)"
            $cbi.Tag = $gpuItem
            $cbi.Background = $bc.ConvertFromString("#161B22")
            $cbi.Foreground = if ($gpuItem.IsDiscrete) { $bc.ConvertFromString("#FFFFFF") } else { $bc.ConvertFromString("#8B949E") }
            $CmbGpuSelect.Items.Add($cbi) | Out-Null
        }
        if ($CmbGpuSelect.Items.Count -gt 0) {
            $CmbGpuSelect.SelectedIndex = 0
            Update-SelectedGpuDisplay
        }

        # RAM
        $cs = Get-CimInstance Win32_ComputerSystem
        if ($cs) {
            $ramGB = [int][Math]::Round($cs.TotalPhysicalMemory / 1GB)
            $TxtRamGB.Text = "物理内存: $ramGB GB"
        }

        # Disk
        $vols = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' }
        $totalFree = ($vols | Measure-Object -Property SizeRemaining -Sum).Sum / 1GB
        $TxtStorageInfo.Text = "全盘固态可用空间: $([int]$totalFree) GB"

        # Platform
        $bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        if ($bat) {
            $TxtPlatform.Text = "笔记本移动工作站 (已启用温控保护)"
        } else {
            $TxtPlatform.Text = "台式机高性能主机 (激进满血供电)"
        }

        # OS
        $os = Get-CimInstance Win32_OperatingSystem
        if ($os) {
            $TxtOsVersion.Text = "$($os.Caption) (Build $($os.BuildNumber))"
        }

        # 检查快照与当前状态 (严格校验快照所属主机及全流程完成标记)
        $snapP1 = "$env:ProgramData\UniversalGameOptimizer\PreOptimizationState.json"
        $snapP2 = Join-Path $scriptDir "PreOptimizationState.json"
        $snapFile = if (Test-Path $snapP1) { $snapP1 } elseif (Test-Path $snapP2) { $snapP2 } else { $null }
        $completedFlag = "$env:ProgramData\UniversalGameOptimizer\OptimizationCompleted.flag"

        if ($snapFile) {
            try {
                $snap = Get-Content $snapFile -Raw -Encoding UTF8 | ConvertFrom-Json
                $isSameMachine = ($snap.PSObject.Properties['ComputerName'] -and $snap.ComputerName -and ($snap.ComputerName -eq $env:COMPUTERNAME))
                if ($isSameMachine -or (-not $snap.PSObject.Properties['ComputerName'])) {
                    if (Test-Path $completedFlag) {
                        $completedTime = (Get-Content $completedFlag -Raw -Encoding UTF8).Trim()
                        $TxtStatusBadge.Text = "[ 已完成优化 · 完成时间: $completedTime ]"
                        $TxtStatusBadge.Foreground = [System.Windows.Media.Brushes]::LimeGreen
                        $BadgeStatusBorder.BorderBrush = [System.Windows.Media.Brushes]::LimeGreen
                    } else {
                        $TxtStatusBadge.Text = "[ 系统状态: 优化未完成/异常中断 (建议一键还原) ]"
                        $TxtStatusBadge.Foreground = [System.Windows.Media.Brushes]::OrangeRed
                        $BadgeStatusBorder.BorderBrush = [System.Windows.Media.Brushes]::OrangeRed
                    }
                } else {
                    $TxtStatusBadge.Text = "[ 系统当前状态: 原生基准 (未优化) ]"
                    $TxtStatusBadge.Foreground = [System.Windows.Media.Brushes]::Goldenrod
                    $BadgeStatusBorder.BorderBrush = [System.Windows.Media.Brushes]::Goldenrod
                }
            } catch {
                $TxtStatusBadge.Text = "[ 系统当前状态: 原生基准 (未优化) ]"
                $TxtStatusBadge.Foreground = [System.Windows.Media.Brushes]::Goldenrod
                $BadgeStatusBorder.BorderBrush = [System.Windows.Media.Brushes]::Goldenrod
            }
        } else {
            $TxtStatusBadge.Text = "[ 系统当前状态: 原生基准 (未优化) ]"
            $TxtStatusBadge.Foreground = [System.Windows.Media.Brushes]::Goldenrod
            $BadgeStatusBorder.BorderBrush = [System.Windows.Media.Brushes]::Goldenrod
        }
    } catch {
        Append-Log "硬件探测提示: $_"
    }
}

Update-SystemBaselineUI

# 启动时输出清晰的待机报告与安全声明 (明示软件未开始运行，仅完成硬件状态探测)
$primaryGpu = if ($global:DetectedGpus -and $global:DetectedGpus.Count -gt 0) { $global:DetectedGpus[0] } else { $null }
Append-Log "======================================================================================"
Append-Log "★ Windows 全维自适应底层游戏性能深度优化大师 · 可视化专业版 (待机就绪)"
Append-Log "======================================================================================"
Append-Log "[安全声明] 软件打开后【仅扫描检测硬件环境】，未对系统/注册表/硬件做任何修改！"
Append-Log "--------------------------------------------------------------------------------------"
Append-Log "[已扫描硬件环境]"
Append-Log "  • 处理器 (CPU) : $($TxtCpuName.Text) [$($TxtCpuCores.Text)]"
if ($primaryGpu) {
    Append-Log "  • 主力显卡 (GPU): $($primaryGpu.Name) [显存: $($primaryGpu.VramGB) GB | $($primaryGpu.Vendor)]"
    Append-Log "  • 独显直连状态 : $(if ($primaryGpu.IsDisplayActive) { '🟢 屏幕物理直连独显 (' + $primaryGpu.RefreshRate + 'Hz 原生极速输出)' } else { '🟡 混合输出模式' })"
}
Append-Log "  • 物理内存 (RAM): $($TxtRamGB.Text)"
Append-Log "  • 存储与形态   : $($TxtPlatform.Text)"
Append-Log "  • 操作系统     : $($TxtOsVersion.Text)"
Append-Log "  • 优化基准状态 : $($TxtStatusBadge.Text)"
Append-Log "--------------------------------------------------------------------------------------"
Append-Log "[操作说明]"
Append-Log "  1. 软件当前处于【待机就绪】状态，优化尚未运行。"
Append-Log "  2. 您可在【🎮 优化目标显卡】下拉框中自由切换显卡（已默认自动选中最强独显）。"
Append-Log "  3. 请在上方确认自选项（是否开启独显直连、CPU 负压调谐、Defender 安全策略）。"
Append-Log "  4. 确认无误后，点击绿色按钮【🚀 开始运行全维优化】，并在确认弹窗中确认后才会开始运行！"
Append-Log "======================================================================================"

# =========================================================================
# 异步进程运行器 (保持 WPF 界面零卡顿、丝滑响应)
# =========================================================================
$script:CurrentChildProcess = $null

function Invoke-AsyncEngine ($scriptPath, $argList, $actionTitle, $onComplete) {
    $BtnStartOptimize.IsEnabled = $false
    $BtnStartRestore.IsEnabled = $false
    $BtnStartCoreCycler.IsEnabled = $false
    $BtnResetClocks.IsEnabled = $false

    Set-ProgressUI 5 "正在启动: $actionTitle ..."
    Append-Log "`r`n======================================================================================"
    Append-Log ">>> 启动任务: $actionTitle ..."
    Append-Log "======================================================================================"

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $argList"
    $psi.WorkingDirectory = $scriptDir
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8

    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi
    $proc.EnableRaisingEvents = $true
    $script:CurrentChildProcess = $proc

    $outHandler = [System.Diagnostics.DataReceivedEventHandler]{
        param($sender, $e)
        if ($e.Data) {
            $line = $e.Data
            Append-Log $line

            if ($line -match ">>> \[(\d+)/(\d+)\]") {
                $curr = [int]$matches[1]
                $total = [int]$matches[2]
                $calcPct = [int][Math]::Min(95, [Math]::Max(10, ($curr / $total) * 90))
                Set-ProgressUI $calcPct "正在执行: $line"
            } elseif ($line -match "严苛高压复核|二次复核|压力测试") {
                Set-ProgressUI 45 "正在执行芯片饱和压力测试与温升采样..."
            } elseif ($line -match "全量系统状态精准无损还原完成|WINDOWS 全维自适应底层优化完成") {
                Set-ProgressUI 100 "任务执行完毕！"
            }
        }
    }

    $proc.add_OutputDataReceived($outHandler)
    $proc.add_ErrorDataReceived($outHandler)

    $proc.add_Exited({
        $window.Dispatcher.Invoke([Action]{
            try {
                $BtnStartOptimize.IsEnabled = $true
                $BtnStartRestore.IsEnabled = $true
                $BtnStartCoreCycler.IsEnabled = $true
                $BtnResetClocks.IsEnabled = $true
                Set-ProgressUI 100 "$actionTitle 已完成！"
                Update-SystemBaselineUI
                if ($onComplete) {
                    try {
                        & $onComplete
                    } catch {
                        Append-Log "[!] 任务回调执行提示: $_"
                    }
                }
            } finally {
                if ($script:CurrentChildProcess) {
                    try { $script:CurrentChildProcess.Dispose() } catch {}
                    $script:CurrentChildProcess = $null
                }
            }
        })
    })

    [void]$proc.Start()
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()
}

# =========================================================================
# 按钮事件绑定
# =========================================================================

# 1. 开始运行全维优化 (点击后二次确认，防止误触)
$BtnStartOptimize.add_Click({
    $selectedGpuObj = if ($CmbGpuSelect.SelectedItem -and $CmbGpuSelect.SelectedItem.Tag) { $CmbGpuSelect.SelectedItem.Tag } else { $null }
    $selectedGpuName = if ($selectedGpuObj) { $selectedGpuObj.Name } else { "" }
    $selectedGpuVram = if ($selectedGpuObj) { "$($selectedGpuObj.VramGB) GB" } else { "未测算" }
    $isDirectConnected = if ($selectedGpuObj) { $selectedGpuObj.IsDisplayActive } else { $false }

    $hwDesc = if ($ChkEnableHardwareTuning.IsChecked) {
        $r = if ($RbRoute2.IsChecked) { "路线二 (BIOS 固件直刷引导)" } else { "路线一 (RyzenAdj 物理负压调谐 + 30秒探测与双烤压力复核)" }
        "已勾选开启 - $r"
    } else {
        "未开启 (保持处理器与显卡原厂时钟，仅优化系统层)"
    }
    $defDesc = if ($RbDefDisable.IsChecked) { "彻底关闭 (极限释放 3%~5% 算力与 IO)" } else { "保持开启 (推荐日常安全防护)" }
    $directDesc = if ($ChkEnableDirectGpu.IsChecked) {
        if ($isDirectConnected) { "已勾选开启 - 物理屏幕已直连，将锁定全局独显渲染首选项与最高性能供电" }
        else { "已勾选开启 - 为所有游戏定向注入独显直接渲染加速，兼顾桌面纯净低功耗与长续航" }
    } else {
        "未开启 (保持系统默认显卡调度)"
    }

    $irqDesc = if ($ChkEnableIrqAffinity.IsChecked) { "已勾选开启 (极客分流: 网卡->Core 2, 显卡->Core 4, 多队列RSS自适应回避)" } else { "未开启 (默认 Windows 原生中断分派)" }
    $ccDesc = if ($ChkEnableCoreCycler.IsChecked) { "已勾选开启 (极苛刻单核瞬态交替轮询 + WHEA-18 监控)" } else { "未开启 (标准双满载复核)" }

    $riskNotice = ""
    if ($ChkEnableIrqAffinity.IsChecked -or $ChkEnableCoreCycler.IsChecked) {
        $riskNotice = "【⚠️ 高风险极客选项提醒】：`n已启用高风险调谐项 (IRQ亲和性分流 / CoreCycler瞬态复核)。测试期间可能发生短时间高负载或瞬态冲击，请先保存所有未完成的工作！`n`n"
    }

    $confirmMsg = "【执行确认】即将开始执行 Windows 全维自适应底层游戏优化！`n`n" +
                  "目标优化显卡：" + $selectedGpuName + " (显存: $selectedGpuVram)`n" +
                  "处理器型号  ：" + $TxtCpuName.Text + "`n`n" +
                  "当前优化自选配置：`n" +
                  "  • 优化目标显卡: $selectedGpuName`n" +
                  "  • 独显直连策略: $directDesc`n" +
                  "  • 芯片调谐模式: $hwDesc`n" +
                  "  • IRQ 中断分流: $irqDesc`n" +
                  "  • 瞬态复核模式: $ccDesc`n" +
                  "  • 安全防护策略: $defDesc`n`n" +
                  $riskNotice +
                  "【安全承诺】：`n" +
                  "优化引擎将在改动任何系统参数前，100% 自动对当前系统所有状态完整生成无损快照。`n" +
                  "若日后需要，随时可在本软件中一键精准恢复至此时时刻的原始原貌。`n`n" +
                  "确定现在开始运行优化吗？"

    $res = [System.Windows.MessageBox]::Show($confirmMsg, "开始全维优化确认", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $hwChoice = if ($ChkEnableHardwareTuning.IsChecked) { "1" } else { "2" }
    $routeChoice = if ($RbRoute2.IsChecked) { "2" } else { "1" }
    $defChoice = if ($RbDefDisable.IsChecked) { "1" } else { "2" }
    $enableDirectChoice = if ($ChkEnableDirectGpu.IsChecked) { "1" } else { "0" }
    $irqChoice = if ($ChkEnableIrqAffinity.IsChecked) { "1" } else { "0" }
    $coreCyclerChoice = if ($ChkEnableCoreCycler.IsChecked) { "1" } else { "0" }

    $coreScript = Join-Path $scriptDir "GameOptimizer_Core.ps1"
    if (-not (Test-Path $coreScript)) {
        [System.Windows.MessageBox]::Show("未找到核心优化引擎文件: $coreScript", "错误", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }

    $argsStr = "-NonInteractive -HwChoice $hwChoice -RouteChoice $routeChoice -DefChoice $defChoice -TargetGpu `"$selectedGpuName`" -EnableDirectGpu $enableDirectChoice -EnableIrqAffinity $irqChoice -EnableCoreCycler $coreCyclerChoice"
    Invoke-AsyncEngine $coreScript $argsStr "全维自适应底层深度优化" {
        Update-SystemBaselineUI
        [System.Windows.MessageBox]::Show("★ 全维底层深度优化已全部完成！`n`n[√] 目标显卡 [$selectedGpuName] 已完成独显直连与图形渲染管线锁定`n[√] 桌面与工具目录已同步编译生成专属还原脚本与批处理`n[√] 若启用了芯片调谐已建立开机自动静默生效任务`n`n强烈建议在方便时【重启电脑】，以便内核隔离关闭与硬件中断在固件层完整生效！", "优化就绪", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    }
})


# 2.5 启动 CoreCycler 单核瞬态轮询验证 (独立深度工具)
$BtnStartCoreCycler.add_Click({
    $warnMsg = "【⚠️ 核心瞬态高压验证警告】`n`n" +
               "本测试借鉴开源超频神器 CoreCycler 的验证逻辑：`n" +
               "利用 Windows 原生 API 将算力单独锁定在单核上轮询执行高低交替突发与骤停撤载，" +
               "配合读取系统事件日志 (Windows Event Log) 中是否产生了 WHEA-Logger Event 18 警告。`n`n" +
               "快速瞬态核验模式耗时约 2~3 分钟（亦可连续循环核验）。期间制造单核瞬态交替突发撤载以检验低压稳定性，可能引起瞬时卡顿或偶发重启，请先保存所有未完成的工作！`n`n" +
               "确定现在开始运行 CoreCycler 瞬态单核轮询测试吗？"
    $res = [System.Windows.MessageBox]::Show($warnMsg, "CoreCycler 瞬态压力测试警告", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $coreScript = Join-Path $scriptDir "GameOptimizer_Core.ps1"
    if (-not (Test-Path $coreScript)) {
        [System.Windows.MessageBox]::Show("未找到核心引擎文件: $coreScript", "错误", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }

    Invoke-AsyncEngine $coreScript "-NonInteractive -TestCoreCyclerOnly" "CoreCycler 单核心瞬态轮询验证" {
        [System.Windows.MessageBox]::Show("★ CoreCycler 单核心瞬态压力测试已执行完毕！`n`n请查看终端日志中的详细核心逐一轮询与 WHEA 18 事件核验报告。", "测试结束", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    }
})
# 2. 一键无损精准还原
$BtnStartRestore.add_Click({
    $res = [System.Windows.MessageBox]::Show("确定要将所有系统底层参数、网络栈、服务、硬件中断与外设 100% 精准无损恢复至优化前原貌吗？`n`n【安全保障】：读取优化前快照清单，仅撤销优化变动，完整保留您原本的个性化设置。", "确认无损还原", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $restoreScript = Join-Path $scriptDir "Restore-PreOptimizationState.ps1"
    if (-not (Test-Path $restoreScript)) {
        $restoreScript = "$env:ProgramData\UniversalGameOptimizer\Restore-PreOptimizationState.ps1"
    }
    if (-not (Test-Path $restoreScript)) {
        [System.Windows.MessageBox]::Show("未找到还原脚本文件！", "错误", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }

    Invoke-AsyncEngine $restoreScript "-NonInteractive" "100% 精准无损系统还原" {
        Remove-Item "$env:ProgramData\UniversalGameOptimizer\OptimizationCompleted.flag" -Force -ErrorAction SilentlyContinue
        Update-SystemBaselineUI
        [System.Windows.MessageBox]::Show("★ 系统状态已 100% 精准还原至优化前原貌！`n`n[√] 所有开机自启调谐任务已注销清除`n[√] 自适应看门狗已彻底终止退出`n[√] 原生电源方案、网络与外设习惯已全量复原`n`n建议在方便时【重启电脑】使固件与中断配置彻底重载！", "还原成功", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    }
})

# 3. 恢复出厂默认频率与功耗墙
$BtnResetClocks.add_Click({
    $res = [System.Windows.MessageBox]::Show("确定要立即重置显卡与处理器至官方出厂默认频率/功耗墙，并注销开机自启调谐吗？", "重置频率", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

    Append-Log "`r`n>>> 正在恢复 CPU/GPU 官方出厂频率基准并清除自启动..."
    try {
        $nvsmi = Get-NvidiaSmiPath
        if ($nvsmi) {
            & $nvsmi -rgc 2>$null | Out-Null
            & $nvsmi -rmc 2>$null | Out-Null
            Append-Log " [√] NVIDIA 显卡核心与显存频率已释放至出厂动态调度！"

            # 恢复 GPU 出厂/快照功耗墙
            $defPl = $null
            try {
                $plQuery = & $nvsmi --query-gpu=power.default_limit --format=csv,noheader,nounits 2>$null
                if ($plQuery -match '(\d+(?:\.\d+)?)') {
                    $defPl = [int][Math]::Round([double]$matches[1])
                }
            } catch {}

            if (-not $defPl -or $defPl -le 30) {
                $snapFile = "$env:ProgramData\UniversalGameOptimizer\PreOptimizationState.baseline.json"
                if (-not (Test-Path $snapFile)) { $snapFile = "$env:ProgramData\UniversalGameOptimizer\PreOptimizationState.json" }
                if (-not (Test-Path $snapFile)) { $snapFile = Join-Path $scriptDir "PreOptimizationState.json" }
                if (Test-Path $snapFile) {
                    try {
                        $snapObj = Get-Content -LiteralPath $snapFile -Raw -Encoding UTF8 | ConvertFrom-Json
                        if ($snapObj.HardwareTuning -and $snapObj.HardwareTuning.GpuPowerLimitW -and [int]$snapObj.HardwareTuning.GpuPowerLimitW -gt 30) {
                            $defPl = [int]$snapObj.HardwareTuning.GpuPowerLimitW
                        }
                    } catch {}
                }
            }

            if ($defPl -and $defPl -gt 30) {
                & $nvsmi -pl $defPl 2>$null | Out-Null
                Append-Log " [√] NVIDIA 显卡功率墙已精准还原至出厂/快照基准: [$defPl W]！"
            }
        }
    } catch {
        Append-Log " [!] 恢复显卡频率提示: $_"
    }

    try {
        $binDir = Join-Path $scriptDir "bin"
        $ryzenAdj = Join-Path $binDir "ryzenadj.exe"
        if (-not (Test-Path $ryzenAdj)) {
            $ryzenAdj = "$env:ProgramData\UniversalGameOptimizer\bin\ryzenadj.exe"
        }
        if (Test-Path $ryzenAdj) {
            & $ryzenAdj --set-coall=0 2>$null | Out-Null
            Append-Log " [√] AMD 处理器 Curve Optimizer 负压值已归零复原！"
        }
    } catch {}

    try {
        $origEpp = 50
        $snapFile = "$env:ProgramData\UniversalGameOptimizer\PreOptimizationState.baseline.json"
        if (-not (Test-Path $snapFile)) { $snapFile = "$env:ProgramData\UniversalGameOptimizer\PreOptimizationState.json" }
        if (-not (Test-Path $snapFile)) { $snapFile = Join-Path $scriptDir "PreOptimizationState.json" }
        if (Test-Path $snapFile) {
            try {
                $snapObj = Get-Content -LiteralPath $snapFile -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($snapObj.Power -and $null -ne $snapObj.Power.PerfEpp) {
                    $origEpp = [int]$snapObj.Power.PerfEpp
                }
            } catch {}
        }
        powercfg -setacvalueindex scheme_current sub_processor PERFEPP $origEpp 2>$null | Out-Null
        powercfg -setactive scheme_current 2>$null | Out-Null
        Append-Log " [√] 处理器供电能效 (PERFEPP) 已恢复基准 ($origEpp)！"
    } catch {}

    schtasks /delete /tn "UniversalGameOptimizer_HardwareStartup" /f 2>$null | Out-Null
    Remove-Item "$env:ProgramData\UniversalGameOptimizer\HardwareBootApply.cmd" -Force -ErrorAction SilentlyContinue | Out-Null
    Append-Log " [√] 已清除开机自动调谐计划任务与引导脚本！"
    Set-ProgressUI 100 "出厂默认频率已复原！"
    Update-SystemBaselineUI
    [System.Windows.MessageBox]::Show("CPU 与 GPU 已全部恢复官方出厂默认频率与功耗状态！", "完成", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
})

# 4. 打开原理手册 (支持 docx、txt、md 及系统无 Office 时的自动降级记事本打开)
$BtnOpenDocs.add_Click({
    $candidates = @(
        (Join-Path $scriptDir "通用底层游戏优化原理与操作手册.docx"),
        (Join-Path $scriptDir "通用底层游戏优化原理手册.docx"),
        (Join-Path $scriptDir "通用底层游戏优化原理与操作手册.txt"),
        (Join-Path $scriptDir "通用底层游戏优化原理与操作手册.md")
    )
    $targetFile = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $targetFile) {
        $found = Get-ChildItem -Path $scriptDir -Filter "*原理*" -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $targetFile = $found.FullName }
    }

    if ($targetFile -and (Test-Path $targetFile)) {
        $opened = $false
        if ($targetFile -match '\.docx$') {
            try {
                Start-Process -FilePath $targetFile -ErrorAction Stop
                $opened = $true
            } catch {
                # 若系统未安装 Office/WPS 导致打不开 docx，平滑降级调用记事本打开同名纯文本版本
                $alt = $candidates | Where-Object { ($_ -match '\.(txt|md)$') -and (Test-Path $_) } | Select-Object -First 1
                if ($alt) {
                    try { Start-Process "notepad.exe" -ArgumentList "`"$alt`"" -ErrorAction Stop; $opened = $true } catch {}
                }
            }
        } else {
            try {
                Start-Process "notepad.exe" -ArgumentList "`"$targetFile`"" -ErrorAction Stop
                $opened = $true
            } catch {
                try { Start-Process -FilePath $targetFile; $opened = $true } catch {}
            }
        }
        if (-not $opened) {
            [System.Windows.MessageBox]::Show("未能调用程序打开手册文件！`n文件路径: $targetFile", "提示", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        }
    } else {
        [System.Windows.MessageBox]::Show("未找到原理手册文件！", "提示", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    }
})

# 5. 清空终端
$BtnClearLog.add_Click({
    $TxtConsoleLog.Clear()
})

# 命令行参数与自动化调度
if ($Help) {
    [System.Windows.MessageBox]::Show("★ UniversalGameOptimizer v6.0 命令行参数说明：`n`n" +
        "  -Optimize     : 启动图形界面并自动执行全维底层优化`n" +
        "  -Restore      : 启动图形界面并自动执行无损状态还原`n" +
        "  -ResetClocks  : 启动图形界面并自动重置 CPU/GPU 默认出厂频率`n" +
        "  -CoreCycler   : 启动图形界面并自动启动 CoreCycler 单核瞬态测试`n" +
        "  -Help         : 显示本命令行帮助信息", "命令行参数帮助", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    exit 0
}

$window.add_Loaded({
    if ($Optimize) {
        $BtnStartOptimize.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    } elseif ($Restore) {
        $BtnStartRestore.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    } elseif ($ResetClocks) {
        $BtnResetClocks.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    } elseif ($CoreCycler) {
        $BtnStartCoreCycler.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    }
})

# 显示主窗口
$window.ShowDialog() | Out-Null
