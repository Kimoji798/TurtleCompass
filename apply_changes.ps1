$ErrorActionPreference = "Stop"
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$p = Join-Path $base "www\index.html"
if (-not (Test-Path $p)) { Write-Host "找不到 www\index.html，请确认脚本放在 TTcompass_DS 目录里"; Read-Host "按回车关闭"; exit 1 }
$c = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)

if ($c.IndexOf('.pointer {') -lt 0 -and $c.Contains('200,126')) { Write-Host "已经修改过，无需重复运行"; Read-Host "按回车关闭"; exit 0 }

$bak = Join-Path $base ("index_backup_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".html")
Copy-Item $p $bak -Force

$i = $c.IndexOf('.pointer {')
$j = $c.IndexOf('.level-hint {')
if ($i -lt 0 -or $j -lt 0 -or $j -le $i) { throw "CSS 锚点未找到 i=$i j=$j" }
$c = $c.Substring(0, $i) + $c.Substring($j)

$c = [regex]::Replace($c, '\r?\n<div class="pointer" aria-hidden="true"></div>', '')

$oldPoly = '<polygon points="191,200 209,200 200,78" fill="#ff453a"/>'
if (-not $c.Contains($oldPoly)) { throw "指针多边形锚点未找到" }
$newPolys = '<polygon points="191,200 209,200 200,126" fill="#ff453a"/>' + "`n" + '<polygon points="191,200 209,200 200,274" fill="#e5e5ea"/>'
$c = $c.Replace($oldPoly, $newPolys)

$checks = [ordered]@{
  顶部指示线已删除 = (-not $c.Contains('<div class="pointer"')) -and (-not $c.Contains('.pointer {'))
  灰色下半已加回 = ([regex]::Matches($c, '200,274')).Count -eq 1
  橙色已缩短 = $c.Contains('200,126')
  旧长指针已去掉 = -not $c.Contains('200,78') -and -not $c.Contains('200,322')
}
$bad = @($checks.GetEnumerator() | Where-Object { -not $_.Value })
if ($bad.Count -gt 0) { Write-Host ("校验失败: " + ($bad.Name -join ", ")); Write-Host "文件未改动"; Read-Host "按回车关闭"; exit 1 }

[IO.File]::WriteAllText($p, $c, (New-Object Text.UTF8Encoding($false)))

$claudePath = Join-Path $base "CLAUDE.md"
try {
  if (Test-Path $claudePath) {
    $cl = [IO.File]::ReadAllText($claudePath, [Text.Encoding]::UTF8)
    $cl = $cl.Replace('中间红色指针在独立固定层，不随表盘旋转、始终指向手机顶端。', '中间红/灰指针在独立固定层，不随表盘旋转、始终指向手机顶端，长度已缩短避免遮挡文字；表盘顶部白色指示线（向下小箭头）已按用户要求删除。')
    [IO.File]::WriteAllText($claudePath, $cl, (New-Object Text.UTF8Encoding($false)))
    $docUpdated = $true
  }
} catch { Write-Host ("CLAUDE.md 更新跳过: " + $_.Exception.Message) }

Write-Host ""
Write-Host "修改完成："
Write-Host "  1. 表盘顶部向下的白色箭头（指示线）已删除"
Write-Host "  2. 中间连圆心的灰色下半箭头已加回"
Write-Host "  3. 橙色和灰色指针已缩短，不再挡住文字"
Write-Host ("  4. 原文件已备份到 " + $bak)
if ($docUpdated) { Write-Host "  5. CLAUDE.md 已同步更新" }
Write-Host ""
Read-Host "按回车关闭"