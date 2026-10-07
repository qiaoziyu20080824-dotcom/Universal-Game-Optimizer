# Universal Game Optimizer (Windows 全维自适应底层游戏性能深度优化大师)

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%20Windows%2011%20(64--bit)-0078D6.svg)](https://microsoft.com/windows)
[![Dependency](https://img.shields.io/badge/Dependencies-Zero%20Runtime%20Required-success.svg)]()
[![Safety](https://img.shields.io/badge/Safety-100%25%20Precision%20Reversible-brightgreen.svg)]()
[![Architecture](https://img.shields.io/badge/Architecture-Native%20Win32%20API%20%2B%20P%2FInvoke-orange.svg)]()

> **打造极致纯净、零微卡顿、毫秒级响应的专业级电竞 Windows 底层调度运行环境。**  
> 100% 拒绝机械死板的硬编码，全面针对目标电脑的物理拓扑、能效核心与散热体质实施动态自适应精准调优。

---

## 🌟 核心特性与架构承诺

1. **零外部依赖 (Zero Dependency)**  
   纯 Windows 原生架构设计，无需安装 Python、Node.js 或 VC++ 运行库。解压即用，即开即走。
2. **100% 精准无损可逆 (100% Precision Reversible)**  
   优化前全维深度捕获真实硬件状态快照（`PreOptimizationState.json`，涵盖原电源方案 GUID、原能效策略、原外设灵敏度、原网卡硬件属性及 Defender 基线）。拒绝盲目套用虚假出厂默认，随时支持一键 100% 完美复原。
3. **待机纯净与安全防呆 (Safe by Default)**  
   打开程序仅扫描并呈现硬件画像，绝不擅自更改任何系统设置；高风险极客项目默认关闭并设显式二次确认。
4. **Win32 原生硬件级拓扑自适应**  
   调用 Windows 原生底层 API（`GetLogicalProcessorInformationEx`）穿透探测硬件级能效等级（`EfficiencyClass`），智能识别混合异构（Intel P/E 核心）与非混合架构；针对 AMD 双 CCD（如 7900X3D）精准识别 3D V-Cache 线程拓扑，规避跨总线延迟。

---

## 🚀 快速上手

### 推荐方式：现代化赛博可视化控制中心
1. 直接双击运行目录内的 `UniversalGameOptimizer.exe`；
2. 在 UAC 提示窗口点击【是】以管理员权限启动；
3. 自由确认配置选项后，点击【立即执行全维底层游戏优化】。

### 备用方式：无 GUI 命令行静默执行
* 直接右键管理员运行 `【备用】一键启动可视化优化中心.bat`。

---

## ⚙️ 核心优化项目清单

* [x] **电源方案与核心解禁**：解锁原生“卓越性能 (Ultimate Performance)”方案，CPU Core Unparking 100% 满频解禁；
* [x] **内核隔离与虚拟化安全**：深度关闭内核隔离 (HVCI) 与 VBS，恢复 CPU 裸金属裸机算力；
* [x] **独显直连与渲染通道**：全局锁定旗舰独立显卡直接渲染通道，绕过核显中转损耗；
* [x] **MSI 硬件消息中断**：PCIe 独立显卡与物理网卡全面开启 Message Signaled Interrupts (MSI) 并锁定 High 优先级；
* [x] **高精度全局系统时钟**：锁定 0.5ms~1ms 全局高精度硬件时钟，彻底消除微秒级跳帧微卡顿；
* [x] **物理内存驻留锁定**：开启 `DisablePagingExecutive=1`，确保系统内核与关键驱动 100% 驻留物理内存；
* [x] **双驱弹性动态虚拟内存**：C 盘保留崩溃转储分页，高速盘建立弹性虚拟内存池，杜绝 3A 大作 OOM 闪退；
* [x] **存储 I/O 开销削减**：关闭 NTFS 访问时间戳与 8.3 短文件名，保持 Windows 原生空闲智能 TRIM 调度；
* [x] **低延迟竞技网络栈**：解除系统网络节流，全面放行 UDP 竞技微包，禁用网卡流控制与能效节能休眠；
* [x] **外设 1:1 像素级对齐**：彻底关闭鼠标指针加速度，封杀 USB 控制器空闲挂起休眠；
* [x] **现代图形调度与 DirectFlip**：开启 HAGS 硬件加速 GPU 调度与原生 MPO/DirectFlip 独立翻转层，消除无边框窗口化延迟；
* [x] **MMCSS 音频与游戏置顶**：开火音画毫秒同步，语音连麦开黑零爆音零卡顿；
* [x] **后台暗箭彻底拔除**：封杀 Windows EcoQoS 节能节流，保留 SysMain 原生内存压缩。

---

## 🔬 进阶极客专属功能

### 1. 科学 CPU 负压与 GPU 动态功耗墙
* **极其安全的保守步进**：AMD Curve Optimizer 全核负压幅度严格限制在极其安全的 `-5 ~ -10 Counts`（默认 `-8 Counts`，约 -30mV），既压制高负载积热，又彻底杜绝待机空闲低电压死机。
* **CoreCycler 瞬态轮询稳定性验证**：采用单核心高低交替瞬态负载冲击模型，配合 Windows 事件日志检测 WHEA-Logger Event 18 警告，唯有验证通过方可持久化生效。

### 2. IRQ 中断亲和性解耦分流 (MSI Interrupt Core Affinity)
* 利用 Windows 注册表 `Affinity Policy` 机制，将物理网卡硬件中断绑定至物理 Core 2，将显卡渲染中断绑定至物理 Core 4，彻底将 Core 0 从繁重的 DPC 硬件中断中解放出来，大幅压平 DPC 延迟峰值。
* 具备硬件拓扑动态防呆校验，杜绝非法掩码注入。

---

## 🛡️ 一键无损还原机制

系统配备双重还原防护网：
1. **专属动态编译还原脚本**：优化运行完毕后，系统将根据您的本次自选决策与硬件扫描结果，动态实时编译生成唯一的 `Restore-PreOptimizationState.ps1`；
2. **双桌面快捷入口**：
   * `一键还原优化前所有系统与硬件状态.bat`
   * `一键恢复CPU_GPU默认出厂频率.bat`

---

## 📂 项目目录结构

```
Universal_Game_Optimizer_GUI/
├── bin/
│   ├── ryzenadj.exe            # AMD SMU 底层通信组件
│   ├── libryzenadj.dll         # RyzenAdj 依赖动态库
│   ├── inpoutx64.dll           # 硬件端口 I/O 驱动支持
│   ├── WinRing0x64.dll         # Ring0 内核访问接口
│   └── WinRing0x64.sys         # Ring0 内核驱动程序
├── GameOptimizer_Core.ps1       # 全自动底层优化与自适应计算核心引擎
├── GameOptimizer_GUI.ps1        # WPF/XAML 现代化赛博暗黑可视化操作中心
├── Restore-PreOptimizationState.ps1 # 通用静态精准无损还原脚本
├── UniversalGameOptimizer.exe   # 原生无黑框快速启动器
├── 【使用说明】必看.txt          # 快速上手与功能详解指南
├── 通用底层游戏优化原理与操作手册.md # 深度底层原理与操作手册
└── README.md                    # 项目官方主页
```

---

## 📜 许可证

本项目基于 [MIT License](LICENSE) 开源。请在遵守当地法律法规及硬件安全规范的前提下使用。
