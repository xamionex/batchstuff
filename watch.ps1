param (
  [Alias("c")]
  [Parameter(Mandatory)]
  [String[]] $command,
  [Alias("d", "t")]
  [String[]] $delay = 2
)
Clear-Host
While ($True) { [console]::CursorVisible = $False; Invoke-Expression "$command"; Start-Sleep -Seconds "$delay"; [console]::CursorVisible = $True; $host.UI.RawUI.CursorPosition = [PSCustomObject] @{X = 0; Y = 0 } }