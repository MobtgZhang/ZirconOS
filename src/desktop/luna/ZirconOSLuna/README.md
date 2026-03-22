# ZirconOSLuna - Windows XP Luna 桌面主题

## 概述

ZirconOSLuna 是 ZirconOS 操作系统的 **Windows XP Luna** 风格桌面环境实现。
Luna 是 Windows XP 的默认视觉主题，以其鲜艳的色彩、圆润的控件和标志性的蓝色任务栏而闻名。

本模块参考 [ReactOS](https://github.com/reactos/reactos) 的桌面架构设计，
实现了完整的桌面 Shell、用户登录、窗口装饰、任务栏和开始菜单。

## 设计风格

### Luna 主题三色方案

| 方案 | 任务栏颜色 | 开始按钮 | 窗口标题栏 |
|------|-----------|---------|-----------|
| **Blue（默认）** | 亮蓝色渐变 `#0054E3 → #0150D0` | 绿色渐变 `#3C8D2E → #3FAA3B` | 蓝色渐变 `#0058E6 → #3A81E5` |
| **Olive Green** | 橄榄绿渐变 `#8DB080 → #6B8E5B` | 橄榄绿 | 橄榄绿渐变 |
| **Silver** | 银灰色渐变 `#B5B9C6 → #8B8FA4` | 银灰色 | 银灰色渐变 |

### 核心视觉特征

- **圆润边角**：窗口、按钮、菜单均使用圆角矩形（6-8px 半径）
- **渐变色标题栏**：活动窗口蓝色渐变，非活动窗口灰色渐变
- **高饱和度配色**：蓝色任务栏 + 绿色开始按钮，形成强烈视觉对比
- **3D 效果按钮**：控件具有立体感，使用高光和阴影模拟凸起效果
- **Tahoma/MS Sans Serif 字体**：系统默认使用 Tahoma 8pt

## 模块架构

```
ZirconOSLuna/
├── src/
│   ├── root.zig              # 库入口，导出所有公共模块
│   ├── main.zig              # 可执行入口，集成测试
│   ├── theme.zig             # Luna 主题定义（颜色、尺寸、样式常量）
│   ├── winlogon.zig          # 用户登录管理（认证、会话、欢迎界面）
│   ├── desktop.zig           # 桌面管理器（壁纸、图标布局、右键菜单）
│   ├── taskbar.zig           # 任务栏（开始按钮、快速启动、系统托盘、时钟）
│   ├── startmenu.zig         # 开始菜单（用户头像、程序列表、常用位置）
│   ├── window_decorator.zig  # 窗口装饰器（Luna 风格标题栏、边框）
│   ├── shell.zig             # 桌面 Shell 主程序（explorer.exe 风格）
│   └── controls.zig          # Luna 风格控件（按钮、文本框、复选框等）
├── resources/
│   ├── wallpapers/                    # 桌面壁纸
│   │   ├── bliss_default.png          # 默认 Bliss 风格蓝天白云壁纸（Blue 主题）
│   │   ├── wallpaper_olive_green.png  # Olive Green 主题秋季风景壁纸
│   │   └── wallpaper_silver.png       # Silver 主题银灰山水壁纸
│   ├── icons/
│   │   ├── system/                    # 系统图标（桌面 & 开始菜单右栏）
│   │   │   ├── icon_mycomputer.png    # 我的电脑
│   │   │   ├── icon_mydocuments.png   # 我的文档
│   │   │   ├── icon_recyclebin_empty.png  # 回收站（空）
│   │   │   ├── icon_recyclebin_full.png   # 回收站（满）
│   │   │   ├── icon_network.png       # 网上邻居
│   │   │   ├── icon_controlpanel.png  # 控制面板
│   │   │   ├── icon_printer.png       # 打印机
│   │   │   ├── icon_help.png          # 帮助和支持
│   │   │   ├── icon_search.png        # 搜索
│   │   │   ├── icon_run.png           # 运行
│   │   │   ├── icon_shutdown.png      # 关机
│   │   │   ├── icon_logoff.png        # 注销
│   │   │   └── icon_user_default.png  # 默认用户头像
│   │   ├── startmenu/                 # 开始菜单左栏固定程序图标
│   │   │   ├── icon_internet.png      # Internet 浏览器
│   │   │   └── icon_email.png         # 电子邮件
│   │   ├── quicklaunch/               # 快速启动栏图标
│   │   │   ├── icon_internet.png      # Internet 浏览器
│   │   │   └── icon_email.png         # 电子邮件
│   │   └── tray/                      # 系统托盘图标
│   │       ├── icon_tray_volume.png   # 音量
│   │       └── icon_tray_network.png  # 网络连接
│   ├── ui/                            # UI 组件图形
│   │   ├── taskbar/
│   │   │   └── ui_start_button.png    # 开始按钮（绿色渐变 + Windows 标志）
│   │   ├── titlebar/
│   │   │   └── ui_titlebar_buttons.png # 窗口控制按钮（最小化/最大化/关闭）
│   │   ├── startmenu/                 # 开始菜单 UI 元素（待扩展）
│   │   ├── buttons/                   # Luna 风格按钮纹理（待扩展）
│   │   └── window/                    # 窗口边框纹理（待扩展）
│   ├── cursors/                       # 鼠标光标
│   │   ├── cursor_arrow.png           # 标准箭头光标
│   │   └── cursor_wait.png            # 等待（沙漏）光标
│   ├── sounds/                        # 系统声音（待添加）
│   └── fonts/                         # 字体文件（待添加）
├── build.zig
├── build.zig.zon
└── README.md
```

## 组件说明

### WinLogon（用户登录）

参考 Windows XP / ReactOS 的 Winlogon 组件：

- **欢迎界面**：显示用户头像和用户名列表
- **密码认证**：支持用户名/密码验证
- **会话管理**：创建和管理用户登录会话
- **安全桌面**：登录界面运行在独立安全桌面上
- **注销/关机**：支持用户注销、系统关机、重启

### Desktop（桌面管理器）

- **壁纸管理**：默认显示经典蓝天白云壁纸（Bliss 风格颜色方案）
- **桌面图标**：我的电脑、我的文档、网上邻居、回收站
- **图标布局**：自动从左上角排列，支持网格对齐
- **右键菜单**：刷新、排列图标、属性

### Taskbar（任务栏）

- **开始按钮**：绿色渐变背景 + "Start" 文字 + Windows 标志
- **快速启动区**：桌面、浏览器、邮件快捷方式
- **任务按钮区**：显示已打开窗口，活动窗口高亮
- **系统托盘**：音量、网络、时钟
- **通知区域**：可折叠的系统图标

### Start Menu（开始菜单）

XP 风格双栏开始菜单：

- **左栏上部**：固定程序（Internet、E-mail）
- **左栏下部**：最近使用的程序
- **右栏**：我的文档、我的电脑、控制面板、打印机等
- **底部**：注销、关机按钮
- **用户头像**：顶部显示当前用户名和头像

### Window Decorator（窗口装饰器）

- **标题栏**：蓝色渐变（活动）/ 灰色渐变（非活动）
- **控制按钮**：最小化、最大化/还原、关闭（XP 风格圆角按钮）
- **窗口边框**：蓝色细边框，支持拖拽调整大小
- **系统菜单**：窗口图标点击弹出系统菜单

## 资源文件说明

### 壁纸（wallpapers）

提供三套壁纸，分别对应 Luna 三色主题方案：

| 壁纸文件 | 对应主题 | 描述 |
|---------|---------|------|
| `bliss_default.png` | Blue（默认） | 经典 Bliss 风格蓝天绿地壁纸 |
| `wallpaper_olive_green.png` | Olive Green | 秋季田园橄榄绿色调壁纸 |
| `wallpaper_silver.png` | Silver | 银灰色调山水湖泊壁纸 |

### 图标（icons）

- **system/** — 系统核心图标：我的电脑、我的文档、回收站（空/满）、网上邻居、控制面板、打印机、帮助、搜索、运行、关机、注销、默认用户头像
- **startmenu/** — 开始菜单左栏固定程序：Internet 浏览器、电子邮件
- **quicklaunch/** — 快速启动栏快捷方式图标
- **tray/** — 系统托盘图标：音量、网络连接

### UI 组件（ui）

- **taskbar/** — 任务栏 UI 元素：开始按钮（绿色渐变 + Windows 标志 + "start" 文字）
- **titlebar/** — 窗口标题栏按钮：最小化、最大化、关闭三合一按钮组

### 鼠标光标（cursors）

- `cursor_arrow.png` — 标准箭头指针
- `cursor_wait.png` — 等待状态沙漏光标

### 待扩展资源

- **sounds/** — 系统声音（启动音、关机音、错误提示音等）
- **fonts/** — 字体文件（Tahoma 等替代字体）
- **ui/buttons/** — Luna 风格按钮状态纹理（正常/悬停/按下/禁用）
- **ui/window/** — 窗口边框和阴影纹理
- **ui/startmenu/** — 开始菜单背景和分隔线

> **注意**：当前资源文件为 PNG 格式的参考设计图。在实际集成到 ZirconOS 时，
> 需要将其转换为操作系统可直接加载的格式（如 BMP 或嵌入式像素数组），
> 并通过 `@embedFile` 编译到内核/Shell 二进制文件中。

## 与主系统集成

ZirconOSLuna 作为 Win32 子系统的视觉层，通过以下方式集成：

1. **user32.zig** 提供窗口管理 API
2. **gdi32.zig** 提供绘图 API
3. **subsystem.zig** (csrss) 管理窗口站和桌面
4. **Luna 主题** 提供所有可视化元素的样式定义

## 参考

- [ReactOS](https://github.com/reactos/reactos) - 开源 Windows 兼容操作系统
- Windows XP Luna Theme 视觉规范
- Microsoft UX Guidelines for Windows XP
