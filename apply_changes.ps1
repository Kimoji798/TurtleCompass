$ErrorActionPreference = "Stop"
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$p = Join-Path $base "www\index.html"
if (-not (Test-Path $p)) { Write-Host "找不到 www\index.html，请确认脚本放在 TTcompass_DS 目录里"; Read-Host "按回车关闭"; exit 1 }
$c = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)

$v14 = ".city-line {`n  margin-top: 10px;`n  min-height: 18px;`n  font-size: 14px;`n  color: var(--label);`n  letter-spacing: 1px;`n}"
$v17a = ".city-line {`n  margin-top: 10px;`n  min-height: 20px;`n  font-size: 17px;`n  color: var(--label);`n  letter-spacing: 1px;`n}"
$v17b = ".city-line {`n  margin-top: 36px;`n  min-height: 20px;`n  font-size: 17px;`n  color: var(--label);`n  letter-spacing: 1px;`n}"
$final = ".city-line {`n  margin-top: 48px;`n  min-height: 24px;`n  font-size: 20px;`n  color: var(--label);`n  letter-spacing: 1px;`n}"

if ($c.Contains($final)) { Write-Host "已经是目标样式，无需重复修改"; Read-Host "按回车关闭"; exit 0 }
if ($c.Contains($v14)) { $c = $c.Replace($v14, $final) }
elseif ($c.Contains($v17a)) { $c = $c.Replace($v17a, $final) }
elseif ($c.Contains($v17b)) { $c = $c.Replace($v17b, $final) }
else { Write-Host "没有找到城市行样式，可能版本不对，请把本窗口内容发给 Codex"; Read-Host "按回车关闭"; exit 1 }

[IO.File]::WriteAllText($p, $c, (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host "修改完成："
Write-Host "  1. 城市区域字号 17px -> 20px"
Write-Host "  2. 城市区域再下移 12px（margin-top 36px -> 48px）"
Write-Host "部署后手机上打开：https://kimoji798.github.io/TTcompass/"
Write-Host ""
Read-Host "按回车关闭"