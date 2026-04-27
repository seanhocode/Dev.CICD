param (
    [Parameter(Mandatory=$true)]
    [string]$GithubToken
)

$ProjectPath = Split-Path -Path $PSScriptRoot -Parent
. "$ProjectPath\SeanTool.Scripts\Shell\Windows\PowerShell\DotNet\PackTool.ps1"

#==================================參數設定==================================
$GithubOwner = "seanhocode"
$SourceUrl   = "https://nuget.pkg.github.com/$GithubOwner/index.json"
$PackageFolderName = "nupkgs"
$RepoName = "$GithubOwner/Dev.CICD"
$LatestTag = "latest"

$TargetFolder = Join-Path $ProjectPath $PackageFolderName

$ProjectsToPack = @(
    (Join-Path $ProjectPath "MyTool"),
    (Join-Path $ProjectPath "MyApp")
)
#==================================參數設定==================================

#==================================產生nupkg=================================
PackProject -ProjectFullPaths $ProjectsToPack -TargetFolder $TargetFolder
#==================================產生nupkg=================================

#==================================發布至github package======================
# 根據csproj裡設定的版本更新
$packages = Get-ChildItem -Path $TargetFolder -Filter "*.nupkg"

if ($packages.Count -eq 0) {
    Write-Warning "Not found in '$TargetFolder'"
    exit
}

foreach ($pkg in $packages) {
    PushNuGetPackage `
        -PackagePath $pkg.FullName `
        -Source $SourceUrl `
        -ApiKey $GithubToken `
        -SkipDuplicate
}
#==================================發布至github package======================

#==================================更新 latest Tag 至最新 Commit=============
Write-Host "========================================"
Write-Host "Moving '$LatestTag' tag to the latest commit..."

# 1. 強制將本地的 latest 標籤指向當前最新的 commit (-f 代表強制覆寫本地標籤)
git -C $ProjectPath tag -f $LatestTag

# 2. 強制將更新後的標籤推送到 GitHub 遠端 (--force 代表強制覆寫遠端標籤)
git -C $ProjectPath push origin $LatestTag --force

Write-Host "========================================"
#==================================更新 latest Tag 至最新 Commit=============

#==================================發布至github release======================
# 根據main最新程式更新
UpdateGitHubRelease `
    -FilePath (Join-Path $TargetFolder "*.nupkg") `
    -Repo $RepoName `
    -Tag $LatestTag `
    -Token $GithubToken
#==================================發布至github release======================