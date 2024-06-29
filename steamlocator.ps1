param(
    [Alias("id")]
    [Parameter(Mandatory)]
    [String] $AppID
)

If (!(Test-Path "HKCU:\Software\Valve\Steam\Apps\$AppID")) {
    Write-Output "Couldn't find AppID in registry, wrong ID? ($AppID)"
    Exit
}

$SteamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam\").SteamPath
$GameName = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam\Apps\$AppID").Name
$SteamLibrary = "$SteamPath\steamapps\libraryfolders.vdf"
$SteamLibraryConverted = ('{' + $((Get-Content -Path "$SteamLibrary" -Raw) -Replace '\t', ' ' -Replace '(\s*".*")\n\s*\{', '$1: {' -Replace '"([^"]+)"\s+"([^"]+)?"', '"$1": "$2",' -Replace ',(\n\s+\})', '$1' -Replace '(\s*\})(\n\s*".*": )', '$1,$2') + '}') | ConvertFrom-Json

ForEach ($Library in $SteamLibraryConverted.libraryfolders.PSObject.Properties) {
    ForEach ($App in $Library.Value.Apps.PSObject.Properties) {
        If ($App.Name -eq "$AppID") {
            $GameLoc = $Library.Value.Path
        }
    }
}

<# If ($GameLoc[0] -ieq $SteamPath[0]) {
    $GameLoc = "$GameLoc\steamapps"
} #>

$GameLoc = ("$GameLoc\steamapps\common\") + ("$GameName" -Replace '[<>:"/\\|?*]', '')

While ($True) {
    If (Test-Path $GameLoc) {
        Return $GameLoc
    }
    Else {
        $GameLoc = (Read-Host -Prompt "Couldn't find $GameName ($AppID), enter path manually")
    }
}