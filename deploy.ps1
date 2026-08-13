param(
  [string]$RepoName = "",
  [switch]$Dry
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($RepoName)) {
  $RepoName = Read-Host "输入 GitHub 仓库名 [ttcompass]"
}
if ([string]::IsNullOrWhiteSpace($RepoName)) { $RepoName = "ttcompass" }

$pushArgs = @("-c", "http.proxy=http://127.0.0.1:7897", "-c", "https.proxy=http://127.0.0.1:7897")

if (-not (Test-Path ".git")) { git init -b main | Out-Null }

if (-not (git config user.name)) { git config user.name "Kimoji798" }
if (-not (git config user.email)) { git config user.email "kimoji798@users.noreply.github.com" }

git add .
git commit -F commit-msg.txt 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "(没有新改动，跳过提交)" }

git remote remove origin 2>$null
git remote add origin "https://github.com/Kimoji798/$RepoName.git"

if ($Dry) {
  Write-Host ""
  Write-Host "[DRY] 跳过推送"
  Write-Host "[DRY] 远程仓库: https://github.com/Kimoji798/$RepoName.git"
  Write-Host "[DRY] 网站地址: https://kimoji798.github.io/$RepoName/"
  exit 0
}

Write-Host ""
Write-Host "推送完整版到 dev 分支..."
git @pushArgs push -u origin main:dev
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "[错误] 推送失败。检查："
  Write-Host "1. 仓库已创建: https://github.com/Kimoji798/$RepoName"
  Write-Host "2. Clash 代理已运行 (127.0.0.1:7897)"
  Write-Host "3. 首次推送会弹出 GitHub 登录窗口，完成后重跑本脚本"
  Read-Host "按回车关闭"
  exit 1
}

Write-Host "推送发布版到 main 分支（GitHub Pages）..."
git branch release-basic 2>$null
git branch -f release-basic main
git @pushArgs push -u origin release-basic:main
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "[错误] main 推送失败，请重跑本脚本"
  Read-Host "按回车关闭"
  exit 1
}

Write-Host ""
Write-Host "=============================================="
Write-Host "  推送完成！一次性设置（仅第一次）："
Write-Host "  GitHub 仓库 - Settings - Pages"
Write-Host "  Source 选 GitHub Actions - Save"
Write-Host "  等 1-2 分钟，然后用手机打开："
Write-Host "  https://kimoji798.github.io/$RepoName/"
Write-Host "=============================================="
Read-Host "按回车关闭"