# ZirconOSModern - Windows 8/8.1 Metro 桌面主题

## 概述

ZirconOSModern 是 ZirconOS 操作系统的 **Windows 8 Metro / Modern UI** 风格桌面环境实现。
Metro（后改名 Modern UI）是 Windows 8 引入的革命性设计语言，以极致扁平化、高对比度色块和
全屏磁贴界面为标志，专为触摸屏设备优化。

本模块参考 [ReactOS](https://github.com/reactos/reactos) 的桌面架构设计，
目标是实现 Windows 8/8.1 的 Modern UI 桌面 Shell，包括开始屏幕、Charms 栏和 Modern 应用框架。

## 设计风格

### Metro / Modern UI 核心视觉特征

| 特征 | 说明 |
|------|------|
| **极致扁平化** | 完全取消透明度、阴影、圆角 |
| **磁贴 (Live Tiles)** | 彩色方块，可显示动态信息 |
| **高对比度色块** | 浓烈的纯色背景，白色文字/图标 |
| **大面积留白** | 简洁版式，突出内容 |
| **Segoe UI** | 默认字体 Segoe UI Light/Semilight |
| **触摸优先** | 大按钮间距，边缘滑入手势 |

### 配色方案

| 元素 | 颜色值 | 说明 |
|------|--------|------|
| 开始屏幕背景 | `#1D1D1D`（深色）/ 用户选择色 | 可自定义主色调 |
| 默认磁贴色 | `#2D89EF`（蓝色） | 应用默认磁贴背景色 |
| 桌面任务栏 | `#1F1F1F` | 深色不透明 |
| 强调色预设 | 25 种主题色 | 用户从调色板选择 |
| 文字 | `#FFFFFF` | 白色（深色背景） |
| 应用栏 | `#1F1F1F` | 底部/顶部应用命令栏 |

### Metro 主题色预设（部分）

| 颜色名 | 色值 | 用途 |
|--------|------|------|
| Cobalt | `#0050EF` | 默认蓝色 |
| Emerald | `#008A00` | 绿色 |
| Crimson | `#A20025` | 深红色 |
| Mango | `#F09609` | 橙色 |
| Purple | `#7B1FA2` | 紫色 |
| Teal | `#00ABA9` | 青色 |

### 与其他主题的关键差异

- **开始屏幕取代开始菜单**：全屏磁贴布局，非弹出菜单
- **无桌面模式**（Win8）：Modern 应用全屏运行
- **Charms 栏**：右侧边缘滑入（搜索/共享/开始/设备/设置）
- **双环境**：Modern UI + 传统桌面模式共存
- **应用栏**：底部上滑或右键弹出命令栏
- **无窗口装饰**：Modern 应用全屏运行，无标题栏

## 模块架构

```
ZirconOSModern/
├── src/
│   ├── root.zig              # 库入口，导出所有公共模块
│   ├── main.zig              # 可执行入口 / 集成测试
│   ├── theme.zig             # Metro 主题定义（主题色、磁贴尺寸、动画参数）
│   ├── winlogon.zig          # 用户登录管理（Win8 锁屏 + 密码/PIN）
│   ├── desktop.zig           # 桌面管理器（传统桌面模式兼容）
│   ├── taskbar.zig           # 任务栏（仅传统桌面模式有效）
│   ├── startmenu.zig         # 开始屏幕（全屏磁贴布局）
│   ├── window_decorator.zig  # 窗口装饰器（传统模式标题栏 + Modern 全屏）
│   ├── shell.zig             # 桌面 Shell 主程序（双模式切换）
│   └── controls.zig          # Metro 风格控件（磁贴、AppBar、Toggle）
├── resources/
│   ├── wallpapers/           # 桌面壁纸
│   ├── icons/                # 系统图标（扁平单色图标）
│   ├── ui/                   # UI 组件素材
│   ├── cursors/              # 鼠标光标
│   └── MANIFEST.md           # 资源清单
├── build.zig
├── build.zig.zon
└── README.md
```

## 计划实现的组件

### WinLogon（用户登录）
- **锁屏界面**：全屏壁纸 + 日期时间 + 上滑解锁
- **登录界面**：用户头像 + 密码/PIN 输入
- **状态栏**：WiFi、电池、辅助功能

### Start Screen（开始屏幕）
- **全屏磁贴布局**：可自定义排列
- **磁贴尺寸**：小 (70x70)、中 (150x150)、宽 (310x150)、大 (310x310)
- **动态磁贴**：显示实时信息（日历、天气、新闻等）
- **语义分组**：磁贴可分组，组名标签
- **全部应用**：上滑或点击箭头查看所有已安装应用

### Charms Bar（超级按钮栏）
- **搜索**：全局搜索（应用、设置、文件）
- **共享**：内容共享合约
- **开始**：返回开始屏幕
- **设备**：投影、打印
- **设置**：快速设置面板（音量、亮度、WiFi、电源）

### Desktop（桌面管理器）
- 传统桌面模式兼容（与 Classic 类似）
- 壁纸管理
- 左下角热角触发开始屏幕

### Taskbar（任务栏）
- 仅传统桌面模式显示
- 深色不透明风格
- 开始按钮回归（Win8.1）

### Window Decorator（窗口装饰器）
- **传统模式**：标准标题栏 + 按钮（扁平化风格）
- **Modern 模式**：全屏无边框，顶部窗口控制
- Snap 分屏（左右二分之一屏幕）

### Controls（UI 控件）
- Live Tile（动态磁贴控件）
- AppBar（应用命令栏）
- Toggle Switch（Metro 风格开关）
- SemanticZoom（语义缩放）
- FlipView（翻转视图）

## 与主系统集成

ZirconOSModern 通过以下内核子系统接口工作：

1. **user32.zig** — 窗口管理 API（全屏应用模式）
2. **gdi32.zig** — 绘图 API（纯色填充为主）
3. **subsystem.zig** (csrss) — 窗口站和桌面管理
4. **framebuffer.zig** — 帧缓冲区显示驱动

### 配置

在 `src/config/desktop.conf` 中选择 Modern 主题：

```ini
[desktop]
theme = modern
color_scheme = cobalt    # cobalt | emerald | crimson | mango | purple | teal
shell = explorer
```

## 构建

```bash
cd src/desktop/modern
zig build
zig build test
```

## 开发状态

当前为项目框架阶段，计划按以下顺序实现：

1. `theme.zig` — Metro 主题色和磁贴尺寸常量
2. `controls.zig` — Live Tile 和 AppBar 控件
3. `startmenu.zig` — 全屏开始屏幕（核心组件）
4. `window_decorator.zig` — 双模式窗口装饰
5. `taskbar.zig` — 传统桌面模式任务栏
6. `desktop.zig` — 桌面管理器
7. `winlogon.zig` — 锁屏 + 登录界面
8. `shell.zig` — 双模式 Shell 集成

## 参考

- [ReactOS](https://github.com/reactos/reactos) — 开源 Windows 兼容操作系统
- [Microsoft Design Language (Metro)](https://learn.microsoft.com/en-us/windows/apps/design/) — Metro 设计规范
- Windows 8 / 8.1 视觉规范
- Microsoft UX Guidelines for Windows 8
