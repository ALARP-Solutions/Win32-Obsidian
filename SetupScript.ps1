Param(
    [Parameter(Mandatory=$true,Position=0)]
    [ValidateSet("u", "i")]
    [String]$Value
)

if ($value -eq "i") {
    If (!(Test-Path "$env:LOCALAPPDATA\Obsidian")) {
        New-Item -Path "$env:LOCALAPPDATA\Obsidian" -ItemType Directory
    }
    Copy-Item "Obsidian\*" "$env:LOCALAPPDATA\Obsidian" -Recurse
    $target = "$env:LOCALAPPDATA\Obsidian\Obsidian.exe"
    $shortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Obsidian.lnk"
    $ws = New-Object -ComObject WScript.Shell
    $s = $ws.CreateShortcut($shortcut)
    $S.TargetPath = $target
    $S.Save()
} else {
    Remove-Item "$env:LOCALAPPDATA\obsidian-updater" -Recurse -Force -ErrorAction Ignore
    Remove-Item "$env:LOCALAPPDATA\Obsidian" -Recurse -Force -ErrorAction Ignore
    Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Obsidian.lnk" -Force -ErrorAction Ignore
}