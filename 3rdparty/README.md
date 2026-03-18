# ZirconOS 桌面主题 (3rdparty)

本目录包含 ZirconOS 操作系统的多个 **Windows 风格桌面环境** 实现。
每个子项目是一个独立的 Zig 模块，提供不同 Windows 版本的视觉主题和桌面 Shell。

## 主题一览

| 项目 | 对应 Windows 版本 | 设计风格 | 状态 |
|------|-------------------|---------|------|
| [ZirconOSClassic](ZirconOSClassic/) | Windows 2000 / 经典主题 | 经典 3D 灰色按钮 + 直角窗口 | 框架 |
| [ZirconOSLuna](ZirconOSLuna/) | Windows XP | Luna 主题（蓝/橄榄绿/银色三套配色） | **已实现** |
| [ZirconOSAero](ZirconOSAero/) | Windows Vista / 7 | Aero 毛玻璃 + 透明边框 + Flip 3D | 框架 |
| [ZirconOSModern](ZirconOSModern/) | Windows 8 / 8.1 | Metro / Modern UI 扁平磁贴 | 框架 |
| [ZirconOSFluent](ZirconOSFluent/) | Windows 10 | Fluent Design + 亚克力材质 + 暗色模式 | 框架 |
| [ZirconOSSunValley](ZirconOSSunValley/) | Windows 11 | Sun Valley + Mica 云母材质 + 大圆角 | 框架 |

> **状态说明**：「已实现」表示具备完整桌面 Shell（登录、桌面、任务栏、开始菜单、窗口装饰、控件），
> 「框架」表示已创建项目骨架，待按照 Luna 模板进行开发。

## 架构设计

所有桌面主题共享统一架构，以 ZirconOSLuna（最完整实现）为参考模板：

```
ZirconOS<Theme>/
├── src/
│   ├── root.zig              # 库入口，导出所有公共模块
│   ├── main.zig              # 可执行入口 / 集成测试
│   ├── theme.zig             # 主题定义（颜色、尺寸、样式常量）
│   ├── winlogon.zig          # 用户登录管理（认证、会话、欢迎界面）
│   ├── desktop.zig           # 桌面管理器（壁纸、图标布局、右键菜单）
│   ├── taskbar.zig           # 任务栏（开始按钮、快速启动、系统托盘、时钟）
│   ├── startmenu.zig         # 开始菜单（程序列表、系统链接）
│   ├── window_decorator.zig  # 窗口装饰器（标题栏、边框、控制按钮）
│   ├── shell.zig             # 桌面 Shell 主程序（explorer.exe 风格）
│   └── controls.zig          # 风格化 UI 控件（按钮、文本框、复选框等）
├── resources/                # 图形资源（壁纸、图标、UI 素材、光标）
│   └── MANIFEST.md           # 资源清单
├── build.zig                 # Zig 构建脚本
├── build.zig.zon             # Zig 包清单
└── README.md                 # 项目说明
```

## 与内核集成

桌面主题通过以下内核子系统接口工作：

1. **user32.zig** — 窗口管理、消息队列、输入处理
2. **gdi32.zig** — 图形设备接口（绘图、字体、位图）
3. **subsystem.zig** (csrss) — 窗口站和桌面管理
4. **framebuffer.zig** — 帧缓冲区显示驱动

### 主题选择

在 `config/desktop.conf` 中通过 `theme` 字段选择桌面主题：

```ini
[desktop]
theme = luna          # classic | luna | aero | modern | fluent | sunvalley
color_scheme = blue   # 主题特定配色方案
shell = explorer
```

## 构建

从项目根目录构建指定桌面主题：

```bash
# 构建默认主题（由 config/desktop.conf 决定）
zig build desktop

# 构建指定主题
zig build desktop -Dtheme=luna
zig build desktop -Dtheme=aero

# 构建所有桌面主题
zig build desktop-all
```

单独构建某个主题（进入子目录）：

```bash
cd 3rdparty/ZirconOSLuna
zig build
```

## 开发指南

新增桌面主题的步骤：

1. 复制 `ZirconOSLuna/` 作为模板
2. 修改 `build.zig.zon` 中的名称和 fingerprint
3. 实现 `theme.zig` 中的配色方案和尺寸常量
4. 按照目标 Windows 版本的视觉规范实现各组件
5. 在 `resources/` 中添加主题资源文件
6. 更新 `config/desktop.conf` 支持新主题名

## 参考

- [ReactOS](https://github.com/reactos/reactos) — 开源 Windows 兼容操作系统
- [Wine](https://www.winehq.org/) — Windows API 兼容层
- Microsoft UX Guidelines — 各版本 Windows 视觉规范
