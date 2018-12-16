#!/usr/bin/env pwsh
[OutputType([void])]
param (
    [string]$NuGetApiKey,
    [string]$BuildBranch
)

# validation
if ($env:APPVEYOR_REPO_BRANCH -notmatch $BuildBranch) {
    Write-Host -ForeGroundColor Yellow "`"Appveyor`" deployment has been skipped as environment variable has not matched (`"$env:APPVEYOR_REPO_BRANCH`" is `"$branch`", should be `"$branch`""
    return
}
if ([string]::IsNullOrWhiteSpace($env:APPVEYOR_REPO_TAG_NAME)) {
    Write-Host -ForeGroundColor Yellow "`"Appveyor`" deployment has been skipped as environment variable has not matched (`"$env:APPVEYOR_REPO_TAG_NAME`" is blank)"
    return
}
if ([string]::IsNullOrWhiteSpace($NuGetApiKey)) {
    Write-Host -ForeGroundColor Yellow "`"Appveyor`" deployment has been skipped as `"NuGetApiKey`" is not specified."
    return
}

# Run
Write-Host -ForegroundColor Green 'Running AppVeyor deploy script'

# environment variables
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleName = "Utf8BomHeader"
$modulePath = Join-Path "$here/publish/$moduleName/$moduleName.psd1"
$manifestPath = "$here/src/$moduleName.psd1"
$version = $env:APPVEYOR_REPO_TAG_NAME
$releaseNoteUrl = "https://github.com/guitarrapc/Utf8BomHeader/releases/tag/$version"

# Update module manifest 
Write-Host -ForegroundColor Green 'Creating new module manifest'
. ./run_build.ps1 -Version $version

# Test Version is correct
$manifest = Invoke-Expression (Get-Content $manifestPath -Raw)
if ($manifest.ModuleVersion -ne $Version) {
    throw "`"Appveyor`" deployment has been canceled. Version update failed (`Manifest Version is `"${$manifest.ModuleVersion}`", should be `"$version`")"
}

# Publish to PS Gallery
Write-Host -ForeGroundColor Green 'Publishing module to Powershell Gallery'
Import-Module $modulePath -PassThru | Publish-Module -NuGetApiKey $NuGetApiKey -ReleaseNotes $releaseNoteUrl
