$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

$backup = "$here/backup"
$bomfile = "$here/bom.txt"
$nobomfile = "$here/nobom.txt"
$addbomfile = "$here/addbom.txt"
$tmpaddbomfile = "$here/temp.addbom.txt"
$tmpnobomfile = "$here/temp.nobom.txt"
$bom = "EFBBBF"

Describe "Utf8BomHeader" {
    BeforeAll {
        if (Test-Path $tmpaddbomfile) {
            Remove-Item $tmpaddbomfile -Force
        }
        if (Test-Path $tmpnobomfile) {
            Remove-Item $tmpnobomfile -Force
        }
        New-Item $backup -ItemType Directory -Force
        Copy-Item $here/*.txt -Destination $backup/
    }
    AfterAll {
        if (Test-Path $tmpaddbomfile) {
            Remove-Item $tmpaddbomfile -Force
        }
        if (Test-Path $tmpnobomfile) {
            Remove-Item $tmpnobomfile -Force
        }
        Copy-Item $backup/*.txt -Destination $here
    }

    It "Test should be pass for bom" {
        Test-Utf8BomHeader -Path $bomfile | Should be $true
    }

    It "Test should be fail for bomless" {
        Test-Utf8BomHeader -Path $nobomfile | Should be $false
    }

    It "Add should append BOM" {
        Add-Utf8BomHeader -Path $nobomfile -OutputPath $addbomfile
        Test-Utf8BomHeader -Path $addbomfile | Should be $true
        Get-Utf8BomHeader -Path $addbomfile | Should not be "$bom$bom"
    }

    It "Add should not operate when BOM already exists" {
        Add-Utf8BomHeader -Path $bomfile -OutputPath $tmpaddbomfile
        Test-Path $tmpaddbomfile | Should be $false
    }

    It "Add -Force should append BOM even already exists" {
        Add-Utf8BomHeader -Path $bomfile -OutputPath $tmpaddbomfile -Force
        Test-Utf8BomHeader -Path $tmpaddbomfile | Should be $true
        Get-Utf8BomHeader -Path $tmpaddbomfile -Count 6 | Should be "$bom$bom"
        Remove-Item $tmpaddbomfile
    }

    It "Remove should not contains BOM" {
        Remove-Utf8BomHeader -Path $bomfile -OutputPath $nobomfile
        Test-Utf8BomHeader -Path $nobomfile | Should be $false
        Get-Utf8BomHeader -Path $addbomfile | Should not be "$bom$bom"
    }

    It "Remove should not operate when BOM not exists" {
        Remove-Utf8BomHeader -Path $nobomfile -OutputPath $tmpnobomfile
        Test-Path $tmpnobomfile | Should be $false
    }

    It "Remove -Force should remove BOM even already not exists" {
        Remove-Utf8BomHeader -Path $nobomfile -OutputPath $tmpnobomfile -Force
        Test-Utf8BomHeader -Path $tmpnobomfile | Should be $false
        Get-Utf8BomHeader -Path $tmpnobomfile -Count 6 | Should not be (Get-Utf8BomHeader -Path $nobomfile -Count 6)
        Remove-Item $tmpnobomfile
    }

    It "Compare should return == when both contains BOM" {
        (Compare-Utf8BomHeader -ReferenceFile $bomfile -DifferenceFile $addbomfile).Equality | Should be "=="
    }

    It "Compare should return <= when reference not contains BOM" {
        (Compare-Utf8BomHeader -ReferenceFile $nobomfile -DifferenceFile $addbomfile).Equality | Should be "<="
    }

    It "Compare should return => when difference not contains BOM" {
        (Compare-Utf8BomHeader -ReferenceFile $bomfile -DifferenceFile $nobomfile).Equality | Should be "=>"
    }

    It "Compare should return <> when reference & difference not contains BOM" {
        (Compare-Utf8BomHeader -ReferenceFile $nobomfile -DifferenceFile $nobomfile).Equality | Should be "<>"
    }
}
