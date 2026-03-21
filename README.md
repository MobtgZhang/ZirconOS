# ZirconOS v1.0

**ZirconOS** 是一个 NT 风格混合微内核操作系统，使用 Zig 语言实现，支持 BIOS (GRUB Multiboot2) 和 UEFI 启动。

## 设计理念

- **NT 风格混合微内核**：内核提供调度、虚拟内存、IPC、中断、系统调用等核心机制
- **用户态系统服务**：Object Manager、Process Manager、I/O Manager、Security 等作为服务运行
- **Win32 兼容层**：ntdll + kernel32 + kernelbase + 控制台子系统
- **Win32 子系统服务器**：csrss 风格的子系统管理、窗口站、桌面
- **Win32 应用执行引擎**：PE 加载 + DLL 绑定 + 进程创建 + API dispatch
- **图形子系统**：user32 (窗口/消息) + gdi32 (绘图/字体/位图)
- **WOW64 兼容层**：PE32 加载 + 32→64 位 syscall thunking + 32 位 PEB/TEB
- **双 Shell 环境**：CMD 命令提示符 + PowerShell 高级 Shell
- **双文件系统**：FAT32 (系统分区) + NTFS (数据分区)
- **多架构支持**：x86_64（主要）、aarch64、loong64、riscv64、mips64el

设计文档：[`docs/README.md`](docs/README.md) | [`docs/Architecture.md`](docs/Architecture.md) | [`docs/Kernel.md`](docs/Kernel.md) | [`docs/Boot.md`](docs/Boot.md) | [`docs/BuildSystem.md`](docs/BuildSystem.md) | [`docs/Roadmap.md`](docs/Roadmap.md)

## 项目结构

```
ZirconOS/
├── build.zig              # Zig 构建配置
├── build.zig.zon          # Zig 依赖声明
├── run.sh                 # 构建与运行脚本
├── Makefile               # Make 便捷入口
├── config/                # 系统配置
│   ├── system.conf        #   系统核心参数
│   ├── boot.conf          #   引导配置
│   ├── desktop.conf       #   桌面环境配置（主题选择、分辨率、窗口管理）
│   └── defaults.zig       #   编译时嵌入配置数据
├── boot/
│   ├── grub/grub.cfg      # GRUB 引导配置 (系统选择菜单)
│   ├── uefi/main.zig      # UEFI 启动应用
│   └── zbm/               # ZirconOS Boot Manager (BIOS/MBR/GPT)
├── link/                  # 各架构链接脚本
│   └── x86_64.ld / aarch64.ld / loong64.ld / riscv64.ld / mips64el.ld
├── src/                   # 内核源码
│   ├── main.zig           # 内核入口 (Phase 0-11 启动流程)
│   ├── config/            # 配置解析器
│   ├── arch/              # 架构相关代码
│   │   ├── x86_64/        #   Multiboot2, 分页, IDT, ISR, Syscall
│   │   ├── aarch64/       #   AArch64 启动, 分页
│   │   └── (loong64, riscv64, mips64el)
│   ├── hal/               # 硬件抽象层
│   │   ├── x86_64/        #   VGA, PIC, PIT, Port I/O, Serial, GDT, Framebuffer
│   │   └── aarch64/       #   GIC, Timer, PL011 UART
│   ├── drivers/           # 设备驱动
│   │   └── video/         #   VGA, HDMI, Framebuffer, Display Manager
│   ├── ke/                # Kernel Executive - 调度, 定时, 中断, 同步
│   ├── mm/                # Memory Manager - 物理帧分配, 虚拟内存, 堆
│   ├── ob/                # Object Manager - 对象/句柄表/命名空间
│   ├── ps/                # Process Subsystem - 进程/线程管理
│   ├── se/                # Security - Token/SID/访问检查
│   ├── io/                # I/O Manager - 设备/驱动/IRP
│   ├── lpc/               # LPC - IPC 消息传递/Port
│   ├── rtl/               # Runtime Library - 内核日志
│   ├── fs/                # File Systems - VFS/FAT32/NTFS
│   ├── loader/            # Loader - PE32/PE32+/ELF
│   ├── libs/              # 用户态 API 库
│   │   ├── ntdll.zig      #   Native API (Nt*/Rtl*/Dbg*)
│   │   └── kernel32.zig   #   Win32 Base API
│   ├── servers/           # 系统服务
│   │   ├── server.zig     #   Process Server (PID 1)
│   │   └── smss.zig       #   Session Manager (SMSS)
│   └── subsystems/        # 子系统实现
│       └── win32/         #   Win32 子系统
│           ├── subsystem.zig  csrss 子系统服务器
│           ├── exec.zig       Win32 应用执行引擎
│           ├── user32.zig     窗口/消息 API
│           ├── gdi32.zig      图形设备接口 API
│           ├── console.zig    控制台运行时
│           ├── cmd.zig        CMD 命令提示符
│           ├── powershell.zig PowerShell
│           └── wow64.zig      WOW64 32位兼容层
├── 3rdparty/              # 桌面主题（独立 Git 仓库，需先拉取）
│   ├── themes.repos       #   各主题 clone URL 清单
│   ├── fetch-themes.sh    #   一键克隆全部主题到本目录
│   ├── ZirconOSClassic/   #   （克隆后）Windows 2000 经典主题
│   ├── ZirconOSLuna/      #   （克隆后）Windows XP Luna 主题 ★ 已完整实现
│   ├── ZirconOSAero/      #   （克隆后）Windows Vista/7 Aero 毛玻璃主题
│   ├── ZirconOSModern/    #   （克隆后）Windows 8/8.1 Metro 扁平磁贴主题
│   ├── ZirconOSFluent/    #   （克隆后）Windows 10 Fluent Design 主题
│   ├── ZirconOSSunValley/ #   （克隆后）Windows 11 Sun Valley 主题
│   └── README.md          #   桌面主题总览与 Git 地址说明
└── docs/                  # 设计文档
```

