$ErrorActionPreference = "Stop"
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$p = Join-Path $base "www\index.html"
if (-not (Test-Path $p)) { Write-Host "找不到 www\index.html，请确认脚本放在 TTcompass_DS 目录里"; Read-Host "按回车关闭"; exit 1 }
$bak = Join-Path $base ("index_backup_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".html")
Copy-Item $p $bak -Force
$c = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)

$c = [regex]::Replace($c, '<polygon points="191,200 209,200 200,78" fill="#ff453a"/>\r?\n<polygon points="191,200 209,200 200,322" fill="#e5e5ea"/>\r?\n<circle cx="200" cy="200" r="13" fill="#1c1c1e" stroke="#ffffff" stroke-width="2"/>', '')

$needleLines = @(
'<div class="needle" aria-hidden="true">',
'<svg viewBox="0 0 400 400" width="100%" height="100%">',
'<polygon points="191,200 209,200 200,78" fill="#ff453a"/>',
'<circle cx="200" cy="200" r="13" fill="#1c1c1e" stroke="#ffffff" stroke-width="2"/>',
'</svg>',
'        </div>'
)
$needleBlock = $needleLines -join "`n"
$c = $c.Replace('<div class="pointer" aria-hidden="true"></div>', ($needleBlock + "`n" + '<div class="pointer" aria-hidden="true"></div>'))

$cssAnchorLines = @(
'.compass-dial svg {',
'  width: 100%;',
'  height: 100%;',
'  display: block;',
'}'
)
$cssAnchor = $cssAnchorLines -join "`n"
$cssAddLines = @(
'.needle {',
'  position: absolute;',
'  top: 0;',
'  left: 0;',
'  width: 100%;',
'  height: 100%;',
'  pointer-events: none;',
'  z-index: 2;',
'}',
'',
'.needle svg {',
'  width: 100%;',
'  height: 100%;',
'  display: block;',
'}'
)
$cssAdd = $cssAddLines -join "`n"
$c = [regex]::Replace($c, [regex]::Escape($cssAnchor) + "\r?\n", ($cssAnchor + "`n" + $cssAdd + "`n"))

$c = [regex]::Replace($c, '  var gestureBound = false;\r?\n', '')
$c = [regex]::Replace($c, '  var orientationState = "unknown";\r?\n', '')
$c = [regex]::Replace($c, '  var sawOrientationEvent = false;\r?\n', '')
$c = [regex]::Replace($c, '  var sawCompassData = false;\r?\n', '')
$c = [regex]::Replace($c, '  var checkCount = 0;\r?\n', '')
$c = [regex]::Replace($c, '    sawOrientationEvent = true;\r?\n', '')
$c = [regex]::Replace($c, '    sawCompassData = true;\r?\n', '')

$startAnchor = 'var GRANT_FLAG = "ttcompass-orientation-granted";'
$endAnchor = 'function startDemoMode() {'
$i1 = $c.IndexOf($startAnchor)
$i2 = $c.IndexOf($endAnchor)
if ($i1 -lt 0 -or $i2 -lt 0 -or $i2 -le $i1) { throw "锚点未找到 i1=$i1 i2=$i2" }

$newJSLines = @(
'  /* ---------- 方向权限（每次打开都需点击按钮） ---------- */',
'',
'  function hasRequestPermission() {',
'    return typeof DeviceOrientationEvent !== "undefined" &&',
'      typeof DeviceOrientationEvent.requestPermission === "function";',
'  }',
'',
'  function showEnableButton() {',
'    if (heading !== null || demoMode) {',
'      return;',
'    }',
'    els.enableBtn.classList.add("visible");',
'    showHint("点击下方黄色按钮，启用方向", "action");',
'  }',
'',
'  function hideEnableButton() {',
'    els.enableBtn.classList.remove("visible");',
'  }',
'',
'  function scheduleNoDataCheck() {',
'    window.setTimeout(function () {',
'      if (heading === null && !demoMode) {',
'        showHint("转动手机获取方向；若仍无反应，请检查 Safari 网站设置", "action");',
'      }',
'    }, 6000);',
'  }',
'',
'  function attachOrientationListeners() {',
'    window.addEventListener("deviceorientation", onOrientation, true);',
'    window.addEventListener("deviceorientationabsolute", onOrientation, true);',
'  }',
'',
'  function onEnableClick() {',
'    hideEnableButton();',
'    if (typeof DeviceOrientationEvent === "undefined") {',
'      showHint("当前浏览器不支持方向传感器，请用 Safari 打开", "error");',
'      return;',
'    }',
'    if (hasRequestPermission()) {',
'      DeviceOrientationEvent.requestPermission().then(function (state) {',
'        if (state === "granted") {',
'          attachOrientationListeners();',
'          showHint("", null);',
'          scheduleNoDataCheck();',
'        } else if (state === "denied") {',
'          showHint("权限被拒绝：Safari 地址栏点 aA → 网站设置 允许，或清除网站数据后重试", "error");',
'          showEnableButton();',
'        } else {',
'          showEnableButton();',
'        }',
'      }).catch(function () {',
'        showEnableButton();',
'      });',
'    } else {',
'      attachOrientationListeners();',
'      showHint("", null);',
'      scheduleNoDataCheck();',
'    }',
'  }',
'',
'  function startCompass() {',
'    startGeolocation();',
'    els.enableBtn.addEventListener("click", onEnableClick);',
'',
'    if (typeof DeviceOrientationEvent === "undefined") {',
'      showHint("当前浏览器不支持方向传感器，请用 Safari 打开", "error");',
'      return;',
'    }',
'',
'    // 每次打开都显示按钮，点击后才请求权限并绑定方向事件',
'    showEnableButton();',
'  }',
'',
'  /* ---------- 演示模式（桌面预览） ---------- */',
'  '
)
$newJS = $newJSLines -join "`n"
$c = $c.Substring(0, $i1) + $newJS + $c.Substring($i2)

