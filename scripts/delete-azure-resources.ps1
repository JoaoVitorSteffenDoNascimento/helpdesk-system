param(
    [string]$ResourceGroup = "rg-helpdesk-system"
)

$ErrorActionPreference = "Stop"

$az = "az"
$knownAz = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
if (-not (Get-Command $az -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $knownAz)) {
    $az = $knownAz
}

& $az group delete --name $ResourceGroup --yes --no-wait
Write-Host "Deletion started for resource group $ResourceGroup"
