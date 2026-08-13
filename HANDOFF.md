# 指南龟（TTcompass）工程交接文档

> 写给后续接手的 AI（Claude Code / Codex / Cursor 等）。阅读顺序：工作区根目录 `AGENTS.md` → 本文件 → 按需读 `CLAUDE.md`、`README.md`。
> 最后更新：2026-08-13（对应本地最新提交 `f14cfe1`）

## 1. 工程一句话

面向 iPhone 的指南针应用：显示方向（度数 + 中文八方位）、海拔、经纬度（度分秒 + 十进制），UI 仿 iOS 自带指南针。核心是单文件 `www/index.html`，已通过 GitHub Pages 部署使用。

## 2. 现状速览

- 阶段：`active`（首次开发中，尚未正式发布）
- 技术路线：AGENTS.md 路线 A（Capacitor 套壳），当前 100% 纯网页，无构建步骤、无 npm 运行时依赖
- 线上地址：https://kimoji798.github.io/TTcompass/
- 仓库：https://github.com/Kimoji798/TTcompass.git
- 本地分支：`main` 追踪 `origin/dev`（完整开发版）；`release-basic` 用于推 `origin/main`（发布版）
- ⚠️ 推送状态：本地最新提交 `f14cfe1`（权限兜底按钮）以及 `42d9a2e`（图标/字体/权限优化）在上次会话结束时**尚未推送**，需运行 `部署到github.bat` 完成；是否已推送可看仓库 Actions 或 `deploy-log.txt`

## 3. 文件地图

- `www/index.html` — 应用本体：CSS / 内联静态 SVG 表盘 / JS 全部内联，单文件即可运行
- `server.js` + `启动服务器.bat` — 本地测试服务器（打印 Phone URL / Demo URL）
- `deploy.ps1` + `部署到github.bat` — 一键推送 dev + main 并触发 Pages 部署
- `.github/workflows/pages.yml` — GitHub Pages 自动部署工作流（源目录 `www/`）
- `make-icon.py` + `icon-1024.png` — App 图标生成脚本与源图
- `www/icon-1024.png` / `www/icon-180.png` / `www/favicon-32.png` — 各尺寸图标
- `www/manifest.webmanifest` + `www/sw.js` — PWA 说明与离线缓存（安卓安装成 App / iOS 添加到主屏幕）
- `capacitor.config.json` / `package.json` — Capacitor 原生封装配置（appId `com.turtleworks.turtlecompass`）
- `CLAUDE.md` — 项目级 AI 指引；`README.md` — 人类可读说明；`commit-msg.txt` — 部署脚本用的提交信息模板

## 4. 完整开发历程（按用户问题出现顺序）

每一条格式：问题现象 → 根因 → 修复方式。

1. **初版开发**：方向 + 海拔 + 经纬度指南针，UI 仿 iOS 自带指南针，`www/index.html` 单文件。
2. **iPhone Edge 浏览器只显示文字、无法启动** → 页面结构/兼容问题 → 修复渲染，同时去掉「点击启动指南针」按钮，打开直接进入运行界面（此后一直是自动启动，无启动遮罩）。
3. **iOS 26 表盘空白** → JS 动态生成 SVG 在 iOS 26 上失败 → 表盘改为**内联静态 SVG**（刻度、度数、北东南西、红白指北针全静态），JS 只负责旋转和更新数据。
4. **经纬高正常但表盘不转动** → 方向事件不兼容 → 优先读 iOS Safari 的 `webkitCompassHeading`，兜底 `deviceorientationabsolute.alpha`；同时监听 `deviceorientation` 与 `deviceorientationabsolute` 两个事件。
5. **微信发送 index.html 无法用 Safari 打开** → 微信屏蔽本地文件「用其他应用打开」 → 改用 GitHub Pages 网址打开，或用数据线/电脑传文件。
6. **首次部署 GitHub Pages** → 建立 `pages.yml` 工作流、`部署到github.bat` 双分支推送流。
7. **不知道在哪里看局域网地址** → 本地服务器改为启动时直接打印 Phone URL 与 Demo URL。
8. **要一键脚本** → `启动服务器.bat` 双击即启动、关窗口即停止。
9. **Safari 仍提示不支持方向传感器、经纬度无法获取** → HTTP 局域网地址不是安全上下文，Safari 拦截定位/方向 → 引导用 HTTPS 的 GitHub Pages；页内加 `isSecureContext` 检测与中文提示。
10. **怎么新建 GitHub 仓库** → 给出点对点建仓库步骤（空仓库、不勾 README）。
11. **GitHub Actions 部署失败系列**（每个都是独立坑，均已修复）：
    - `configure-pages` 报 Get Pages site Not Found → workflow 加 `enablement: true`
    - workflow 报 `Unexpected value 'administration'` → `permissions` 去掉非法字段，只留 `contents: read`、`pages: write`、`id-token: write`
    - `Branch "main" is not allowed to deploy due to environment protection rules` → 用户曾手动给仓库环境 `github-pages` 设置 main 分支保护规则，需删除/放行（仓库 Settings → Environments）
    - `Node.js 20 is deprecated` → 无害警告，不影响部署
