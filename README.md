# ZirconOS

ZirconOS 是一个实验性操作系统项目：**GRUB 启动 + x86_64 freestanding 内核（Zig）**。本仓库当前提供“可启动的最小骨架”，后续将逐步扩展到 microkernel + user-mode servers/subsystems 的架构。

设计原则与方针见：[`docs/README.md`](docs/README.md)

第三方软件与许可证说明见：[`docs/THIRD_PARTY.md`](docs/THIRD_PARTY.md)

## 目录结构

```
.
├─ boot/
│  └─ grub/
│     └─ grub.cfg
├─ build/            # 构建输出（不会提交到 git）
├─ kernel/
│  ├─ build.zig
│  ├─ linker.ld
│  └─ src/
│     ├─ arch/
│     │  └─ x86_64/
│     │     ├─ multiboot2.zig
│     │     └─ portio.zig
│     ├─ hal/
│     │  └─ x86_64/
│     │     └─ vga_text.zig
│     └─ main.zig
├─ Makefile
├─ servers/          # 预留：Object/Process/IO/Security/Loader/SMSS 等服务
├─ subsystems/       # 预留：win32/posix/wow64 子系统
└─ .gitignore
```

## 依赖

Ubuntu/Debian：

```bash
sudo apt update
sudo apt install -y grub-pc-bin grub-common grub-efi-amd64-bin xorriso mtools qemu-system-x86 ovmf
```

安装 Zig（任选其一）：

- 发行版包（可能较旧）：`sudo apt install -y zig`
- 或从 Zig 官方下载并加入 PATH（推荐）

验证：

```bash
zig version
grub-mkrescue --version
xorriso -version
qemu-system-x86_64 --version
```

## 构建与运行（GRUB UEFI + QEMU/OVMF）

构建 UEFI 应用 + 生成 ISO：

```bash
make iso-uefi
```

运行（UEFI，QEMU + OVMF）：

```bash
make run-uefi
```

你应该能看到屏幕输出（注意 `Hello` 与 `ZirconOS!` 之间有两个空格）：

```
Hello  ZirconOS!
```

## 说明

- UEFI 路径：GRUB 在 UEFI 模式下 `chainloader` 启动 `zirconos.efi`。
- BIOS 路径：仍保留 **Multiboot2** 直接加载内核 ELF（`make run-bios`）。
- 目前仅做最小输出与死循环，后续会逐步加入：中断/定时器/调度/虚拟内存/IPC/syscall 等模块。

