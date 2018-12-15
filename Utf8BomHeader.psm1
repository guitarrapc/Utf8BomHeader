$cs = @"
using System;
using System.IO;
using System.Linq;

public class Utf8BomHeaderCompareResult
{
    public string SourceFile { get; }
    public string SourceHeader { get; }
    public string Equality { get; }
    public string CompareFile { get; }
    public string CompareHeader { get; }
    
    public Utf8BomHeaderCompareResult(string sourceFile, string sourceHeader, string equality, string compareFile, string compareHeader)
    {
        SourceFile = sourceFile;
        SourceHeader = sourceHeader;
        Equality = equality;
        CompareFile = compareFile;
        CompareHeader = compareHeader;
    }
}

public static class FileHeader
{
    public static string Read(string path, int count)
    {
        using (var stream = new System.IO.FileStream(path, FileMode.Open))
        {
            var reads = Enumerable.Range(1, count).Select(x => stream.ReadByte().ToString("X2")).ToArray();
            return string.Join("", reads);
        }
    }

    public static string Read(FileInfo file, int count)
    {
        using (var stream = file.OpenRead())
        {
            var reads = Enumerable.Range(1, count).Select(x => stream.ReadByte().ToString("X2")).ToArray();
            return string.Join("", reads);
        }
    }

    public static void Write(string source, string dest, byte[] header)
    {
        var buffer = File.ReadAllBytes(source);
        var combine = Combine(header, buffer);
        File.WriteAllBytes(dest, combine);
    }

    public static void Write(FileInfo file, string dest, byte[] header)
    {
        byte[] buffer = null;
        using (var stream = file.OpenRead())
        {
            buffer = new byte[stream.Length];
            stream.Read(buffer, 0, (int)stream.Length);
        }
        var combine = Combine(header, buffer);
        File.WriteAllBytes(dest, combine);
    }

    public static void Remove(string source, string dest, int offset)
    {
        byte[] buffer = null;
        using (var stream = new FileStream(source, FileMode.Open))
        {
            buffer = new byte[stream.Length - offset];
            stream.Seek(offset, SeekOrigin.Current);
            stream.Read(buffer, 0, (int)stream.Length - offset);
        }
        File.WriteAllBytes(dest, buffer);
    }

    public static void Remove(FileInfo source, string dest, int offset)
    {
        byte[] buffer = null;
        using (var stream = source.OpenRead())
        {
            buffer = new byte[stream.Length - offset];
            stream.Seek(offset, SeekOrigin.Current);
            stream.Read(buffer, 0, (int)stream.Length - offset);
        }
        File.WriteAllBytes(dest, buffer);
    }
    
    public static Utf8BomHeaderCompareResult Compare(string sourcePath, string comparePath, int count, string check)
    {
        var sourceHeader = Read(sourcePath, count);
        var compareHeader = Read(comparePath, count);
        var sourceSymbol = sourceHeader == check ? "=" : "<";
        var compareSymbol = compareHeader == check ? "=" : ">";
        return new Utf8BomHeaderCompareResult(sourcePath, sourceHeader, sourceSymbol + compareSymbol, comparePath, compareHeader);
    }

    private static byte[] Combine(byte[] first, byte[] second)
    {
        byte[] ret = new byte[first.Length + second.Length];
        Buffer.BlockCopy(first, 0, ret, 0, first.Length);
        Buffer.BlockCopy(second, 0, ret, first.Length, second.Length);
        return ret;
    }
}
"@
Add-Type -TypeDefinition $cs -Language CSharpVersion7

New-Variable -Name removeOffset -Value 3 -Option Constant
New-Variable -Name bomHex -Value "EFBBBF" -Option Constant
New-Variable -Name bom -Value 239,187,191 -Option Constant

function Add-Utf8BomHeader {
    [CmdletBinding(DefaultParameterSetName = "File")]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "File")]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Path")]
        [Alias("LiteralPath", "PSPath")]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$OutputPath,

        [Switch]$Force
    )

    process {
        if ($PSBoundParameters.ContainsKey("File")) {
            if (!$Force) {
                $header = [FileHeader]::Read($File, $removeOffset)
                if ($header -eq $bomHex) {
                    Write-Verbose "Bom already exists."
                    return
                }
            } else {
                Write-Verbose "-Force paramter detected, skip checking bom header before operation."
            }
            [FileHeader]::Write($File, $OutputPath, $bom)
        }
        else {
            if (!$Force) {
                $header = [FileHeader]::Read($Path, $removeOffset)
                if ($header -eq $bomHex) {
                    Write-Verbose "Bom already exists."
                    return
                }
            } else {
                Write-Verbose "-Force paramter detected, skip checking bom header before operation."
            }
            [FileHeader]::Write($Path, $OutputPath, $bom)
        }
    }
}