$checks = [ordered]@{
  指针固定层 = ([regex]::Matches($c, '<div class="needle"')).Count -eq 1
  朝下箭头已删除 = ([regex]::Matches($c, '200,322')).Count -eq 0
  红针保留一根 = ([regex]::Matches($c, 'fill="#ff453a"')).Count -eq 1
  固定层样式 = $c.Contains('.needle svg')
  无自动授权记忆 = -not $c.Contains('ttcompass-orientation-granted') -and -not $c.Contains('rememberGrant') -and -not $c.Contains('wasGrantedBefore')
  每次打开显示按钮 = $c.Contains('每次打开都显示按钮')
}
$bad = @($checks.GetEnumerator() | Where-Object { -not $_.Value })
if ($bad.Count -gt 0) { Write-Host ("校验失败: " + ($bad.Name -join ", ")); Write-Host "文件未改动"; Read-Host "按回车关闭"; exit 1 }

[IO.File]::WriteAllText($p, $c, (New-Object Text.UTF8Encoding($false)))

$claudePath = Join-Path $base "CLAUDE.md"
try {
  if (Test-Path $claudePath) {
    $cl = [IO.File]::ReadAllText($claudePath, [Text.Encoding]::UTF8)
    $cl = $cl.Replace('（刻度、度数、北东南西、红白指北针），JS 只负责旋转与数据更新，避免 JS 生成 SVG 失败导致表盘空白。', '（刻度、度数、北东南西），JS 只负责旋转与数据更新，避免 JS 生成 SVG 失败导致表盘空白；中间红色指针在独立固定层，不随表盘旋转、始终指向手机顶端。')
    $cl = $cl.Replace('- iOS 13+ 的 `DeviceOrientationEvent.requestPermission()` 若未自动授予，会在首次轻触屏幕时重新请求（无遮挡按钮）。', '- 每次打开都显示黄色按钮，点击后才调用 iOS 13+ 的 `DeviceOrientationEvent.requestPermission()` 并绑定方向事件；无自动请求、无 localStorage 授权记忆（用户明确要求每次点击）。')
    [IO.File]::WriteAllText($claudePath, $cl, (New-Object Text.UTF8Encoding($false)))
    $docUpdated = $true
  }
} catch { Write-Host ("CLAUDE.md 更新跳过: " + $_.Exception.Message) }
Write-Host ""
Write-Host "修改完成："
Write-Host "  1. 每次打开都会显示黄色按钮，点击一下才启用方向"
Write-Host "  2. 表盘中间的红色指针固定不动、始终指向手机顶端"
Write-Host "  3. 中间朝下的白色箭头已删除"
$junk = @(
  (Join-Path $base "io_test.txt"),
  (Join-Path $base "probe_node2.txt"),
  "D:\TurtleWorks\io_test.txt",
  "D:\TurtleWorks\active\io_test.txt",
  "D:\TurtleWorks\active\TTvideo\probe.txt",
  "D:\TurtleWorks\active\TTvideo\www\p.txt",
  "D:\TurtleWorks\shipped\probe.txt",
  (Join-Path $base ".github\workflows\probe.txt"),
  (Join-Path $base ".git\probe.txt"),
  "D:\TurtleWorks\active\TTcompass_CC\www\p.txt"
)
foreach ($j in $junk) { if (Test-Path -LiteralPath $j) { Remove-Item -LiteralPath $j -Force } }
foreach ($d in @("D:\TurtleWorks\active\TTvideo\www", "D:\TurtleWorks\active\TTcompass_CC\www")) { if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d } }
Write-Host ("  4. 原文件已备份到 " + $bak)
if ($docUpdated) { Write-Host "  5. CLAUDE.md 已同步更新" }
Write-Host ""
Read-Host "按回车关闭"