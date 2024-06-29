param(
    [Alias("t")]
    [String] $Time,
    [Alias("r")]
    [Switch] $Restart,
    [Alias("s")]
    [Int] $ShutdownTimer = 30
)

# Prompt user for input
if ($null -eq $Time) {
    $Time = Read-Host -Prompt "Enter time duration (e.g., 10h2m3s or 10h 2m 3s)"
}

# If input is empty, exit
if ([string]::IsNullOrEmpty($Time)) {
    $Time = "5m"
}

# Extract and calculate total seconds
$TotalSeconds = 0

# Match cases where there is no unit
([regex]::Matches($Time, '(\d+(?!.*[dDhHmMsS]))') | ForEach-Object {
    $TotalSeconds += $_.Value                       # Assume user is meaning seconds
})

# Match cases where there is a unit
([regex]::Matches($Time, '\d+[dD]|\d+[hH]|\d+[mM]|\d+[sS]') | ForEach-Object {
    $value = [int]($_.Value -replace '[^\d]')       # Extract numerical value
    $unit = "$($_.Value[-1])".ToLower()             # Extract unit and convert to lowercase
    switch ($unit) {
        "d" { $TotalSeconds += $value * 86400 }     # Convert days to seconds
        "h" { $TotalSeconds += $value * 3600 }      # Convert hours to seconds
        "m" { $TotalSeconds += $value * 60 }        # Convert minutes to seconds
        "s" { $TotalSeconds += $value }             # Seconds remain as they are
    }
})

function FormatSeconds {
    param($Seconds)
    Return '{0:dd\d\:hh\h\:mm\m\:ss\s}' -f ([timespan]::fromseconds($Seconds)) -replace ':?00[dhms]:?' -replace '0(\d)', '$1'
}

function Countdown {
    param(
        [Parameter(Mandatory)]
        [String] $Type,
        [Parameter(Mandatory)]
        [Int] $ShutdownTimer
    )
    switch ($Type) {
        'restart' {
            $ActivityText = "Press E to cancel RESTART"
            $StatusText = "Restarting in:"
            $ExitType = "shutdown /r"
        }
        'shutdown' {
            $ActivityText = "Press E to cancel SHUTDOWN"
            $StatusText = "Shutting down in:"
            $ExitType = "shutdown /s"
        }
    }
    Clear-Host
    $host.UI.RawUI.CursorPosition = [PSCustomObject] @{X = 0; Y = 0 }
    while ($ShutdownTimer -ne 0) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true).Key
            if ($key -in 'E') {
                Clear-Host
                Exit
            }
        }
        $ShutdownTimer -= 1
        Write-Progress -Activity $ActivityText -Status $StatusText -SecondsRemaining $ShutdownTimer
        Start-Sleep -Seconds 1
    }
    Invoke-Expression -Command "$ExitType"
    break
}

while ($True) {
    if ($Restart) {
        $Type = "restart"
        $WaitText = "RESTART"
    }
    else {
        $Type = "shutdown"
        $WaitText = "SHUTDOWN"
    }
    for ($i = 1; $i -le $TotalSeconds; $i++ ) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true).Key
            if ($key -in 'E') {
                Clear-Host
                Exit
            }
        }
        Write-Progress -Activity "Waiting $(FormatSeconds($TotalSeconds)) to $WaitText | Press E to EXIT" -Status "Elapsed: $(FormatSeconds($i)) | Remaining: $(FormatSeconds($TotalSeconds - $i))" -PercentComplete $(($i / $TotalSeconds) * 100)
        Start-Sleep -Seconds 1
    }
    Countdown -Type "$Type" -ShutdownTimer $ShutdownTimer
}