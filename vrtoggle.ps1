
$toggletype = $args[0]

function ParseObjectLevel {
	param(
		[string[]]$lines,
		[ref]$currentLine = ([ref]0),
		[string]$RegExCompare = '\A\s*((?<key>"[^"]+")|(?<brace>[\{\}]))\s*(?<lineValue>"[^"]*")?\Z'
	)

	$currTable = [ordered]@{}
	while ($currentLine.Value -lt $lines.count) {
		if ($lines[$currentLine.Value] -match $RegExCompare) {
			if ($matches.key) { $currKey = $matches.key }
			if ($matches.lineValue) { $currTable.$currKey = $matches.lineValue }
			elseif ($matches.brace -eq '{') {
				$currentLine.Value++
				$currTable.$currKey = ParseObjectLevel -lines $lines `
					-currentLine $currentLine -RegExCompare $RegExCompare
			}
			elseif ($matches.brace -eq '}') {
				break
			}
		}
		$currentLine.Value++
	}
	return $currTable
}

function Enable {
	if (Test-Path -Path "$resolvedpath\SteamVR\bin\win64\vrmonitor_disabled.exe") {
		Rename-Item "$resolvedpath\SteamVR\bin\win64\vrmonitor_disabled.exe" "$resolvedpath\SteamVR\bin\win64\vrmonitor.exe"
	}
	Write-Output "SteamVR was found at $resolvedpath\SteamVR and enabled."
	exit
}

function Disable {
	if (Test-Path -Path "$resolvedpath\SteamVR\bin\win64\vrmonitor.exe") {
		Rename-Item "$resolvedpath\SteamVR\bin\win64\vrmonitor.exe" "$resolvedpath\SteamVR\bin\win64\vrmonitor_disabled.exe"
	}
	Write-Output "SteamVR was found at $resolvedpath\SteamVR and disabled."
	exit
}

$steam = (Get-Item HKCU:\Software\Valve\Steam).GetValue("SteamPath")
$libraryfolders = New-Object PSCustomObject (ParseObjectLevel -lines (Get-Content "${steam}/steamapps/libraryfolders.vdf"))
foreach ($library in $libraryfolders[0].Keys) {
	$path = ($libraryfolders[0]."$library".'"path"'.Replace("`"", "")) + "\\steamapps\\common"
	foreach ($app in $libraryfolders[0]."$library".'"apps"'.Keys) {
		if ($app -eq '"250820"') {
			$found = $true
			$resolvedpath = Resolve-Path -LiteralPath $path
			break
		}
	}
}
if (!$found) {
	Write-Output "Couldn't find SteamVR"
	exit
}

if ((Test-Path -Path "$resolvedpath\SteamVR\bin\win64\vrmonitor_disabled.exe") -and (Test-Path -Path "$resolvedpath\SteamVR\bin\win64\vrmonitor.exe")) {
	Remove-Item "$resolvedpath\SteamVR\bin\win64\vrmonitor_disabled.exe" -Force
}

if ($toggletype -eq "disable") {
	Disable
}
elseif ($toggletype -eq "enable") {
	Enable
}

if (Test-Path -Path "$resolvedpath\SteamVR\bin\win64\vrmonitor.exe") {
	Disable
}
else {
	Enable
}