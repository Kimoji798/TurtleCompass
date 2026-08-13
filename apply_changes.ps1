$ErrorActionPreference = "Stop"
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$p = Join-Path $base "www\index.html"
if (-not (Test-Path $p)) { Write-Host "找不到 www\index.html，请确认脚本放在 TTcompass_DS 目录里"; Read-Host "按回车关闭"; exit 1 }
$c = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)

if ($c.Contains('id="cityLine"') -and $c.Contains('margin-top: -14px;')) {
  Write-Host "界面部分已经修改过，仅重新生成图标"
} else {
  $bak = Join-Path $base ("index_backup_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".html")
  Copy-Item $p $bak -Force

  $old1 = "html,`nbody {`n  margin: 0;`n  padding: 0;`n  height: 100%;`n}"
  $new1 = "html,`nbody {`n  margin: 0;`n  padding: 0;`n  height: 100%;`n  background: #000000;`n}"
  if (-not $c.Contains($old1)) { throw "html/body 锚点未找到" }
  $c = $c.Replace($old1, $new1)

  $old2 = '  background: radial-gradient(120% 80% at 50% 26%, #2c2c2e 0%, #101012 55%, #000000 100%);'
  $new2 = $old2 + "`n" + '  background-color: #000000;'
  if (-not $c.Contains($old2)) { throw "body 渐变锚点未找到" }
  $c = $c.Replace($old2, $new2)

  $old3 = ".compass-stage {`n  position: relative;`n  width: 80vw;"
  $new3 = ".compass-stage {`n  position: relative;`n  margin-top: -14px;`n  width: 80vw;"
  if (-not $c.Contains($old3)) { throw "表盘锚点未找到" }
  $c = $c.Replace($old3, $new3)

  $cityCss = ".city-line {`n  margin-top: 10px;`n  min-height: 18px;`n  font-size: 14px;`n  color: var(--label);`n  letter-spacing: 1px;`n}`n`n"
  $i = $c.IndexOf('.level-hint {')
  if ($i -lt 0) { throw "level-hint 锚点未找到" }
  $c = $c.Insert($i, $cityCss)

  $old4 = '<button id="enableBtn" class="enable-btn" type="button">点击启用方向</button>'
  if (-not $c.Contains($old4)) { throw "按钮锚点未找到" }
  $c = $c.Replace($old4, ($old4 + "`n" + '      <div class="city-line" id="cityLine">正在识别位置…</div>'))

  $old5 = '    levelHint: document.getElementById("levelHint")'
  if (-not $c.Contains($old5)) { throw "els 锚点未找到" }
  $c = $c.Replace($old5, ($old5 + "," + "`n" + '    cityLine: document.getElementById("cityLine")'))

  $old6 = '  var heading = null;'
  if (-not $c.Contains($old6)) { throw "heading 锚点未找到" }
  $c = $c.Replace($old6, ($old6 + "`n" + '  var geoCoded = false;'))

  $jsLines = @(
'  /* ---------- 城市区域（逆地理编码） ---------- */',
'  function maybeReverseGeocode(pos) {',
'    var acc = typeof pos.coords.accuracy === "number" ? pos.coords.accuracy : null;',
'    if (geoCoded || (acc !== null && acc > 1200)) {',
'      return;',
'    }',
'    geoCoded = true;',
'    reverseGeocode(pos.coords.latitude, pos.coords.longitude);',
'  }',
'',
'  function reverseGeocode(lat, lon) {',
'    var url = "https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=" + lat + "&longitude=" + lon + "&localityLanguage=zh";',
'    fetch(url).then(function (r) {',
'      return r.json();',
'    }).then(function (d) {',
'      var parts = [];',
'      if (d.city) { parts.push(d.city); }',
'      if (d.locality && d.locality !== d.city) { parts.push(d.locality); }',
'      if (!parts.length && d.principalSubdivision) { parts.push(d.principalSubdivision); }',
'      if (!parts.length && d.countryName) { parts.push(d.countryName); }',
'      els.cityLine.textContent = parts.length ? parts.join(" ") : "未能识别所在区域";',
'    }).catch(function () {',
'      var u2 = "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=" + lat + "&lon=" + lon + "&zoom=12&accept-language=zh-CN";',
'      fetch(u2).then(function (r) {',
'        return r.json();',
'      }).then(function (d) {',
'        var a = d.address || {};',
'        var parts = [];',
'        if (a.city) { parts.push(a.city); }',
'        else if (a.town) { parts.push(a.town); }',
'        var sub = a.suburb || a.city_district || a.county;',
'        if (sub && sub !== parts[0]) { parts.push(sub); }',
'        if (!parts.length && a.state) { parts.push(a.state); }',
'        els.cityLine.textContent = parts.length ? parts.join(" ") : (a.country || "未能识别所在区域");',
'      }).catch(function () {',
'        els.cityLine.textContent = "未能识别所在区域";',
'      });',
'    });',
'  }',
'',
'  '
)
  $js = $jsLines -join "`n"
  $k = $c.IndexOf('  function startGeolocation() {')
  if ($k -lt 0) { throw "startGeolocation 锚点未找到" }
  $c = $c.Insert($k, $js)

  $old7 = "  function onPosition(pos) {`n    renderPosition(pos.coords);`n  }"
  $new7 = "  function onPosition(pos) {`n    renderPosition(pos.coords);`n    maybeReverseGeocode(pos);`n  }"
  if (-not $c.Contains($old7)) { throw "onPosition 锚点未找到" }
  $c = $c.Replace($old7, $new7)

  $checks = [ordered]@{
    城市行已添加 = $c.Contains('id="cityLine"')
    城市样式已添加 = $c.Contains('.city-line {')
    底部黑底修复 = ([regex]::Matches($c, 'background: #000000;')).Count -ge 1 -and $c.Contains('background-color: #000000;')
    表盘已上移 = $c.Contains('margin-top: -14px;')
    逆地理编码已添加 = $c.Contains('function reverseGeocode') -and $c.Contains('function maybeReverseGeocode')
    定位回调已接线 = $c.Contains('maybeReverseGeocode(pos);')
  }
  $bad = @($checks.GetEnumerator() | Where-Object { -not $_.Value })
  if ($bad.Count -gt 0) { Write-Host ("校验失败: " + ($bad.Name -join ", ")); Write-Host "文件未改动"; Read-Host "按回车关闭"; exit 1 }

  [IO.File]::WriteAllText($p, $c, (New-Object Text.UTF8Encoding($false)))
  Write-Host "界面修改完成："
  Write-Host "  1. 底部白色区域已修复（背景固定黑色）"
  Write-Host "  2. 表盘整体上移 14px"
  Write-Host "  3. 表盘下方新增城市区域行（定位后自动显示）"
  Write-Host ("  4. 原文件已备份到 " + $bak)
}

Set-Location $base
$iconOk = $false
foreach ($py in @("python", "py")) {
  if (Get-Command $py -ErrorAction SilentlyContinue) {
    & $py make-icon.py
    if ($LASTEXITCODE -eq 0) { $iconOk = $true; break }
  }
}
if ($iconOk) {
  Write-Host "  5. App 图标已重新生成（简约风格：黑底白环 + 红针 + 绿色六边形）"
} else {
  Write-Host "提示：未找到 Python 或图标生成失败，请把本窗口内容发给 Codex"
}

$claudePath = Join-Path $base "CLAUDE.md"
try {
  if (Test-Path $claudePath) {
    $cl = [IO.File]::ReadAllText($claudePath, [Text.Encoding]::UTF8)
    $oldA = '坐标：度分秒（DMS）+ 十进制度双显示。'
    $newA = '坐标：度分秒（DMS）+ 十进制度双显示。' + "`n" + '- 城市区域：表盘下方显示逆地理编码结果（BigDataCloud 为主、Nominatim 兜底；精度 >1200m 时不解析）。'
    if ($cl.Contains($oldA) -and -not $cl.Contains('逆地理编码结果')) { $cl = $cl.Replace($oldA, $newA) }
    $oldB = '定位/方向可能需要安全上下文（HTTPS 或 localhost），HTTP 局域网地址可能被浏览器拦截。'
    $newB = $oldB + "`n" + '- 界面：html/body 固定黑底（修复底部白边），表盘上移 14px；App 图标为简约风格（黑底白环 + 红针 + 绿色六边形中心），由 `make-icon.py` 生成。'
    if ($cl.Contains($oldB) -and -not $cl.Contains('修复底部白边')) { $cl = $cl.Replace($oldB, $newB) }
    [IO.File]::WriteAllText($claudePath, $cl, (New-Object Text.UTF8Encoding($false)))
  }
} catch { Write-Host ("CLAUDE.md 更新跳过: " + $_.Exception.Message) }

Write-Host ""
Read-Host "按回车关闭"