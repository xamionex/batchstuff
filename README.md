# terrible code i randomly make in batch/ps1 for no reason

### phone.bat
downloads scrcpy and vdesk for use
- phone silent: launches cmd in background
- phone vr: launches with vdesk and switches the scrcpy window to 2nd virtual desktop
- phone silentvr: calls silent then vr
- phone kill: kills adb and scrcpy
- phone update_scrcpy: redownloads scrcpy
- phone update_vdesk: redownloads vdesk

### NMI.ps1
bad code for making all minecraft instances linked, to be used with prismlauncher \
running from console as 
 - `NMI.ps1 "path\to\instance\"`
 - `NMI.ps1 "C:\Users\Petar\AppData\Roaming\PrismLauncher\instances\Versatile"`

### checkcontroller.ps1
checks whether or not a controller by the name "Wireless Controller" is connected and outputs to a file in the same directory

### steamlocator.ps1
Locates a game with steamlibrary file with the given id
- steamlocator -id x
- steamlocator -id 480

### timer.ps1
Shutdowns computer after a certain amount of time
-t for time defaults to 5m, -r for restart, -s for shutdown delay takes only numbers
- timer -t 1h1m1s -r -s 30
- timer -t 30m
- timer -t 5m -r
- timer -r

### vrtoggle.ps1
Toggles steamvr's vrmonitor.exe, very useful for something like roblox
No args toggles between off and on, disable disables vr, enable enables vr
- vrtoggle
- vrtoggle enable
- vrtoggle disable

### watch.ps1
Watch command that works similar to the one in linux
-c/command, -t/delay
- watch -c "fastfetch"
- watch -c "fastfetch" -t 1
