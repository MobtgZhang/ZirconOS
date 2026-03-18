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

设计文档：[`docs/README.md`](docs/README.md) | [`docs/refs.md`](docs/refs.md)

## 项目结构（NT Executive 风格）

```
ZirconOS/
├── build.zig              # Zig 构建系统
├── Makefile               # 便捷构建封装
├── boot/
│   ├── grub/grub.cfg      # GRUB 引导配置 (BIOS/UEFI Debug/Release)
│   └── uefi/main.zig      # UEFI 启动应用
├── link/                  # 各架构链接脚本
│   ├── x86_64.ld / aarch64.ld / loong64.ld / riscv64.ld / mips64el.ld
├── kernel/src/
│   ├── main.zig           # 内核入口 (Phase 0-11 启动流程)
│   ├── arch.zig           # 架构抽象分发层
│   ├── arch/              # 架构相关代码
│   │   ├── x86_64/        #   Multiboot2, 分页, IDT, ISR, Syscall
│   │   ├── aarch64/       #   AArch64 启动, 分页
│   │   └── (loong64, riscv64, mips64el stubs)
│   ├── hal/               # 硬件抽象层
│   │   ├── x86_64/        #   VGA, PIC, PIT, Port I/O, Serial, GDT
│   │   └── aarch64/       #   PL011 UART
│   ├── ke/                # Kernel Executive - 调度, 定时, 中断, 同步
│   ├── mm/                # Memory Manager - 物理帧分配, 虚拟内存, 堆
│   ├── ob/                # Object Manager - 对象/句柄表/命名空间/Waitable
│   ├── ps/                # Process Subsystem - 进程/线程/Server/SMSS
│   ├── se/                # Security - Token/SID/访问检查
│   ├── io/                # I/O Manager - 设备/驱动/IRP
│   ├── lpc/               # LPC - IPC 消息传递/Port
│   ├── fs/                # File Systems - VFS/FAT32/NTFS
│   ├── loader/            # Loader - PE32/PE32+/ELF/Section Mapping/DLL管理
│   ├── win32/             # Win32 子系统
│   │   ├── ntdll.zig      #   Native API (完整 Nt* / Rtl* / Dbg* 系列)
│   │   ├── kernel32.zig   #   Win32 Base API (进程/文件/控制台/内存/模块/同步)
│   │   ├── user32.zig     #   Window/Message API (窗口/消息队列/输入/UI)
│   │   ├── gdi32.zig      #   GDI API (DC/绘图/字体/位图/BitBlt)
│   │   ├── console.zig    #   控制台运行时 (conhost 风格)
│   │   ├── cmd.zig        #   CMD 命令提示符 (20+ 命令)
│   │   ├── powershell.zig #   PowerShell 7.4 (20+ cmdlets)
│   │   ├── subsystem.zig  #   Win32 子系统服务器 (csrss 风格)
│   │   ├── exec.zig       #   Win32 应用执行引擎
│   │   └── wow64.zig      #   WOW64 32位兼容层
│   └── rtl/               # Runtime Library - 内核日志
├── servers/               # 用户态系统服务（预留）
├── subsystems/            # 子系统：Win32/POSIX/WOW64（预留）
├── libs/                  # 用户态库：ntdll/kernel32（预留）
└── docs/                  # 设计文档
```

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
# 构建内核 (Debug)
make kernel

# 构建内核 (Release)
make kernel-release

# 构建 ISO 并在 QEMU 中运行 (BIOS)
make run-bios

# BIOS Debug 模式 (带 GDB 调试服务器)
make run-bios-debug

# BIOS Release 模式
make run-bios-release

# UEFI 模式运行
make run-uefi-x86_64

# UEFI Debug 模式 (带 GDB)
make run-uefi-debug

# UEFI Release 模式
make run-uefi-release

# AArch64
make run-aarch64

