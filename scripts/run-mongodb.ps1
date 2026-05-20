param(
    [int]$Port = 27017
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$mongod = & (Join-Path $root "scripts\ensure-mongodb.ps1")
$dataDir = Join-Path $root ".data\mongodb"
$logDir = Join-Path $root ".logs"
$logPath = Join-Path $logDir "mongodb.log"

New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

Write-Host "Starting MongoDB on mongodb://localhost:$Port"
& $mongod --dbpath $dataDir --bind_ip 127.0.0.1 --port $Port --logpath $logPath --logappend
