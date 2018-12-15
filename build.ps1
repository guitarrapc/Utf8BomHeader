#!/usr/bin/env pwsh
[OutputType([void])]
param (
    [string]$Version
)
$path = "$pwd/src/Utf8BomHeader.psd1"
$guid = "11da18bb-f0d4-4509-b709-8b17efd8bb17"
$publish = "./publish/Utf8BomHeader"
$targets = "Utf8BomHeader.ps*1"

# test
docker build -t utf8bomheader_peseter:$Version .
docker run utf8bomheader_peseter:$Version .
if (!$?) {
   return 1
}

# setup
function Update([string]$Path, [string]$Version, [string]$Guid){
    New-ModuleManifest -Path $Path -Guid $Guid -Author guitarrapc -Copyright guitarrapc -ModuleVersion $Version -RootModule Utf8BomHeader.psm1 -Description "PowerShell Module to operate UTF8-Bom Header" -CompatiblePSEditions Core,Desktop -Tags UTF8BOM -ProjectUri https://github.com/guitarrapc/Utf8BomHeader -LicenseUri https://github.com/guitarrapc/Utf8BomHeader/blob/master/LICENSE.md
}

function Prepare([string]$Path) {
    if (Test-Path $Path) {
        Remove-Item $Path -Force -Recurse
    }
    New-Item -Path $Path -ItemType Directory -Force    
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    Write-Warning "Version not specified, please specify semantic version."
    return;
}
if (Test-Path $path) {
    $manifest = Invoke-Expression (cat $path -Raw)
    if ($manifest.ModuleVersion -eq $Version) {
        Write-Warning "Same version specified, nothing to do."
        return;
    }
}
Update -Path $path -Version $Version -Guid $Guid
Prepare -Path ./publish/Utf8BomHeader
Copy-Item -Path src/*,LICENSE.md -Destination "$publish/"