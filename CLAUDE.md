# 指南龟 TTcompass — AI 项目指引

> 面向 iPhone 的指南针应用：方向、海拔、经纬度。UI 参考 iOS 自带指南针。
> 本文件是项目级 AI 协作规范，优先级低于根目录 `AGENTS.md`。

> **完整工程交接文档：先读 `HANDOFF.md`**（开发历程、权限状态机、部署链路与全部已知坑）。

## 技术栈与路线

- 采用 AGENTS.md 推荐的 **路线 A：Capacitor 套壳**。
- 核心为单文件前端 `www/index.html`，CSS / SVG 表盘 / JS 全部内联，无构建步骤。
- 未使用 npm 依赖也能运行；`package.json` 仅用于后续 `npx cap` 原生封装。

## 目录结构

- `www/index.html` — 单文件应用（内联 CSS、SVG 表盘、JS）
- `capacitor.config.json` — Capacitor 配置（appId：`com.turtleworks.turtlecompass`）
- `package.json` — 原生封装脚本与 Capacitor 依赖

## 运行 / 验证

- 桌面预览（模拟方向旋转 + 北京坐标）：`?demo=1`
- 本地静态服务器：在 `www` 目录执行 `npx serve .`
- 语法检查：提取 `index.html` 内联 `<script>` 后 `node --check`，或直接 `node --check` 临时文件

## 关键实现约定

- 打开即自动运行：无启动按钮/遮罩，页面加载后直接启动定位与方向监听。
- 表盘为**内联静态 SVG**（刻度、度数、北东南西、红白指北针），JS 只负责旋转与数据更新，避免 JS 生成 SVG 失败导致表盘空白。
- 方向：优先用 iOS Safari 的 `webkitCompassHeading`，Android 兜底 `deviceorientationabsolute.alpha`。
- 定位：原生 `navigator.geolocation.watchPosition`，`coords.altitude` 取海拔。
- 坐标：度分秒（DMS）+ 十进制度双显示。
- iOS 13+ 的 `DeviceOrientationEvent.requestPermission()` 若未自动授予，会在首次轻触屏幕时重新请求（无遮挡按钮）。
- 页内 `window.onerror` 会把 JS 运行错误显示到表盘下方的提示区，便于真机排查。
- 定位/方向可能需要安全上下文（HTTPS 或 localhost），HTTP 局域网地址可能被浏览器拦截。

## 部署（GitHub Pages）

- 一键脚本：双击 `部署到github.bat`（内部调用 `deploy.ps1`），提交信息来自 `commit-msg.txt`。
- 推送规则按 AGENTS.md：完整版推 `main:dev`，发布版从本地 `release-basic` 推到 `origin/main`，git 走 `127.0.0.1:7897` 代理。
- Pages 由 `.github/workflows/pages.yml` 从 `www/` 自动部署（仓库 Settings → Pages → Source = GitHub Actions，需用户设置一次）。
- iOS Safari 的定位/方向要求 HTTPS 安全上下文，本地 HTTP 局域网地址会被拦截，App 内已有对应提示。

## 原生封装（拿到 Mac 后）

> 注意：WKWebView 默认不会触发 `deviceorientation` 事件，浏览器版本已可用；封装成原生 App 前必须接一个原生方向传感器插件（或 Swift 桥接 `CMMotionManager`），否则表盘不转。

1. `npm install`
2. `npx cap add ios`
3. `npx cap sync`
4. 接入方向传感器插件（以 Capacitor 社区插件目录当前版本为准），或自行用 Swift 桥接。
5. 在 Xcode 的 `Info.plist` 添加：
   - `NSMotionUsageDescription`（运动与方向）
   - `NSLocationWhenInUseUsageDescription`（定位）
6. `CFBundleDisplayName` 改为 `指南龟`
7. `npx cap open ios` 真机运行

## 命名

- 中文名：指南龟
- 英文名：TurtleCompass
- 工程目录：`TTcompass`
