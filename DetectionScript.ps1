$File = "$env:LOCALAPPDATA\Obsidian\Obsidian.exe"
if ($file) {
    write-output "Obsidian detected, exiting"
    exit 0
}
else {
    exit 1
}