# 查看帮助
make help
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
| kernelbase | ✅ | Base API 转发器 |
| user32 | ✅ | 窗口管理, 消息队列, 窗口类, UI 原语, 输入处理 |
| gdi32 | ✅ | 设备上下文, 绘图原语, 字体, 位图, BitBlt |
| Console | ✅ | 控制台运行时 |
| CMD Shell | ✅ | 命令提示符 (dir, cd, set, ver, systeminfo, tasklist 等) |
| PowerShell | ✅ | 高级 Shell (Get-Process, Get-ChildItem, Get-Service 等) |
| csrss | ✅ | Win32 子系统服务器, 窗口站, 桌面, 进程注册, GUI 分发 |
| Exec Engine | ✅ | Win32 应用执行引擎, PE加载, DLL绑定, 生命周期管理 |
| WOW64 | ✅ | 32位兼容层, PE32加载, syscall thunking, 32位PEB/TEB |
| Debug/Release | ✅ | BIOS + UEFI 双模式, Debug日志/GDB/Release优化 |
| 多架构 | 🔧 | x86_64 完整, 其他 stub |

## NT 兼容层 API 覆盖

### ntdll.dll (Native API)

| 分类 | API |
|------|-----|
| 进程 | NtCreateProcess, NtTerminateProcess, NtQueryInformationProcess, NtSetInformationProcess |
| 线程 | NtCreateThread, NtTerminateThread, NtQueryInformationThread |
| 文件 | NtCreateFile, NtOpenFile, NtReadFile, NtWriteFile, NtClose, NtDeleteFile, NtQueryDirectoryFile |
| 对象 | NtCreateEvent, NtSetEvent, NtResetEvent, NtCreateMutant, NtCreateSemaphore |
| 同步 | NtWaitForSingleObject, NtWaitForMultipleObjects |
| 内存 | NtAllocateVirtualMemory, NtFreeVirtualMemory, NtProtectVirtualMemory, NtQueryVirtualMemory |
| Section | NtCreateSection, NtMapViewOfSection, NtUnmapViewOfSection |
| IPC | NtCreatePort, NtConnectPort, NtRequestWaitReplyPort |
| 系统 | NtQuerySystemInformation |
| 注册表 | NtOpenKey, NtCreateKey, NtQueryValueKey, NtSetValueKey |
| RTL | RtlGetVersion, RtlInitUnicodeString, RtlCopyMemory, RtlZeroMemory, RtlNtStatusToDosError |
| 调试 | DbgPrint, DbgBreakPoint |

### kernel32.dll (Win32 Base API)

| 分类 | API |
|------|-----|
| 进程 | CreateProcessA, ExitProcess, TerminateProcess, GetCurrentProcessId, WaitForSingleObject |
| 文件 | CreateFileA, ReadFile, WriteFile, CloseHandle, DeleteFileA, GetFileSize, GetFileAttributesA |
| 文件搜索 | FindFirstFileA, FindNextFileA, FindClose |
| 目录 | CreateDirectoryA, RemoveDirectoryA, GetCurrentDirectoryA, SetCurrentDirectoryA |
| 控制台 | GetStdHandle, WriteConsoleA, ReadConsoleA, AllocConsole, FreeConsole, SetConsoleTitleA |
| 内存 | VirtualAlloc, VirtualFree, HeapAlloc, HeapFree, LocalAlloc, GlobalAlloc |
| 模块 | LoadLibraryA, GetProcAddress, FreeLibrary, GetModuleHandleA, GetModuleFileNameA |
| 同步 | CreateEventA, CreateMutexA, CreateSemaphoreA, CriticalSection 系列, Sleep |
| 系统 | GetSystemInfo, GetVersionExA, GetTickCount, GetComputerNameA, GetUserNameA |
| 环境 | GetEnvironmentVariableA, SetEnvironmentVariableA, GetTempPathA, ExpandEnvironmentStringsA |
| 错误 | GetLastError, SetLastError |
| 调试 | OutputDebugStringA |

### user32.dll (Window/Message API)

