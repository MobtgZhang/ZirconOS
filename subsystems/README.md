# ZirconOS Subsystems

子系统负责提供应用兼容层 API。

## 规划中的子系统

| 子系统 | 目录 | 说明 |
|--------|------|------|
| Native | `native/` | ZirconOS 原生 API |
| Win32 | `win32/` | kernel32/user32/gdi32 兼容层 |
| POSIX | `posix/` | libc/POSIX API 映射 |
| WOW64 | `wow64/` | 32-bit PE thunk + ABI 转换 |

## 实现路线

1. Native subsystem（原生 ZirconOS 可执行文件）
2. Win32 Console-only（kernel32 基础 API）
3. POSIX 最小集
4. Win32 GUI（user32/gdi32）
5. WOW64（32-bit 兼容）