## 桌面主题

ZirconOS 支持六套 Windows 风格桌面主题，覆盖 Windows 2000 到 Windows 11 的完整视觉演进。
每套主题是独立的 Zig 子项目，源码在 **各自的 GitHub 仓库**；克隆主仓库后需先拉取到 `3rdparty/`：

```bash
./3rdparty/fetch-themes.sh
# 或: make fetch-themes
```

详见 [`3rdparty/README.md`](3rdparty/README.md) 中的仓库 URL 与 Submodule 说明。

| 主题 | Windows 版本 | 状态 | 特色 |
|------|-------------|------|------|
| Classic | Windows 2000 | 框架 | 3D 灰色按钮、直角窗口、极简高效 |
| **Luna** | **Windows XP** | **✅ 已实现** | 蓝色渐变任务栏、绿色开始按钮、圆角边框 |
| Aero | Vista / 7 | 框架 | 毛玻璃透明边框、Flip 3D、Aero Snap |
| Modern | Windows 8 | 框架 | 全屏磁贴、Metro 扁平化、Charms 栏 |
| Fluent | Windows 10 | 框架 | 亚克力材质、暗色模式、Reveal 效果 |
| Sun Valley | Windows 11 | 框架 | Mica 云母、大圆角、居中任务栏 |

桌面主题由 `config/desktop.conf` 配置选择：

```ini
[desktop]
theme = luna              # classic | luna | aero | modern | fluent | sunvalley
color_scheme = blue       # 主题特定配色方案
```

详细文档：[`3rdparty/README.md`](3rdparty/README.md)

## 依赖

Ubuntu/Debian：

```bash
sudo apt update
sudo apt install -y grub-pc-bin grub-common xorriso mtools \
    qemu-system-x86 qemu-system-arm ovmf
```

