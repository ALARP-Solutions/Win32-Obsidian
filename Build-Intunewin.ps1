
# Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
# Install-Module -Name 7Zip4Powershell -Scope CurrentUser -Verbose
#Import-Module 7Zip4PowerShell

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

$installcmd = @(
    'ROBOCOPY "%~dp0Obsidian" "%LOCALAPPDATA%\Obsidian" /mir'
    'set TARGET="%LOCALAPPDATA%\Obsidian\Obsidian.exe"'
    'set SHORTCUT="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Obsidian.lnk"'
    'set PWS=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile'
    '%PWS% -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut(%SHORTCUT%); $S.TargetPath = %TARGET%; $S.Save()"'
)
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines("$temppath\Install.cmd", $installcmd, $Utf8NoBomEncoding)


$uninstallcmd = @(
    'del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Obsidian.lnk"'
    'del /f /q "%LOCALAPPDATA%\obsidian-updater"'
    'del /f /q "%LOCALAPPDATA%\Obsidian"'
)
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines("$temppath\Uninstall.cmd", $uninstallcmd, $Utf8NoBomEncoding)

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
./7z.exe x "$temppath\Obsidian.$vers.exe" -o"$temppath\TempX"
./7z.exe x "$temppath\TempX\`$PLUGINSDIR\app-64.7z" -o"$temppath\Obsidian\"

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

& "$PSScriptRoot\Microsoft Win32 Content Prep Tool\IntuneWinAppUtil.exe" -c "$temppath" -s "$filepath" -o "$buildpath"

## ------------------------------ ##
## Clean-Up
## ------------------------------ ##
If (Test-Path $temppath) {
    $relocation = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
    Move-Item $temppath $relocation
    Remove-Item -LiteralPath "$relocation\tempWIN32-Obsidian" -Recurse -Force -Confirm:$false
}
