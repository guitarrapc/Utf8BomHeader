#!/usr/bin/env pwsh
[OutputType([void])]
param (
    [string]$NuGetApiKey,
    [string]$BuildBranch
)

# validation
if ($env:APPVEYOR_REPO_BRANCH -notmatch $BuildBranch) {
    Write-Host "`"Appveyor`" deployment has been skipped as environment variable has not matched (`"$env:APPVEYOR_REPO_BRANCH`" is `"$branch`", should be `"$branch`""
    exit
}
if ([string]::IsNullOrWhiteSpace($env:APPVEYOR_REPO_TAG)) {
    Write-Host "`"Appveyor`" deployment has been skipped as environment variable has not matched (`"$env:APPVEYOR_REPO_TAG`" is blank)"
    exit
}
if ([string]::IsNullOrWhiteSpace($NuGetApiKey)) {
    Write-Warning "`"Appveyor`" deployment has been skipped as `"NuGetApiKey`" is not specified."
    return;
}

Write-Host 'Running AppVeyor deploy script' -ForegroundColor Green

# environment variables
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleName = Split-Path -Path $here -Leaf
$modulePath = Join-Path "$here" "publish/Utf8BomHeader"
$version = $env:APPVEYOR_REPO_TAG_NAME

# Update module manifest # 
Write-Host 'Creating new module manifest'
. ./run_build.ps1 -Version $version

# Publish to PS Gallery # 
Write-Host "Adding $modulePath to 'psmodulepath' PATH variable"
$env:psmodulepath = "${modulePath}:${env:psmodulepath}"

Write-Host 'Publishing module to Powershell Gallery'
Publish-Module -Name $moduleName -NuGetApiKey $NuGetApiKey