Zig 编译器：从 [ziglang.org](https://ziglang.org/download/) 下载并加入 PATH。

## 构建与运行

```bash
# 使用 run.sh（推荐）
./run.sh build              # 构建内核 (Debug)
./run.sh build-release      # 构建内核 (Release)
./run.sh iso                # 构建 ISO
./run.sh run                # 构建 ISO 并在 QEMU 中运行 (BIOS)
./run.sh run-debug          # BIOS + GDB 调试服务器
./run.sh run-release        # BIOS Release 模式
./run.sh run-uefi           # UEFI 模式运行 (x86_64)
./run.sh run-uefi-aarch64   # UEFI 模式运行 (aarch64)
./run.sh run-aarch64        # AArch64 裸机运行
./run.sh clean              # 清理构建产物
./run.sh help               # 查看帮助

# 使用 Make（简洁入口）
make run                    # 等同于 ./run.sh run
make run-debug              # 等同于 ./run.sh run-debug
make clean                  # 等同于 ./run.sh clean
make help                   # 查看帮助

# 使用 Zig 直接构建
zig build -Darch=x86_64 -Ddebug=true -Denable_idt=true
```

## v1.0 已实现 (Phase 0-11)

| 模块 | 状态 | 说明 |
|------|------|------|
| GRUB Boot | ✅ | Multiboot2 启动, x86_64, 多种启动模式 |
| UEFI Boot | ✅ | UEFI 启动应用, Debug/Release, Phase 0-11 信息 |
| VGA Output | ✅ | 文本模式控制台 |
| Serial | ✅ | COM1 串口输出 |
| Frame Allocator | ✅ | 位图物理帧分配器 |
| Paging | ✅ | 四级页表, identity mapping |
| Kernel Heap | ✅ | Bump 分配器 |
| IPC (LPC) | ✅ | 消息队列, send/receive, Port |
| Syscall | ✅ | int 0x80 分发 |
| IDT/ISR | ✅ | 中断描述符表 256 vectors |
| Scheduler | ✅ | Round-Robin 调度器 |
| Timer | ✅ | PIC + PIT ~100Hz |
| Sync | ✅ | Event, Mutex, Semaphore, SpinLock |
| Object Manager | ✅ | 对象类型/句柄表/命名空间/Waitable |
| Process Manager | ✅ | 进程/线程, Process Server |
| Session Manager | ✅ | SMSS, 会话管理, 子系统注册 |
| Security | ✅ | Token, SID, 访问检查 |
| I/O Manager | ✅ | 设备/驱动/IRP 分发 |
| VFS | ✅ | 虚拟文件系统, 挂载点 |
| FAT32 | ✅ | 文件创建/读写/目录/删除 (C:\) |
| NTFS | ✅ | MFT, 文件/目录操作 (D:\) |
| PE32+ Loader | ✅ | PE 头解析, DLL加载, 导入解析, 重定位, PEB/TEB |
| PE32 Loader | ✅ | 32位 PE 支持, WOW64 兼容 |
| ELF Loader | ✅ | ELF64 头解析, 段加载, 共享对象 |
| ntdll | ✅ | Native API (进程/线程/文件/同步/内存/IPC/系统/注册表/调试) |
| kernel32 | ✅ | Win32 Base API (进程/文件搜索/控制台/内存/模块/同步/环境) |
| user32 | ✅ | 窗口管理, 消息队列, 窗口类, UI 原语, 输入处理 |
| gdi32 | ✅ | 设备上下文, 绘图原语, 字体, 位图, BitBlt |
| Console | ✅ | 控制台运行时 |
| CMD Shell | ✅ | 命令提示符 (dir, cd, set, ver, systeminfo, tasklist 等) |
| PowerShell | ✅ | 高级 Shell (Get-Process, Get-ChildItem, Get-Service 等) |
| csrss | ✅ | Win32 子系统服务器, 窗口站, 桌面, 进程注册, GUI 分发 |
| Exec Engine | ✅ | Win32 应用执行引擎, PE加载, DLL绑定, 生命周期管理 |
| WOW64 | ✅ | 32位兼容层, PE32加载, syscall thunking, 32位PEB/TEB |

## 里程碑

- **Phase 0** ✅ 工具链 + QEMU 调试环境
- **Phase 1** ✅ Boot + Early Kernel (GDT/Multiboot2/Frame/Heap)
- **Phase 2** ✅ Trap / Timer / Scheduler
- **Phase 3** ✅ VM + User Mode (页表/地址空间)
- **Phase 4** ✅ Object / Handle / Process Core
- **Phase 5** ✅ IPC + System Services (SMSS/LPC)
- **Phase 6** ✅ I/O + File System (FAT32/NTFS) + Driver
- **Phase 7** ✅ Loader (PE32/PE32+/ELF, DLL管理, 导入解析, 重定位)
- **Phase 8** ✅ Native Userland (ntdll/kernel32 完整API/CMD/PowerShell)
- **Phase 9** ✅ Win32 Subsystem (csrss/exec引擎/应用执行/DLL绑定)
- **Phase 10** ✅ Graphical Subsystem (user32窗口管理/gdi32绘图/消息队列/GUI分发)
- **Phase 11** ✅ WOW64 (PE32加载/syscall thunking/32位PEB-TEB/兼容性测试)
