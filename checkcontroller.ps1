$Device = $(Get-PnpDevice | Where-Object Name -Like "Wireless Controller")[0]
$InstanceID = $Device.InstanceID

$DeviceProperties = Get-PnpDeviceProperty -InstanceId "$InstanceID"

$IsPresent = $DeviceProperties | Where-Object { $_.KeyName -eq 'DEVPKEY_Device_IsPresent' } | Select-Object -ExpandProperty Data
$LastConnection = $DeviceProperties | Where-Object { $_.KeyName -eq 'DEVPKEY_Bluetooth_LastConnectedTime' } | Select-Object -ExpandProperty Data

$Connected = $($null -eq $LastConnection) -and $($IsPresent)
$Connected | Out-File -FilePath $PSScriptRoot\checkcontroller.txt
Write-Host `nDevice: $Device`nID: $InstanceID`nLast Connection: $LastConnection`nIs Present: $IsPresent`nConnected: $Connected