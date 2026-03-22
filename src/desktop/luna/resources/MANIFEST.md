# ZirconOS Luna 资源清单

本资源包为 ZirconOS 原创设计，所有图形资源由代码生成或使用原创素材。
**不包含任何第三方版权资源**。

## 图形资源

| 资源类型 | 数量 | 说明 |
|---------|------|------|
| 壁纸 | 3 SVG | 原创矢量壁纸，覆盖 3 个 Luna 配色变体 |
| 图标 | 16 SVG | 32x32 系统图标，Windows XP 3D 风格 |
| 光标 | 8 SVG | 32x32 光标集，经典白色箭头风格 |
| 开始按钮 | 1 SVG | 绿色 "start" 按钮图标 |

## 主题配置

| 文件 | 说明 |
|------|------|
| `themes/luna_blue.theme` | Luna 蓝色主题配置（默认） |
| `themes/luna_olive.theme` | Luna 橄榄绿主题配置 |
| `themes/luna_silver.theme` | Luna 银色主题配置 |

## 壁纸

| 文件 | 主题 | 说明 |
|------|------|------|
| `wallpapers/bliss.svg` | Blue (默认) | 蓝天绿草经典 Bliss 风格 |
| `wallpapers/bliss_olive.svg` | Olive Green | 暖色调橄榄风格壁纸 |
| `wallpapers/bliss_silver.svg` | Silver | 银灰色调壁纸 |

## 图标

| ID | 文件 | 说明 |
|----|------|------|
| 1 | `icons/my_computer.svg` | 我的电脑 — 蓝色显示器+米色机箱 |
| 2 | `icons/my_documents.svg` | 我的文档 — 黄色文件夹 |
| 3 | `icons/my_network_places.svg` | 网上邻居 — 联网电脑 |
| 4 | `icons/recycle_bin.svg` | 回收站 — 金属垃圾桶 |
| 5 | `icons/internet_explorer.svg` | Internet Explorer — 蓝色 e 图标 |
| 6 | `icons/control_panel.svg` | 控制面板 |
| 7 | `icons/printers.svg` | 打印机和传真 |
| 8 | `icons/terminal.svg` | 命令提示符 |
| 9 | `icons/notepad.svg` | 记事本 |
| 10 | `icons/calculator.svg` | 计算器 |
| 11 | `icons/outlook_express.svg` | Outlook Express |
| 12 | `icons/paint.svg` | 画图 |
| 13 | `icons/media_player.svg` | Windows Media Player |
| 14 | `icons/help.svg` | 帮助和支持 |
| 15 | `icons/search.svg` | 搜索 |
| 16 | `icons/run.svg` | 运行 |

## Luna 主题特点

- **配色方案**: Luna Blue（蓝色）、Luna Olive Green（橄榄绿）、Luna Silver（银色）
- **任务栏**: 渐变色填充，高度 30px
- **开始按钮**: 绿色圆角，"start" 小写斜体文本
- **标题栏**: 水平渐变（左→右），圆角 8px
- **窗口阴影**: 4px 软阴影
- **无 DWM 玻璃效果**: Luna 使用 GDI 风格不透明渐变渲染
- **系统字体**: Tahoma（映射到 Noto Sans）

## 使用方式

资源通过 `@embedFile` 嵌入或由渲染代码在运行时按主题配色生成。
主题通过 `theme_loader.zig` 模块加载 `.theme` INI 文件并映射到内部配色方案。

## 注意

发行版仅使用代码生成的原创资源。
