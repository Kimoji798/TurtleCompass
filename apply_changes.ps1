$ErrorActionPreference = "Stop"
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$www = Join-Path $base "www"
$p = Join-Path $www "index.html"
$manifestPath = Join-Path $www "manifest.webmanifest"
$swPath = Join-Path $www "sw.js"
$claudePath = Join-Path $base "CLAUDE.md"

function Count-Str($haystack, $needle) {
  return ([regex]::Matches($haystack, [regex]::Escape($needle))).Count
}

if (-not (Test-Path $p)) { Write-Host "找不到 www\index.html，请确认脚本放在 TTcompass_DS 目录里"; Read-Host "按回车关闭"; exit 1 }

$c = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)

$needPwa = -not ($c.Contains('rel="manifest"') -and (Test-Path $manifestPath) -and (Test-Path $swPath))

$oldCity = ".city-line {`n  margin-top: 48px;`n  min-height: 28px;`n  font-size: 24px;`n  color: var(--label);`n  letter-spacing: 1px;`n}"
$newCity = ".city-line {`n  margin-top: 48px;`n  min-height: 29px;`n  font-size: 25px;`n  color: #ffffff;`n  letter-spacing: 1px;`n}"
$cityCount = Count-Str $c $oldCity
$needCity = $cityCount -ge 1

if (-not $needPwa -and -not $needCity) { Write-Host "已经是最新（城市区域 25px 白色 + PWA 都已就绪），无需修改"; Read-Host "按回车关闭"; exit 0 }

if ($needCity) {
  if ($cityCount -ne 1) { Write-Host "锚点校验失败：城市区域样式块不唯一，未做任何修改。请把本窗口内容发给 Codex"; Read-Host "按回车关闭"; exit 1 }
  $c = $c.Replace($oldCity, $newCity)
}

if ($needPwa) {
  $anchorIcon = '<link rel="icon" type="image/png" sizes="32x32" href="favicon-32.png">'
  $anchorInit = '  init();'
  if ((Count-Str $c $anchorIcon) -ne 1) { Write-Host "锚点校验失败：没找到唯一的 favicon-32 图标链接，未做任何修改。请把本窗口内容发给 Codex"; Read-Host "按回车关闭"; exit 1 }
  if ((Count-Str $c $anchorInit) -ne 1) { Write-Host "锚点校验失败：没找到唯一的 init() 调用，未做任何修改。请把本窗口内容发给 Codex"; Read-Host "按回车关闭"; exit 1 }
  $manifestLink = "`n  <link rel=`"manifest`" href=`"manifest.webmanifest`">"
  $c = $c.Replace($anchorIcon, $anchorIcon + $manifestLink)
  $swBlock = "  if (`"serviceWorker`" in navigator) {`n    navigator.serviceWorker.register(`"./sw.js`");`n  }`n`n"
  $c = $c.Replace($anchorInit, $swBlock + $anchorInit)
}

[IO.File]::WriteAllText($p, $c, (New-Object Text.UTF8Encoding($false)))

$cAfter = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)
if ($needCity -and -not $cAfter.Contains($newCity)) { Write-Host "修改后校验失败：城市区域样式不符合预期，请把本窗口内容发给 Codex"; Read-Host "按回车关闭"; exit 1 }
if ($needPwa -and (-not $cAfter.Contains('rel="manifest"') -or -not $cAfter.Contains('navigator.serviceWorker.register'))) { Write-Host "修改后校验失败：index.html 内容不符合预期，请把本窗口内容发给 Codex"; Read-Host "按回车关闭"; exit 1 }

if ($needPwa) {
  $manifest = "{`n  `"name`": `"指南龟`",`n  `"short_name`": `"指南龟`",`n  `"description`": `"方向、海拔、经纬度指南针`",`n  `"start_url`": `"./`",`n  `"scope`": `"./`",`n  `"display`": `"standalone`",`n  `"orientation`": `"portrait`",`n  `"background_color`": `"#000000`",`n  `"theme_color`": `"#000000`",`n  `"icons`": [`n    { `"src`": `"icon-180.png`", `"sizes`": `"180x180`", `"type`": `"image/png`" },`n    { `"src`": `"icon-1024.png`", `"sizes`": `"1024x1024`", `"type`": `"image/png`", `"purpose`": `"any maskable`" }`n  ]`n}"
  [IO.File]::WriteAllText($manifestPath, $manifest, (New-Object Text.UTF8Encoding($false)))

  $sw = "const CACHE = `"ttcompass-v1`";`nconst ASSETS = [`"./`", `"./index.html`", `"./manifest.webmanifest`", `"./icon-180.png`", `"./icon-1024.png`", `"./favicon-32.png`"];`n`nself.addEventListener(`"install`", (e) => {`n  e.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(ASSETS)).then(() => self.skipWaiting()));`n});`n`nself.addEventListener(`"activate`", (e) => {`n  e.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim()));`n});`n`nself.addEventListener(`"fetch`", (e) => {`n  if (e.request.method !== `"GET`") { return; }`n  e.respondWith(`n    fetch(e.request)`n      .then((res) => {`n        if (res.ok && e.request.url.startsWith(self.location.origin)) {`n          const copy = res.clone();`n          caches.open(CACHE).then((cache) => cache.put(e.request, copy));`n        }`n        return res;`n      })`n      .catch(() => caches.match(e.request).then((m) => m || caches.match(`"./index.html`")))`n  );`n});"
  [IO.File]::WriteAllText($swPath, $sw, (New-Object Text.UTF8Encoding($false)))

  if (-not (Test-Path $manifestPath) -or -not (Test-Path $swPath)) { Write-Host "修改后校验失败：manifest 或 sw.js 未生成，请把本窗口内容发给 Codex"; Read-Host "按回车关闭"; exit 1 }

  if (Test-Path $claudePath) {
    $cl = [IO.File]::ReadAllText($claudePath, [Text.Encoding]::UTF8)
    $anchorClaude = '由 `make-icon.py` 生成。'
    if ($cl.Contains($anchorClaude) -and -not $cl.Contains('PWA：已加')) {
      $nl = "`n"
      $pwaNote = $nl + '- PWA：已加 `www/manifest.webmanifest` + `www/sw.js`，安卓 Chrome「安装应用」/添加到主屏幕，iOS Safari「分享→添加到主屏幕」全屏运行，离线缓存 `ttcompass-v1`。'
      $cl = $cl.Replace($anchorClaude, $anchorClaude + $pwaNote)
      [IO.File]::WriteAllText($claudePath, $cl, (New-Object Text.UTF8Encoding($false)))
    }
  }
}

Write-Host ""
Write-Host "修改完成："
if ($needCity) { Write-Host "  - 城市区域字号 24px -> 25px，颜色改为白色" }
if ($needPwa) {
  Write-Host "  - www/index.html：manifest 链接 + Service Worker 注册"
  Write-Host "  - 新增 www/manifest.webmanifest、www/sw.js（离线缓存，断网也能打开）"
}
Write-Host ""
Write-Host "接下来双击 部署到github.bat（输入 TTcompass 回车）推到 GitHub Pages"
if ($needPwa) {
  Write-Host "部署完成后："
  Write-Host "  - 安卓 Chrome/Edge：打开链接 -> 右上角菜单 -> 安装应用 / 添加到主屏幕"
  Write-Host "  - iPhone Safari：打开链接 -> 分享 -> 添加到主屏幕，之后全屏无地址栏"
}
Write-Host ""
Read-Host "按回车关闭"