| 分类 | API |
|------|-----|
| 窗口类 | RegisterClassA, RegisterClassExA, UnregisterClassA |
| 窗口创建 | CreateWindowExA, DestroyWindow |
| 窗口属性 | ShowWindow, UpdateWindow, EnableWindow, IsWindow, IsWindowVisible |
| 窗口布局 | SetWindowPos, MoveWindow, GetWindowRect, GetClientRect |
| 窗口文本 | SetWindowTextA, GetWindowTextA, GetWindowTextLengthA |
| 消息循环 | GetMessageA, PeekMessageA, TranslateMessage, DispatchMessageA |
| 消息发送 | PostMessageA, SendMessageA, PostQuitMessage |
| 焦点/激活 | SetFocus, GetFocus, SetActiveWindow, GetActiveWindow, SetForegroundWindow |
| 绘制 | BeginPaint, EndPaint, InvalidateRect, GetDC, ReleaseDC |
| 输入 | SetCapture, ReleaseCapture, GetCapture |
| 定时器 | SetTimer, KillTimer |
| 对话框 | MessageBoxA |
| 系统 | GetSystemMetrics, GetDesktopWindow, DefWindowProcA |
| 资源 | LoadCursorA, LoadIconA |

### gdi32.dll (Graphics API)

| 分类 | API |
|------|-----|
| DC | CreateCompatibleDC, DeleteDC, SaveDC, RestoreDC |
| 对象 | SelectObject, DeleteObject, GetStockObject, GetObjectType |
| 画笔/画刷 | CreatePen, CreateSolidBrush, CreateHatchBrush |
| 字体 | CreateFontA, CreateFontIndirectA, GetTextMetricsA |
| 颜色 | SetTextColor, SetBkColor, SetBkMode, SetTextAlign, RGB |
| 绘图 | SetPixel, MoveToEx, LineTo, Rectangle, Ellipse, RoundRect, Polyline, Polygon |
| 填充 | FillRect, FrameRect, InvertRect, PatBlt |
| 文本 | TextOutA, DrawTextA, GetTextExtentPoint32A |
| 位图 | CreateCompatibleBitmap, BitBlt, StretchBlt |
| 区域 | CreateRectRgn, SelectClipRgn, GetClipBox |
| 坐标 | SetViewportOrgEx, SetWindowOrgEx |

### WOW64 (32-bit Compatibility)

| 分类 | 组件 |
|------|------|
| 核心 | wow64.dll (syscall dispatch), wow64cpu.dll (context管理), wow64win.dll (Win32k thunks) |
| 32位DLL | ntdll32.dll (Native API 32-bit shim), kernel3232.dll (Win32 Base 32-bit shim) |
| Thunk | 18+ syscall thunks (NtCreateProcess, NtCreateFile, NtAllocateVirtualMemory 等) |
| 转换 | 指针 32↔64, 句柄转换, 结构体转换, 地址空间映射 |
| 上下文 | CONTEXT32 (x86 寄存器), PEB32, TEB32, 32位栈/堆管理 |
| 地址空间 | 2GB 用户空间 (0x00000000 - 0x7FFFFFFF) |

## 启动模式

### BIOS (GRUB Multiboot2)

| 模式 | 说明 | Make 命令 |
|------|------|-----------|
| Normal | 标准启动, Debug 日志 | `make run-bios` |
| Debug | GDB 远程调试 | `make run-bios-debug` |
| Release | 优化构建, 最小日志 | `make run-bios-release` |
| Safe Mode | 安全模式 | GRUB 菜单选择 |
| Serial Debug | 仅串口调试 | GRUB 菜单选择 |
| Recovery | 恢复控制台 | GRUB 菜单选择 |
| GUI Demo | user32/gdi32 演示 | GRUB 菜单选择 |
| WOW64 Demo | 32位兼容演示 | GRUB 菜单选择 |
| Full Demo | Phase 0-11 完整演示 | GRUB 菜单选择 |

### UEFI (OVMF/AAVMF)

| 模式 | 说明 | Make 命令 |
|------|------|-----------|
| Normal | 标准 UEFI 启动 | `make run-uefi-x86_64` |
| Debug | GDB 远程调试 | `make run-uefi-debug` |
| Release | 优化构建 | `make run-uefi-release` |
| AArch64 | ARM64 UEFI | `make run-uefi-aarch64` |

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
