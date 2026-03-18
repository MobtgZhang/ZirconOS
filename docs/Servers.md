# ZirconOS User-Space System Servers

NT 风格用户态系统服务，通过 LPC/IPC 与微内核通信。

## 规划中的服务

| 服务 | 目录 | 职责 |
|------|------|------|
| Session Manager (smss) | `smss/` | 启动管理、服务注册、子系统管理 |
| Object Server (obsvr) | `obsvr/` | 对象命名空间、目录/符号链接 |
| Process Server (pssvr) | `pssvr/` | 进程/线程策略、生命周期管理 |
| I/O Server (iosvr) | `iosvr/` | 设备命名空间、VFS、驱动模型 |
| Security Server (secsvr) | `secsvr/` | Token/ACL/访问检查 |
| Loader (ldsvr) | `ldsvr/` | ELF/PE 映射、重定位、导入解析 |

每个服务自带 `proto/` 或 `ipc/` 目录定义 IPC 协议。