function Remove-Utf8BomHeader {
    [CmdletBinding(DefaultParameterSetName = "File")]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "File")]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Path")]
        [Alias("LiteralPath", "PSPath")]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$OutputPath,

        [Switch]$Force
    )

    process {
        if ($PSBoundParameters.ContainsKey("File")) {
            if (!$Force) {
                $header = [FileHeader]::Read($File, $removeOffset)
                if ($header -ne $bomHex) {
                    Write-Verbose "header $header($bomHex) : Bom already missing."
                    return
                }
            } else {
                Write-Verbose "-Force paramter detected, skip checking bom header before operation."
            }
            [FileHeader]::Remove($File, $OutputPath, $removeOffset)
        }
        else {
            if (!$Force) {
                $header = [FileHeader]::Read($Path, $removeOffset)
                if ($header -ne $bomHex) {
                    Write-Verbose "header $header($bomHex) : Bom already missing."
                    return
                }
            } else {
                Write-Verbose "-Force paramter detected, skip checking bom header before operation."
            }
            [FileHeader]::Remove($Path, $OutputPath, $removeOffset)
        }
    }
}

function Get-Utf8BomHeader {
    [CmdletBinding(DefaultParameterSetName = "File")]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "File")]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Path")]
        [Alias("LiteralPath", "PSPath")]
        [string]$Path,

        [Alias("Count")]
        [int]$ReadCount = $removeOffset
    )

    process {
        if ($PSBoundParameters.ContainsKey("File")) {
            $header = [FileHeader]::Read($File, $ReadCount)
            Write-Output $header
        }
        else {
            $header = [FileHeader]::Read($Path, $ReadCount)
            Write-Output $header
        }
    }
}

function Compare-Utf8BomHeader {
    [OutputType([Utf8BomHeaderCompareResult])]
    param(
        [Parameter(Mandatory = $true)]
        [Alias("Source")]
        [string]$ReferenceFile,

        [Parameter(Mandatory = $true)]
        [Alias("Target")]
        [string]$DifferenceFile
    )

    $compare = [FileHeader]::Compare($ReferenceFile, $DifferenceFile, $removeOffset, $bomHex)
    Write-Output $compare
}

function Test-Utf8BomHeader {
    [CmdletBinding(DefaultParameterSetName = "File")]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "File")]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Path")]
        [Alias("LiteralPath", "PSPath")]
        [string]$Path
    )

    process {
        if ($PSBoundParameters.ContainsKey("File")) {
            $header = [FileHeader]::Read($File, $removeOffset)
            Write-Output ($header -eq $bomHex)
        }
        else {
            $header = [FileHeader]::Read($Path, $removeOffset)
            Write-Output ($header -eq $bomHex)
        }
    }
}

function Test-Utf8BomHeaderPS {
    [CmdletBinding(DefaultParameterSetName = "File")]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "File")]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Path")]
        [Alias("LiteralPath", "PSPath")]
        [string]$Path
    )

    process {
        if ($PSBoundParameters.ContainsKey("File")) {
            [System.IO.FileStream]$stream
            try {
                $stream = $File.OpenRead()
                $header = (1..3 | ForEach-Object {$stream.ReadByte().ToString("X2")}) -join ""
                Write-Output ($header -eq $bomHex)
            }
            finally {
                $stream.Dispose();
            }
        }
        else {
            [System.IO.FileStream]$stream
            try {
                $stream = [System.IO.FileStream]::New($Path, [System.IO.FileMode]::Open)
                $header = (1..3 | ForEach-Object {$stream.ReadByte().ToString("X2")}) -join ""
                Write-Output ($header -eq $bomHex)
            }
            finally {
                $stream.Dispose();
            }
        }
    }
}

# $path = "D:\GitHub\guitarrapc\AWSLambdaCSharpIntroduction\AWSLambdaCSharpIntroduction.sln"
# $remove = "D:\GitHub\remove.sln"
# $add = "D:\GitHub\add.sln"
# Import-Module ./Utf8BomHeader.psm1 -Force -Verbose
# ls $path -File | Where-Object {Test-Utf8BomHeader -File $_}
# ls $path -File | Where-Object {Test-Utf8BomHeader -File $_} | Get-Utf8BomHeader
# ls $path -File | Where-Object {Test-Utf8BomHeader -File $_} | Remove-Utf8BomHeader -OutputPath $remove
# Get-Utf8BomHeader -Path $remove
# Add-Utf8BomHeader -Path $remove -OutputPath $add
# Get-Utf8BomHeader -Path $add
# Compare-Utf8BomHeader -ReferenceFile $path -DifferenceFile $add
Export-ModuleMember -Function *-Utf8BomHeader, *-Utf8BomHeaderPS
