param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("api-gateway", "ticket-service", "user-service")]
    [string]$Service
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$mvn = & (Join-Path $root "scripts\ensure-maven.ps1")

$servicePath = Join-Path $root $Service
if (-not (Test-Path -LiteralPath $servicePath)) {
    throw "Service folder not found: $servicePath"
}

Write-Host "Starting $Service with portable Maven..."
& $mvn -f (Join-Path $servicePath "pom.xml") spring-boot:run
