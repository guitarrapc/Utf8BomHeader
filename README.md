[![Build status](https://ci.appveyor.com/api/projects/status/jvb3u412phhl43nh/branch/master?svg=true)](https://ci.appveyor.com/project/guitarrapc/utf8bomheader/branch/master)

## Utf8BomHeader

PowerShell Module to check file BOM on Utf8.

* :white_check_mark: Desktop
* :white_check_mark: NetCore

## Installation

```ps1
Install-Module Utf8BomHeader -Scope CurrentUser
```

## Functions

Function | Description
---- | ----
Add-Utf8BomHeader | Add BOM header to a file
Compare-Utf8BomHeader | Compare two files BOM header status
Get-Utf8BomHeader | Get header of a file
Remove-Utf8BomHeader | Remove BOM header from a file
Test-Utf8BomHeader | Test is BOM header is exists on a file

## Usage

See [Test](https://github.com/guitarrapc/Utf8BomHeader/blob/master/tests/Utf8BomHeader.Tests.ps1)

## Ref

C# code : https://gist.github.com/guitarrapc/aac20b599e519e48656ca1ae6f642834