

ROBOCOPY "%~dp0Obsidian" "%LOCALAPPDATA%\Obsidian" /mir

set TARGET='%LOCALAPPDATA%\Obsidian\Obsidian.exe'
set SHORTCUT='%APPDATA%\Microsoft\Windows\Start Menu\Programs\Obsidian.lnk'
set PWS=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile

%PWS% -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut(%SHORTCUT%); $S.TargetPath = %TARGET%; $S.Save()"