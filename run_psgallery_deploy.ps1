#!/usr/bin/env pwsh
[OutputType([void])]
param (
    [string]$NuGetApiKey,
    [string]$BuildBranch
)

# validation
if ($env:APPVEYOR_REPO_BRANCH -notmatch $BuildBranch) {
    Write-Host "`"Appveyor`" deployment has been skipped as environment variable has not matched (`"$env:APPVEYOR_REPO_BRANCH`" is `"$branch`", should be `"$branch`"" -ForGroundColor Yellow
    return
}
if ([string]::IsNullOrWhiteSpace($env:APPVEYOR_REPO_TAG_NAME)) {
    Write-Host "`"Appveyor`" deployment has been skipped as environment variable has not matched (`"$env:APPVEYOR_REPO_TAG_NAME`" is blank)" -ForGroundColor Yellow
    return
}
if ([string]::IsNullOrWhiteSpace($NuGetApiKey)) {
    Write-Host "`"Appveyor`" deployment has been skipped as `"NuGetApiKey`" is not specified." -ForGroundColor Yellow
    return
}

# Run
Write-Host 'Running AppVeyor deploy script' -ForegroundColor Green

# environment variables
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleName = Split-Path -Path $here -Leaf
$modulePath = Join-Path "$here" "publish"
$manifestPath = Join-Path "$modulePath/$moduleName" "$moduleName.psd1"
$version = $env:APPVEYOR_REPO_TAG_NAME

# Update module manifest 
Write-Host 'Creating new module manifest' -ForGroundColor Green
. ./run_build.ps1 -Version $version

# Test Version is correct
$manifest = Invoke-Expression (Get-Content $manifestPath -Raw)
if ($manifest.ModuleVersion -ne $Version) {
    Write-Host "`"Appveyor`" deployment has been canceled. Version update failed (`Manifest Version is `"${$manifest.ModuleVersion}`", should be `"$version`")" -ForGroundColor Yellow
    throw
}

# Publish to PS Gallery
Write-Host "Adding $modulePath to 'psmodulepath' PATH variable" -ForGroundColor Green
$env:psmodulepath = "${modulePath}:${env:psmodulepath}"
Write-Host 'Publishing module to Powershell Gallery' -ForGroundColor Green
Publish-Module -Name $moduleName -NuGetApiKey $NuGetApiKey