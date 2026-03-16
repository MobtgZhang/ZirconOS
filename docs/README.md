# ZirconOS 设计原则与方针

本文档定义 ZirconOS 的**长期设计目标**、**分层边界**与**工程方针**，用于约束后续演进，避免“做到一半推倒重来”。

## 核心目标（What we build）

- **Microkernel + 用户态系统服务**：内核最小化，系统语义在用户态 server/subsystem 中实现。
- **NT 风格思路**：面向对象/句柄（handle）/命名空间（namespace）/系统服务化（Executive 用户态化）。
- **Zig 实现**：尽量用 Zig 表达可验证的边界与 ABI，避免隐式依赖 libc。
- **兼容性分阶段**：先 native + ELF，再 PE，再 Win32 子系统，最后 WOW64。

## 非目标（What we do NOT build now）

- **不做“完整 NT 内核复刻”**：不追求完全同 ABI/同实现细节，只追求可用的 NT 风格结构与演进路径。
- **不把 Win32 语义塞进内核**：窗口/消息/GDI 等属于子系统层，内核只提供机制（IPC、调度、VM、异常）。
- **不追求一开始就跑大型应用**：先能稳定启动、能创建线程/进程、能 IPC、能加载最小用户态程序。

## 分层边界（最重要的约束）

### 内核（Microkernel）只提供“机制”

- **调度**：线程、优先级、时间片
- **虚拟内存**：地址空间、映射/解映射、权限、page fault 上送
- **IPC**：端口/通道、同步 call/reply、异步通知（后续）
- **异常/中断**：基本分发、可上送用户态异常分发器（后续）
- **syscall ABI**：稳定、最小、可版本化
- **最小 handle 原语**：引用/复制/关闭/跨进程转移（能力票据）

### 用户态系统服务提供“语义”

- **Object Manager（obsvr）**：对象类型系统、命名空间（`\`）、目录/符号链接、句柄表策略
- **Process Manager（pssvr）**：进程/线程策略、生命周期、资源集合（句柄表、token、参数）
- **I/O Manager（iosvr）**：设备命名空间、VFS、驱动模型（尽量用户态化）
- **Security（secsvr）**：token/ACL/访问检查（早期可 stub，但接口形状要预留）
- **Loader（ldsvr）**：ELF/PE 映射、重定位、导入解析，创建初始线程上下文
- **SMSS**：启动、服务注册、子系统管理（win32ss/posixss/wow64ss）

### Subsystem 负责“兼容层”

- **Win32 Subsystem**：kernel32/user32/gdi32/ntdll 的逐步实现（先最小集）
- **POSIX Subsystem**：libc/posix API 映射到系统服务
- **WOW64 Subsystem**：32-bit thunk + ABI/结构体转换；内核尽量不“懂 32-bit”

## 设计方针（How we evolve）

- **先机制、后策略**：内核先把调度/VM/IPC 做对，再把策略上移到用户态服务。
- **接口先行**：新增能力先定义 RPC/syscall/对象类型与信息类（info class），再填实现。
- **可观测性优先**：早期就保留串口/日志管线（哪怕是最简），便于定位 bug。
- **渐进兼容**：PE/Win32/WOW64 都按阶段落地，避免“一步到位”导致架构绑死。
- **可替换实现**：server/subsystem 可以重启/替换；崩溃隔离是 microkernel 路线的收益点。

## 命名与目录约定（约束未来扩展）

- **内核模块**：`kernel/src/{arch,hal,kernel}`（后续可加 `kernel/src/kernel/` 存放 sched/vm/ipc/syscall）
- **用户态服务**：`servers/<name>/`（每个服务自带 `proto/` 或 `ipc/` 定义）
- **子系统**：`subsystems/<name>/`（Win32/POSIX/WOW64）
- **协议与 ABI**：集中在 `docs/abi/`（后续建立），变更需标注版本与兼容策略

## 里程碑（建议的交付节奏）

- **M0 启动**：GRUB + Multiboot2 + VGA 输出（已完成最小骨架）
- **M1 中断/定时器**：IDT/IRQ、tick、基础时间
- **M2 线程与调度**：可切换、可阻塞等待
- **M3 地址空间/映射**：用户态地址空间 + page fault
- **M4 IPC + syscall**：最小 call/reply + handle 原语
- **M5 obsvr/pssvr**：对象/句柄表/命名空间 + 进程/线程策略
- **M6 Loader**：ELF → PE（按优先级）
- **M7 子系统**：Win32 最小集 → WOW64

