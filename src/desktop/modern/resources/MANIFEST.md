# ZirconOS Modern 资源清单

本资源包为 ZirconOS 原创设计，所有图形资源由代码生成或使用原创素材。
**不包含任何第三方版权资源**。

## 设计语言

Windows 8 Metro 风格：
- **扁平设计**：无渐变、无透明、无阴影
- **大胆色彩**：纯色强调色块
- **锐利几何**：直角矩形，无圆角
- **单色图标**：白色线条轮廓图标
- **磁贴界面**：方形彩色磁贴替代传统菜单

## 图形资源

| 资源类型 | 数量 | 说明 |
|---------|------|------|
| 壁纸 | 6 SVG | 纯色/几何矢量壁纸，覆盖 6 个主题变体 |
| 图标 | 13 SVG | 48x48 系统图标，单色扁平风格 |
| 光标 | 8 SVG | 32x32 光标集，扁平白色箭头 |

## 主题配置

| 文件 | 说明 |
|------|------|
| `themes/modern_blue.theme` | 蓝色 Metro 主题（默认） |
| `themes/modern_purple.theme` | 紫色变体 |
| `themes/modern_green.theme` | 绿色变体 |
| `themes/modern_orange.theme` | 橙色变体 |
| `themes/modern_red.theme` | 红色变体 |
| `themes/modern_dark.theme` | 深色变体 |

## 壁纸

| 文件 | 主题 | 说明 |
|------|------|------|
| `wallpapers/modern_default.svg` | Blue (默认) | 蓝色纯色背景 + 几何线条 |
| `wallpapers/modern_purple.svg` | Purple | 紫色纯色背景 |
| `wallpapers/modern_green.svg` | Green | 绿色纯色背景 |
| `wallpapers/modern_orange.svg` | Orange | 橙色纯色背景 |
| `wallpapers/modern_red.svg` | Red | 红色纯色背景 |
| `wallpapers/modern_dark.svg` | Dark | 深灰纯色背景 |

## 配色方案

| 色块 | Hex | 用途 |
|------|-----|------|
| 蓝色强调 | `#0078D7` | 默认强调色、磁贴、标题栏 |
| 紫色强调 | `#881798` | 紫色主题变体 |
| 绿色强调 | `#107C10` | 绿色主题变体 |
| 橙色强调 | `#DA3B01` | 橙色主题变体 |
| 红色强调 | `#E81123` | 红色变体 / 关闭按钮 |
| 深灰 | `#1F1F1F` | 任务栏背景 |
| 纯白 | `#FFFFFF` | 窗口背景 / 文字 |

## 使用方式

资源通过 `@embedFile` 嵌入或由渲染代码在运行时按主题配色生成。
主题通过 `theme_loader.zig` 模块加载 `.theme` INI 文件并映射到内部配色方案。

## 注意

发行版仅使用代码生成的原创资源。
