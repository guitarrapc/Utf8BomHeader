#!/usr/bin/env pwsh
[OutputType([void])]
param (
    [string]$Version
)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$path = "$here/src/Utf8BomHeader.psd1"
$guid = "11da18bb-f0d4-4509-b709-8b17efd8bb17"
$publish = "./publish/Utf8BomHeader"
$targets = "Utf8BomHeader.ps*1"

# validation
if ([string]::IsNullOrWhiteSpace($Version)) {
    Write-Host -ForeGroundColor Yellow "Version not specified, please specify semantic version."
    return;
}
if (Test-Path $path) {
    $manifest = Invoke-Expression (Get-Content $path -Raw)
    if ($manifest.ModuleVersion -eq $Version) {
        Write-Host -ForeGroundColor Yellow "Same version specified, nothing to do."
        return;
    }
}

# setup
function Update([string]$Path, [string]$Version, [string]$Guid){
    New-ModuleManifest -Path $Path -Guid $Guid -PowerShellVersion 5.1 -Author guitarrapc -ModuleVersion $Version -RootModule Utf8BomHeader.psm1 -Description "PowerShell Module to operate UTF8-Bom Header" -CompatiblePSEditions Core,Desktop -Tags UTF8BOM -ProjectUri https://github.com/guitarrapc/Utf8BomHeader -LicenseUri https://github.com/guitarrapc/Utf8BomHeader/blob/master/LICENSE.md
}

function Prepare([string]$Path) {
    if (Test-Path $Path) {
        Remove-Item $Path -Force -Recurse
    }
    New-Item -Path $Path -ItemType Directory -Force    
}

# run
Update -Path $path -Version $Version -Guid $Guid
Prepare -Path ./publish/Utf8BomHeader
Copy-Item -Path src/*,*.md -Destination "$publish/"