# ZirconOS Fluent 资源清单

本资源包为 ZirconOS 原创设计，采用亚克力（Acrylic）视觉风格，
**不包含任何来自微软的版权资源**。

所有图标、光标、壁纸均为 ZirconOS 项目原创 SVG 矢量设计。

## 图形资源

| 资源类型 | 路径 | 说明 |
|---------|------|------|
| Logo | `resources/logo.svg` | ZirconOS Fluent 风格 Logo |
| 开始按钮 | `resources/start_button.svg` | Fluent 四格开始按钮图标 |
| 壁纸 | `resources/wallpapers/` | 8 张原创渐变壁纸（SVG 矢量） |
| 图标 | `resources/icons/` | 12 个 Fluent 风格系统图标（SVG） |
| 光标 | `resources/cursors/` | 9 个 Fluent 风格光标（SVG） |
| 主题 | `resources/themes/` | Dark/Light 主题配置文件 |
| 声音 | `resources/sounds/` | 音效方案配置 |

## 壁纸列表

| 文件名 | 模式 | 说明 |
|--------|------|------|
| `zircon_default.svg` | Dark | 默认暗色 Acrylic 流动壁纸 |
| `zircon_flow.svg` | Dark | 深海蓝色波浪渐变 |
| `zircon_light.svg` | Light | 浅色明亮渐变壁纸 |
| `zircon_gradient.svg` | Dark | 紫蓝色 Mesh 渐变 |
| `zircon_aurora.svg` | Dark | 极光夜景壁纸 |
| `zircon_cityscape.svg` | Dark | 城市天际线夜景 |
| `zircon_abstract.svg` | Dark | 抽象几何渐变 |
| `zircon_spectrum.svg` | Dark | 彩色频谱条带 |

## 图标列表

| 图标 | 文件 | 说明 |
|------|------|------|
| Computer | `computer.svg` | 桌面 PC / 此电脑 |
| Documents | `documents.svg` | 用户文档文件夹 |
| Recycle Bin | `recycle_bin.svg` | 回收站 |
| Terminal | `terminal.svg` | 命令行终端 |
| Network | `network.svg` | 网络连接 |
| Browser | `browser.svg` | 网页浏览器 |
| File Manager | `file_manager.svg` | 文件管理器 |
| Settings | `settings.svg` | 系统设置 |
| Store | `store.svg` | 应用商店 |
| Calculator | `calculator.svg` | 计算器 |
| Mail | `mail.svg` | 邮件客户端 |
| Calendar | `calendar.svg` | 日历应用 |

## 光标列表

| 光标 | 文件 | 说明 |
|------|------|------|
| Arrow | `zircon_arrow.svg` | 默认箭头指针 |
| Text | `zircon_text.svg` | 文本选择 I-beam |
| Busy | `zircon_busy.svg` | 系统忙碌旋转圈 |
| Working | `zircon_working.svg` | 箭头+旋转圈（应用启动） |
| Link | `zircon_link.svg` | 手形超链接指针 |
| Move | `zircon_move.svg` | 四向移动箭头 |
| NS Resize | `zircon_ns.svg` | 垂直调整大小 |
| EW Resize | `zircon_ew.svg` | 水平调整大小 |
| Unavailable | `zircon_unavail.svg` | 禁止/不可用 |

## 使用方式

资源文件通过 `@embedFile` 嵌入或由渲染代码在运行时按主题配色生成。
`resource_loader.zig` 负责在初始化时注册所有资源路径供合成器引用。

## 许可证

本目录下所有资源文件均为 ZirconOS 项目原创作品，采用与主项目相同的许可证。
