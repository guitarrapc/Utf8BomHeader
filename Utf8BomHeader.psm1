$cs = @"
using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;

public static class FileHeader
{
    public static string Read(string path, int count)
    {
        using (var stream = new System.IO.FileStream(path, FileMode.Open))
        {
            var reads = Enumerable.Range(1, count).Select(x => stream.ReadByte().ToString("x2")).ToArray();
            return string.Join("", reads);
        }
    }

    public static string Read(FileInfo file, int count)
    {
        using (var stream = file.OpenRead())
        {
            var reads = Enumerable.Range(1, count).Select(x => stream.ReadByte().ToString("x2")).ToArray();
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
    
    public static bool Compare(string source1, string source2)
    {
        var hash1 = GetFileHash(source1);
        var hash2 = GetFileHash(source2);
        return hash1 == hash2;
    }

    private static byte[] Combine(byte[] first, byte[] second)
    {
        byte[] ret = new byte[first.Length + second.Length];
        Buffer.BlockCopy(first, 0, ret, 0, first.Length);
        Buffer.BlockCopy(second, 0, ret, first.Length, second.Length);
        return ret;
    }

    private static string GetFileHash(string file)
    {
        using (FileStream stream = File.OpenRead(file))
        {
            var sha = new SHA256Managed();
            byte[] hash = sha.ComputeHash(stream);
            return BitConverter.ToString(hash).Replace("-", String.Empty);
        }
    }
}
"@
Add-Type -TypeDefinition $cs -Language CSharpVersion7

[byte[]]$bom = 239, 187, 191
$bomHex = "EFBBBF"
$removeOffset = 3

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
        [string]$OutputPath
    )

    process {
        if ($PSBoundParameters.ContainsKey("File")) {
            [FileHeader]::Write($File, $OutputPath, $bom)
        }
        else {
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
        [string]$OutputPath
    )

    process {
        if ($PSBoundParameters.ContainsKey("File")) {
            [FileHeader]::Remove($File, $OutputPath, $removeOffset)
        }
        else {
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
        [string]$Path
    )

    process {
        if ($PSBoundParameters.ContainsKey("File")) {
            $header = [FileHeader]::Read($File, 3)
            $header
        }
        else {
            $header = [FileHeader]::Read($Path, 3)
            $header
        }
    }
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
            $header = [FileHeader]::Read($File, 3)
            Write-Output ($header -eq $bomHex)
        }
        else {
            $header = [FileHeader]::Read($Path, 3)
            Write-Output ($header -eq $bomHex)
        }
    }
}

function Compare-Utf8BomHeader {
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [Alias("Source")]
        [string]$ReferenceFile,

        [Parameter(Mandatory = $true)]
        [Alias("Target")]
        [string]$DifferenceFile
    )

    $compare = [FileHeader]::Compare($ReferenceFile, $DifferenceFile)
    Write-Output $compare
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

# $path = "D:\GitHub\guitarrapc\AWSLambdaCSharpIntroduction"
# $remove = "D:\GitHub\remove.sln"
# $add = "D:\GitHub\add.sln"
# Import-Module ./Utf8BomHeader.psm1 -Force -Verbose
# ls $path -File | Where-Object {Test-Utf8BomHeader -File $_}
# ls $path -File | Where-Object {Test-Utf8BomHeader -File $_} | Get-Utf8BomHeader
# ls $path -File | Where-Object {Test-Utf8BomHeader -File $_} | Remove-Utf8BomHeader -OutputPath 
# Get-Utf8BomHeader -Path $remove
# Add-Utf8BomHeader -Path $remove -OutputPath $add
# Get-Utf8BomHeader -Path $add
# Compare-Utf8BomHeader -ReferenceFile $file -DifferenceFile $add
Export-ModuleMember -Function *-Utf8BomHeader, *-Utf8BomHeaderPS
