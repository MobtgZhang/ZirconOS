# 第三方软件与许可证说明

本项目源码以你选择的许可证发布（例如 LGPL）。但**构建/运行/分发**时会涉及第三方软件工具或组件，请务必区分：

- **工具依赖（build-time dependency）**：例如 `grub-mkrescue`、`xorriso`、`qemu`。它们通常不属于你项目的源码分发内容。
- **分发产物中包含的组件（runtime/distribution artifact）**：例如你发布的 `zirconos.iso` 里可能包含 GRUB 的二进制与模块文件。

## GRUB

- **用途**：生成可启动 ISO，并在 UEFI/BIOS 下引导进入 ZirconOS（当前通过 `chainloader` 启动 `zirconos.efi`）。
- **上游**：GNU GRUB（官方仓库）
- **许可证**：通常为 **GPLv3+**（以 GRUB 上游实际声明为准）

### 这对你选择 LGPL 有什么影响？

- **你的 ZirconOS 源码可以继续使用 LGPL**：只要你不把 GRUB 的源码“并入/改写成你项目的一部分”并以 LGPL 重新许可。
- **关键点在“分发 ISO”**：
  - 如果你把 `build/release/zirconos.iso` 作为发行物发布，而其中包含 GRUB 的二进制/模块，那么你需要**遵守 GRUB 的 GPLv3 义务**（例如提供对应源代码获取方式、保留版权与许可证文本等）。
  - 这通常不会自动“感染”你的内核/UEFI 应用的许可证，但你必须对 GRUB 这部分单独合规。

### 建议做法（最省心、最符合 GitHub 项目习惯）

- **仓库不 vendoring GRUB**：不把 GRUB 源码放进本仓库，不在仓库里“重新编译 GRUB”。
- **把 GRUB 作为系统依赖**：在 `README.md` 写清楚安装依赖（`grub-mkrescue`、`grub-efi-amd64-bin` 等）。
- **发布 release 时**：
  - 你可以发布 ISO，但要在 release notes/仓库里提供 `GRUB source` 获取指引（指向上游版本与源码下载方式），并附上 GRUB 的许可证声明。

## 其他依赖

- **OVMF（EDK2）**：用于 QEMU 的 UEFI 固件（开发测试用，通常不随你的 ISO 分发）
- **xorriso**：ISO 生成工具
- **QEMU**：模拟器

