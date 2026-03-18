# ZirconOS User-Space Libraries

用户态库，为应用程序提供系统调用封装和 API。

## 规划中的库

| 库 | 目录 | 说明 |
|----|------|------|
| ntdll | `ntdll/` | Native API 系统调用封装（NT 风格） |
| kernel32 | `kernel32/` | Win32 基础 API 子集 |
| ucrt | `ucrt/` | 最小 C 运行时 |

## 分层关系

```
应用程序
  ↓
kernel32 / user32 / ...    (Win32 API)
  ↓
ntdll                       (Native API)
  ↓
syscall                     (内核系统调用 ABI)
  ↓
ZirconOS Microkernel
```
