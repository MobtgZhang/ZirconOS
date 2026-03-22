# ZirconOS Fluent 桌面主题

ZirconOS Fluent 是一个原创的亚克力（Acrylic）风格桌面主题，具有以下特性：

- **亚克力材质**：多遍高斯模糊 + 噪点纹理 + 明度混合，实现磨砂玻璃效果
- **深度阴影**：多层渐变阴影系统，营造 UI 元素的空间层次感
- **Reveal 高亮**：鼠标指针附近的径向渐变光晕效果
- **双色模式**：完整的明/暗配色方案
- **动态磁贴**：开始菜单磁贴网格布局
- **操作中心**：快速设置面板 + 通知卡片
- **虚拟桌面**：多桌面工作区管理

## 架构

```
ZirconOSFluent/
├── src/
│   ├── root.zig              # 库入口，导出所有模块
│   ├── main.zig              # 可执行入口 / 集成测试
│   ├── theme.zig             # 主题配色、尺寸、DWM 默认值
│   ├── dwm.zig               # 合成器（模糊、噪点、明度混合、Reveal、阴影）
│   ├── desktop.zig           # 桌面管理器（壁纸、图标、右键菜单）
│   ├── taskbar.zig           # 任务栏（开始按钮、搜索、任务视图、系统托盘）
│   ├── startmenu.zig         # 开始菜单（应用列表、磁贴网格、搜索栏）
│   ├── window_decorator.zig  # 窗口装饰器（标题栏、边框、控制按钮）
│   ├── shell.zig             # 桌面 Shell 主程序
│   ├── controls.zig          # UI 控件（按钮、文本框、复选框、开关等）
│   ├── winlogon.zig          # 登录管理器
│   └── action_center.zig     # 操作中心（快速设置、通知）
├── resources/
│   ├── MANIFEST.md           # 资源清单
│   ├── logo.svg              # ZirconOS Fluent Logo（原创）
│   └── wallpapers/           # 原创矢量壁纸
│       ├── zircon_flow.svg   # 暗色主题壁纸
│       └── zircon_light.svg  # 明色主题壁纸
├── build.zig
├── build.zig.zon
└── README.md
```

## 构建

```bash
cd src/desktop/fluent
zig build
```

或从项目根目录：

```bash
make run-desktop-fluent
```

## 许可证

本项目所有代码和资源均为 ZirconOS 项目原创，不包含任何第三方版权内容。
