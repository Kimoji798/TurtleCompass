# 指南龟（TurtleCompass）

面向 iPhone 的指南针应用，界面参考 iOS 自带指南针，显示：

- 当前朝向（度 + 中文八方位）
- 海拔
- 经纬度（度分秒 + 十进制度）

## 手机真机使用（推荐：GitHub Pages）

iOS Safari 只允许 HTTPS 页面使用定位和方向传感器，所以推荐部署到 GitHub Pages：

1. 在 github.com 用 Kimoji798 账号新建**空仓库**（名字如 `ttcompass`，不要勾选 README）。
2. 双击 `部署到github.bat`，输入仓库名，按回车。
3. 首次会弹出 GitHub 登录窗口，完成登录（需要 Clash 代理开着）。
4. 去仓库页面 Settings → Pages → Source 选 **GitHub Actions** → Save（只需设置一次）。
5. 等 1-2 分钟，手机上打开 `https://kimoji798.github.io/<仓库名>/`，允许「定位」和「运动与方向」权限即可。

以后每次改完代码，再双击一次 `部署到github.bat` 就会更新。

## 本地电脑预览

双击 `启动服务器.bat`，窗口里打印 `Phone URL` 和 `Demo URL`：

- `Phone URL`：手机连同一 WiFi 可打开，但 Safari 会因 HTTP 拦截定位/方向；`Demo URL`（`?demo=1`）不依赖传感器，适合验证界面。
- 关闭窗口 = 停止服务器。

## 项目结构

- `www/index.html` — 应用本体（CSS / SVG 表盘 / JS 全部内联，单文件即可运行）
- `server.js` + `启动服务器.bat` — 本地测试服务器
- `deploy.ps1` + `部署到github.bat` — 一键推送到 GitHub（dev + main）并触发 Pages 部署
- `.github/workflows/pages.yml` — GitHub Pages 自动部署工作流
- `capacitor.config.json` / `package.json` — Capacitor 原生封装配置

## 打包成 iOS App

当前为 Capacitor 套壳路线，网页版已可运行。等有 Mac 后：

```bash
npm install
npx cap add ios
npx cap sync
npx cap open ios
```

注意两点：
- WKWebView 默认不触发网页的 `deviceorientation`，封装前需接入原生方向传感器插件或 Swift 桥接 `CMMotionManager`，否则表盘不会转动。
- 在 Xcode 的 `Info.plist` 中补充：
  - `NSMotionUsageDescription`：用于读取指南针方向
  - `NSLocationWhenInUseUsageDescription`：用于显示海拔与经纬度
  - `CFBundleDisplayName`：指南龟

## 状态

active（首次开发中，尚未发布）。

## 给 AI 协作者

完整工程交接文档见 `HANDOFF.md`（开发历程、权限流程、部署链路与已知坑）。
