# ZirconOS v1.0

**ZirconOS** 是一个 NT 风格微内核操作系统，使用 Zig 语言实现，基于 GRUB Multiboot2 启动。

## 设计理念

- **NT 风格微内核**：内核仅提供调度、虚拟内存、IPC、中断、系统调用等最小机制
- **用户态系统服务**：Object Manager、Process Manager、I/O Manager、Security 等作为用户态服务运行
- **多架构支持**：x86_64（主要）、aarch64、loong64、riscv64、mips64el

设计文档：[`docs/README.md`](docs/README.md)

## 项目结构（NT Executive 风格）

```
ZirconOS/
├── build.zig              # Zig 构建系统
├── Makefile               # 便捷构建封装
├── boot/grub/grub.cfg     # GRUB 引导配置
├── link/                  # 各架构链接脚本
│   ├── x86_64.ld
│   ├── aarch64.ld
│   ├── loong64.ld
│   ├── riscv64.ld
│   └── mips64el.ld
├── kernel/src/
│   ├── main.zig           # 内核入口
│   ├── arch.zig           # 架构抽象分发层
│   ├── arch/              # 架构相关代码
│   │   ├── x86_64/        #   Multiboot2、分页、IDT、ISR、Syscall
│   │   ├── aarch64/       #   AArch64 启动、分页（stub）
│   │   ├── loong64/       #   LoongArch64（stub）
│   │   ├── riscv64/       #   RISC-V 64（stub）
│   │   └── mips64el/      #   MIPS64EL（stub）
│   ├── hal/               # 硬件抽象层
│   │   ├── x86_64/        #   VGA、PIC、PIT、Port I/O
│   │   └── aarch64/       #   PL011 UART
│   ├── ke/                # Kernel Executive - 调度、定时、中断
│   ├── mm/                # Memory Manager - 物理帧分配、虚拟内存
│   ├── ps/                # Process Subsystem - 进程/线程、Process Server
│   ├── ob/                # Object Manager - 对象/句柄表
│   ├── lpc/               # LPC - IPC 消息传递
│   ├── se/                # Security - Token/访问检查
│   ├── io/                # I/O Manager - 设备/驱动模型
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
sudo apt install -y grub-pc-bin grub-common xorriso qemu-system-x86
```

Zig 编译器：从 [ziglang.org](https://ziglang.org/download/) 下载并加入 PATH。

## 构建与运行

```bash
# 构建 x86_64 ISO（GRUB + Multiboot2）
make iso

# 在 QEMU 中运行（BIOS 模式）
make run

# 构建指定架构的内核
make kernel ARCH=aarch64

# 运行 AArch64 内核
make run-aarch64

# 查看帮助
make help
```

## v1.0 已实现

| 模块 | 状态 | 说明 |
|------|------|------|
| GRUB Boot | ✅ | Multiboot2 启动，x86_64 |
| VGA Output | ✅ | 文本模式控制台 |
| Frame Allocator | ✅ | 位图物理帧分配器 |
| Paging | ✅ | 四级页表，identity mapping |
| IPC (LPC) | ✅ | 消息队列，send/receive |
| Syscall | ✅ | int 0x80 分发 |
| Process Server | ✅ | 进程创建/终止 |
| IDT/ISR | ✅ | 中断描述符表 |
| Object Manager | 🔧 | 接口定义，待实现 |
| Security | 🔧 | Token stub，待实现 |
| I/O Manager | 🔧 | 接口定义，待实现 |
| 多架构 | 🔧 | x86_64 完整，其他 stub |

## 里程碑

- **M0** ✅ GRUB 启动 + VGA 输出
- **M1** ✅ 中断/定时器
- **M2** 🔧 线程与调度
- **M3** ✅ 地址空间/映射
- **M4** ✅ IPC + Syscall
- **M5** 🔧 Object Manager / Process Manager
- **M6** 📋 Loader (ELF → PE)
- **M7** 📋 Win32 子系统
