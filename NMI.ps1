#at top of script
if (!
    #current role
    (New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
        #is admin?
    )).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
) {
    #elevate script and exit current non-elevated runtime
    Start-Process `
        -FilePath 'powershell' `
        -ArgumentList (
        #flatten to single array
        '-File', $MyInvocation.MyCommand.Source, $args `
        | % { $_ }
    ) `
        -Verb RunAs
    exit
}

function Test-ReparsePoint([string]$path) {
    $file = Get-Item $path -Force -ea SilentlyContinue
    return [bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

$selection = "$args"
if (Test-Path -LiteralPath "${selection}\.minecraft") { Set-Location -LiteralPath "${selection}\.minecraft" }
elseif (Test-Path -LiteralPath "${selection}\minecraft") { Set-Location -LiteralPath "${selection}\minecraft" }
else {
    Write-Host ".minecraft doesnt exist inside instance"
    exit
}

${curdir} = Get-Location
${appdatamc} = "${env:APPDATA}\.minecraft"
${folders} = "screenshots", "resourcepacks", "saves", "schematics", "shaderpacks", "texturepacks"

Write-Host "Created symlinks for:"
foreach (${folder} in ${folders}) {
    $instancefolder = "${curdir}\${folder}"
    $appdatafolder = "${appdatamc}\${folder}"

    # Create the folders if they don't exist
    if (!(Test-Path -LiteralPath ${instancefolder})) {
        New-Item -ItemType Directory "${instancefolder}"
    }
    if (!(Test-Path -LiteralPath ${appdatafolder})) {
        New-Item -ItemType Directory "${appdatafolder}"
    }

    if (Test-ReparsePoint "${instancefolder}") {
        Write-Host "(SKIPPED) (Already a symlink): ${folder}"
    }
    else {
        # Copy existing files to appdata folder and remove the instance folder, then create a symlink
        Copy-Item "${instancefolder}\*" -Destination "${appdatafolder}\" -Recurse
        Remove-Item "${instancefolder}" -Recurse -Force
        New-Item -ItemType SymbolicLink "${folder}" -Target "${appdatafolder}" -Force
    }
}

# Create if doesn't exist
if (!(Test-Path -LiteralPath "servers.dat")) {
    New-Item -ItemType File "servers.dat"
}
if (!(Test-Path -LiteralPath "${appdatamc}\servers.dat")) {
    New-Item -ItemType File "${appdatamc}\servers.dat"
}

# Check if servers.dat is already a symlink
if (Test-ReparsePoint "${curdir}\servers.dat") {
    Write-Host "(SKIPPED) (Already a symlink): servers.dat"
}
else {
    # Rename servers.dat to old_currdate and create symlink
    $DateStr = Get-Date -Format "yyyy-MM-dd-hh-mm-ss"
    Rename-Item "servers.dat" "servers.dat_old.${DateStr}"
    if (!(Test-Path -LiteralPath "${curdir}\servers.dat")) {
        New-Item -ItemType SymbolicLink "${curdir}\servers.dat" -Target "${appdatamc}\servers.dat"
    }
}