12. **部署成功但方向仍无法启用** → 加入 iOS 13+ `DeviceOrientationEvent.requestPermission()` 权限流程，黄色按钮点击触发系统权限弹窗。
14. **底部白边 + 图标 + 表盘位置 + 城市区域**（2026-08-13）：修复界面底部白色区域（html/body 固定黑底）；图标重设计为简约风格；表盘上移 14px；表盘下方新增当前城市区域显示（逆地理编码，见第 6 节）；后续字号调至 25px 白色。

13. **打开要等 + 每次点黄色按钮** → 本轮优化：打开自动请求权限 + `localStorage` 记忆授权 + 2.5 秒兜底按钮（详见第 5 节）；同时海拔字体 22→25px、经纬度 17→19px、经纬间隔 2→3 空格；新增 App 图标（详见第 7 节）。

15. **安卓能否打开 / 下载成 App**（2026-08-13）→ 链接本身安卓 Chrome/Edge 可直接打开；为支持「安装成 App」增加 PWA：`www/index.html` 加 manifest 链接与 Service Worker 注册，新增 `www/manifest.webmanifest`（standalone 全屏、黑底、icon-180/icon-1024）与 `www/sw.js`（ttcompass-v1 缓存，网络优先+缓存回退，离线可开）。安卓 Chrome 菜单「安装应用」，iPhone Safari「分享→添加到主屏幕」。

对应提交（`git log --oneline --reverse`）：`dc7032c`(v0.1 发布) → `73bff83`/`affe325`/`3c4f615`/`a8b0c80`(部署修复系列) → `2a33f9a`(方向权限修复) → `42d9a2e`(权限优化+图标) → `f14cfe1`(权限兜底按钮)。

## 5. 方向权限状态机（当前行为，改动前必读）

**每次打开都需点击一次按钮**（用户明确要求，2026-08-13 改动）：

1. 打开页面 → 黄色按钮立即可见，提示「点击下方黄色按钮，启用方向」，此时不监听方向事件。
2. 点击按钮 → iOS 13+ 调用 `DeviceOrientationEvent.requestPermission()`：
   - `granted` → 绑定方向事件监听，开始显示方位
   - `denied` → 提示「Safari 地址栏点 aA → 网站设置 允许」，按钮重新显示
3. 无 `requestPermission`（Android/桌面）→ 点击后直接绑定监听。
4. 拿到方向数据后自动隐藏按钮；6 秒无数据提示「转动手机获取方向…」。
5. 无自动请求、无 localStorage 授权记忆。
## 6. UI 参数（用户对字号/间距有明确偏好，改动前先确认）

- 海拔 `.value`：25px；经纬度 `.coords`：19px；海拔比经纬度调得更多
- 经纬度之间间隔：3 个空格（配合 `white-space: pre` 生效），用户嫌小只加一点点
- 表盘：SVG `viewBox 0 0 400 400`，北东南西大字 + 30° 刻度；中间红/灰指针在独立固定层 `.needle` 中，不随表盘旋转、始终指向手机顶端，长度已缩短避免遮挡北/南文字；表盘顶部白色指示线（向下小箭头）已按用户要求删除；JS 只旋转 `#dial`（`rotate(-heading)`）
- 配色：黑底 `#000`，标签灰、警示黄 `#ffd60a`（同启用按钮）、错误红 `#ff453a`
- 底部白边修复：`html, body` 固定黑色背景（曾出现界面底部白色区域，是 html 默认白底露出）
- 表盘整体上移 14px（`.compass-stage { margin-top: -14px }`）
- 表盘下方 `.city-line` 显示当前城市区域：BigDataCloud 逆地理编码为主、Nominatim 兜底；定位精度 >1200m 时不解析，避免首次定位误差显示错城市；字号 25px 白色（用户要求调大并改白）；`margin-top: 48px` 整体下移约 2 行（用户两次要求下移）
- 打开即运行：无启动按钮、无遮罩；页内 `window.onerror` 把 JS 错误显示到表盘下方提示区，便于真机排查

