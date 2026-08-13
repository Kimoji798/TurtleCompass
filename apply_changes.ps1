$ErrorActionPreference = "Stop"
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$p = Join-Path $base "www\index.html"
if (-not (Test-Path $p)) { Write-Host "找不到 www\index.html，请确认脚本放在 TTcompass_DS 目录里"; Read-Host "按回车关闭"; exit 1 }
$c = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)

$old = ".city-line {`n  margin-top: 48px;`n  min-height: 24px;`n  font-size: 20px;`n  color: var(--label);`n  letter-spacing: 1px;`n}"
$new = ".city-line {`n  margin-top: 48px;`n  min-height: 28px;`n  font-size: 24px;`n  color: var(--label);`n  letter-spacing: 1px;`n}"

if ($c.Contains($new)) { Write-Host "已经是 24px，无需重复修改"; Read-Host "按回车关闭"; exit 0 }
if (-not $c.Contains($old)) { Write-Host "没有找到 20px 的城市行样式，可能版本不对，请把本窗口内容发给 Codex"; Read-Host "按回车关闭"; exit 1 }

$c = $c.Replace($old, $new)
[IO.File]::WriteAllText($p, $c, (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host "修改完成：城市区域字号 20px -> 24px（位置不变）"
Write-Host "部署后手机上打开：https://kimoji798.github.io/TTcompass/"
Write-Host ""
Read-Host "按回车关闭"