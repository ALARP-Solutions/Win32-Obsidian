$vers = "0.14.6"

## ------------------------------ ##
## Create Build Folder
## ------------------------------ ##

$buildpath = "$PSScriptRoot\Builds\"

If (-Not (Test-Path $buildpath)) {
    New-Item -Path "$buildpath" -Name "" -ItemType "directory" | Out-Null
}

## ------------------------------ ##
## Create Temp Folder
## ------------------------------ ##

$temppath = "$PSScriptRoot\tempWIN32-Obsidian"
If (Test-Path $temppath) {
    $relocation = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
    Move-Item $temppath $relocation
    Remove-Item -LiteralPath "$relocation\tempWIN32-Obsidian" -Recurse -Force -Confirm:$false
}
New-Item $temppath -ItemType "directory" | Out-Null

## ------------------------------ ##
## Copy Inputs into Temp Folder
## ------------------------------ ##

$installcmd = "powershell.exe -executionpolicy bypass -command `"& '%~dp0Setup.ps1' i`""
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines("$temppath\Install.cmd", $installcmd, $Utf8NoBomEncoding)

$uninstallcmd = "powershell.exe -executionpolicy bypass -command `"& '%~dp0Setup.ps1' u`""
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines("$temppath\Uninstall.cmd", $uninstallcmd, $Utf8NoBomEncoding)

Copy-Item "$PSScriptRoot\SetupScript.ps1" "$temppath\Setup.ps1"

## ------------------------------ ##
## Download Obsidian
## ------------------------------ ##

$url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v$vers/Obsidian.$vers.exe"
$filepath = "$temppath\Obsidian.$vers.exe"

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $filepath)

## ------------------------------ ##
## Extract Obsidian & Clean Up
## ------------------------------ ##
./7z.exe x -aoa "$temppath\Obsidian.$vers.exe" -o"$temppath\TempX"
./7z.exe x -aoa "$temppath\TempX\`$PLUGINSDIR\app-64.7z" -o"$temppath\Obsidian\"

## Cleanup
$relocation = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
Move-Item "$temppath\TempX" $relocation
Move-Item $filepath "$relocation\TempX"
Remove-Item -LiteralPath "$relocation\TempX" -Recurse -Force -Confirm:$false

## ------------------------------ ##
## Build the Intunewin File
## ------------------------------ ##
$Testpath = "$buildpath\logioptionsplus_installer.intunewin"
if (Test-Path $Testpath) {
    Remove-Item $Testpath
}

& "$PSScriptRoot\Microsoft Win32 Content Prep Tool\IntuneWinAppUtil.exe" -c "$temppath" -s "$temppath\Setup.ps1" -o "$buildpath"

## ------------------------------ ##
## Clean-Up - Pause here for debug
## ------------------------------ ##
If (Test-Path $temppath) {
    $relocation = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
    Move-Item $temppath $relocation
    Remove-Item -LiteralPath "$relocation\tempWIN32-Obsidian" -Recurse -Force -Confirm:$false
}
