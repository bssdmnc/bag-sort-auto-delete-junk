$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$addon = "$root\addon\BagSortAutoDeleteJunk"
$version = (Select-String -Path "$addon\BagSortAutoDeleteJunk.toc" -Pattern '## Version: (.+)').Matches[0].Groups[1].Value
New-Item -ItemType Directory -Force "$root\dist" | Out-Null
$zip = "$root\dist\BagSortAutoDeleteJunk-$version.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path $addon -DestinationPath $zip
Get-Item $zip | Select-Object Name, Length