## 7. App 图标

- `make-icon.py`（Python + PIL）生成三档尺寸：1024 / 180 / 32 px；2026-08-13 重设计为简约风格 = 纯黑背景 + 白色细圆环 + 四向短刻度 + 红色朝上指针 + 绿色六边形中心（龟壳品牌元素），无文字无纹理
- 重新生成：`python make-icon.py`
- `www/index.html` 已加 `<link rel="apple-touch-icon">`（iPhone 添加到主屏幕图标）和 favicon

## 8. 部署链路与已知坑

### 8.1 正常流程

双击 `部署到github.bat` → `deploy.ps1`：用 `commit-msg.txt` 提交 → 推 `main:dev` → 推 `release-basic:main` → 校验远程。main 推送会触发 `.github/workflows/pages.yml`，把 `www/` 部署到 Pages，1-2 分钟生效。

### 8.2 必须满足的前提

- git 必须走代理 `127.0.0.1:7897`（Clash 需开启）；**不要**给用户设置全局 git 代理（AGENTS.md 约定）
- 仓库 Settings → Pages → Source 选 **GitHub Actions**（一次性设置）
- 仓库 Settings → Environments → `github-pages` 若存在 main 分支保护规则需删除/放行（曾因此拒绝部署）
- workflow `permissions` 只能有 `contents: read`、`pages: write`、`id-token: write`；`configure-pages` 必须带 `enablement: true`

### 8.3 已知坑速查

- `HttpError: Not Found / Get Pages site failed` → Pages 源没选 GitHub Actions，或缺少 `enablement: true`
- `Unexpected value 'administration'` → permissions 里有非法字段
- `Branch "main" is not allowed to deploy` → 环境保护规则拦截
- `Node.js 20 is deprecated` → 无害警告，忽略
- iPhone 看不到新版本 → 下拉刷新，仍不行清 Safari 网站数据（缓存问题）

## 9. 原生封装前必须知道（路线 A：Capacitor）

- **WKWebView 默认不触发 `deviceorientation` 事件** → 封装成原生 App 前必须接原生方向传感器插件或 Swift 桥接 `CMMotionManager`，否则表盘不转
- Xcode `Info.plist` 需补：`NSMotionUsageDescription`（运动与方向）、`NSLocationWhenInUseUsageDescription`（定位）、`CFBundleDisplayName` = 指南龟
- 用户还没有 Mac，计划买 Mac mini M4；网页版先跑通验证
- 步骤：`npm install` → `npx cap add ios` → `npx cap sync` → 接传感器插件 → `npx cap open ios`

## 10. 下一步建议

- 等 Mac 到位后按第 9 节完成原生封装（首个上架练手 App，AGENTS.md 建议选审核零风险品类，指南针符合）
- 可迭代方向：真机磁力计校准提示、水平仪（倾斜提示已有雏形）、差异化功能、App Store 上架流程
- 若继续改 UI：先问用户字号/间距偏好（第 6 节）

## 11. 给后续 AI 的检查清单

- 改完 `www/index.html`：提取内联 `<script>` 用 `node --check` 验语法；本地开 `?demo=1` 预览界面
- 改完代码：中文 commit（格式见 AGENTS.md 规则 3），然后提醒用户双击 `部署到github.bat` 推送到真机测试
- 不要破坏的既有约定：每次打开需点击黄色按钮才开始显示方向（用户明确要求）、内联静态 SVG 表盘、中间红/灰指针固定朝上、已缩短不挡字、顶部无白色指示线、Pages 双分支部署链路
- 交流：全程中文、结论先行、术语首次出现给括号解释、给方案给具体选项不给开放式提问
- 关键决策/新约定出现时更新本文件或 `CLAUDE.md`，保持交接文档不过期
