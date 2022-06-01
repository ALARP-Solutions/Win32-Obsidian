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

$installcmd = "powershell.exe -executionpolicy bypass -command `"& './Setup.ps1' i`""
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines("$temppath\Install.cmd", $installcmd, $Utf8NoBomEncoding)

$uninstallcmd = "powershell.exe -executionpolicy bypass -command `"& './Setup.ps1' u`""
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines("$temppath\Uninstall.cmd", $uninstallcmd, $Utf8NoBomEncoding)

$SetupScript = @"
Param(
    [Parameter(Mandatory=`$true,Position=0)]
    [ValidateSet("u", "i")]
    [String]`$Value
)

if (`$value -eq "i") {
    If (!(Test-Path "`$env:LOCALAPPDATA\Obsidian")) {
        New-Item -Path "`$env:LOCALAPPDATA\Obsidian" -ItemType Directory
    }
    Copy-Item "Obsidian\*" "`$env:LOCALAPPDATA\Obsidian" -Recurse
    `$target = "`$env:LOCALAPPDATA\Obsidian\Obsidian.exe"
    `$shortcut = "`$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Obsidian.lnk"
    `$ws = New-Object -ComObject WScript.Shell
    `$s = `$ws.CreateShortcut(`$shortcut)
    `$S.TargetPath = `$target
    `$S.Save()
} else {
    Remove-Item "`$env:LOCALAPPDATA\obsidian-updater" -Recurse -Force -ErrorAction Ignore
    Remove-Item "`$env:LOCALAPPDATA\Obsidian" -Recurse -Force -ErrorAction Ignore
    Remove-Item "`$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Obsidian.lnk" -Force -ErrorAction Ignore
}
"@
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines("$temppath\Setup.ps1", $SetupScript, $Utf8NoBomEncoding)

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

# Download 7-Zip
$wc = New-Object System.Net.WebClient

# Download simple 7zr
$7zrPath = "$temppath\7zr.exe"
$wc.DownloadFile("https://www.7-zip.org/a/7zr.exe", $7zrPath)

# Download advance 7-Zip
$7zExtraPath = "$temppath\7z2107-extra.7z"
$wc.DownloadFile("https://www.7-zip.org/a/7z2107-extra.7z", $7zExtraPath)

# Extract 7za.exe
& $7zrPath e $7zExtraPath -o"$temppath" "7za.exe"
$7za = "$temppath\7za.exe"

& $7za x -aoa "$temppath\Obsidian.$vers.exe" -o"$temppath\Obsidian"

# clean up
Remove-Item $7zrPath
Remove-Item $7zExtraPath
Remove-Item $7za

## ------------------------------ ##
## Build the Intunewin File
## ------------------------------ ##
$Testpath = "$buildpath\Obsidian.$vers.intunewin"
if (Test-Path $Testpath) {
    Remove-Item $Testpath
}

& "$PSScriptRoot\Microsoft Win32 Content Prep Tool\IntuneWinAppUtil.exe" -c "$temppath" -s "$temppath\Setup.ps1" -o "$buildpath"
Rename-Item -Path "$buildpath\Setup.intunewin" -NewName "Obsidian.$vers.intunewin"

## ------------------------------ ##
## Build the Detection Script
## ------------------------------ ##
$DSpath = "$buildpath\DetectionScript.$vers.ps1"
if (Test-Path $DSpath) {
    Remove-Item $DSpath
}

$detectionScript = @"
`$FileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("`$env:LOCALAPPDATA\Obsidian\Obsidian.exe").FileVersion
#The below line trims the spaces before and after the version name
`$FileVersion = `$FileVersion.Trim();
if ([System.Version]`$FileVersion -ge [System.Version]'$vers') {
    #Write the version to STDOUT by default
    `$FileVersion
    exit 0
}
else {
    #Exit with non-zero failure code
    exit 1
}
"@
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines($DSpath, $detectionScript, $Utf8NoBomEncoding)

## ------------------------------ ##
## Clean-Up - Pause here for debug
## ------------------------------ ##
If (Test-Path $temppath) {
    $relocation = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
    Move-Item $temppath $relocation
    Remove-Item -LiteralPath "$relocation\tempWIN32-Obsidian" -Recurse -Force -Confirm:$false
}
