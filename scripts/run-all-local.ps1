param(
    [string]$MongoUri = $env:SPRING_DATA_MONGODB_URI
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$logsDir = Join-Path $root ".logs"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

if ([string]::IsNullOrWhiteSpace($MongoUri)) {
    $MongoUri = "mongodb://localhost:27017"
}

Write-Host "Using MongoDB URI base: $MongoUri"
Write-Host "If localhost MongoDB is not running, this script will start the portable MongoDB copy."

$mvn = & (Join-Path $root "scripts\ensure-maven.ps1")

function Start-HelpdeskJob {
    param(
        [string]$Name,
        [scriptblock]$ScriptBlock,
        [object[]]$ArgumentList
    )

    $job = Start-Job -Name $Name -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
    Write-Host "Started $Name as job $($job.Id)"
    return $job
}

function Test-MongoConnection {
    param([string]$Uri)

    if (-not (Get-Command mongosh -ErrorAction SilentlyContinue)) {
        return $false
    }

    & mongosh $Uri --quiet --eval "db.adminCommand({ ping: 1 }).ok" | Out-Null
    return $LASTEXITCODE -eq 0
}

$jobs = @()

if ($MongoUri -eq "mongodb://localhost:27017" -and -not (Test-MongoConnection -Uri $MongoUri)) {
    $jobs += Start-HelpdeskJob -Name "mongodb" -ArgumentList @($root) -ScriptBlock {
        param($root)
        & (Join-Path $root "scripts\run-mongodb.ps1")
    }

    Write-Host "Started portable MongoDB as job $($jobs[-1].Id)"
    Start-Sleep -Seconds 6
}

$jobs += Start-HelpdeskJob -Name "ticket-service" -ArgumentList @($root, $mvn, $MongoUri) -ScriptBlock {
    param($root, $mvn, $mongoUri)
    $env:SPRING_DATA_MONGODB_URI = if ($mongoUri.Contains("?")) {
        $parts = $mongoUri.Split("?", 2)
        "$($parts[0])/helpdesk_tickets`?$($parts[1])"
    } else {
        "$mongoUri/helpdesk_tickets"
    }
    & $mvn -f (Join-Path $root "ticket-service\pom.xml") spring-boot:run
}

$jobs += Start-HelpdeskJob -Name "user-service" -ArgumentList @($root, $mvn, $MongoUri) -ScriptBlock {
    param($root, $mvn, $mongoUri)
    $env:SPRING_DATA_MONGODB_URI = if ($mongoUri.Contains("?")) {
        $parts = $mongoUri.Split("?", 2)
        "$($parts[0])/helpdesk_users`?$($parts[1])"
    } else {
        "$mongoUri/helpdesk_users"
    }
    & $mvn -f (Join-Path $root "user-service\pom.xml") spring-boot:run
}

Start-Sleep -Seconds 8

$jobs += Start-HelpdeskJob -Name "api-gateway" -ArgumentList @($root, $mvn) -ScriptBlock {
    param($root, $mvn)
    $env:TICKET_SERVICE_URL = "http://localhost:8081"
    $env:USER_SERVICE_URL = "http://localhost:8082"
    & $mvn -f (Join-Path $root "api-gateway\pom.xml") spring-boot:run
}

$jobs += Start-HelpdeskJob -Name "frontend" -ArgumentList @($root) -ScriptBlock {
    param($root)
    $frontendPath = Join-Path $root "frontend"
    Push-Location $frontendPath
    try {
        if (-not (Test-Path -LiteralPath "node_modules")) {
            npm.cmd install
        }
        npm.cmd run dev
    }
    finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "Local Help Desk stack is starting."
Write-Host "Frontend:    http://localhost:5173"
Write-Host "Gateway API: http://localhost:8080"
Write-Host ""
Write-Host "Keep this PowerShell window open while using the app."
Write-Host "Press Ctrl+C to stop all local services."
Write-Host ""

try {
    while ($true) {
        Receive-Job -Job $jobs -Keep
        Start-Sleep -Seconds 2
    }
}
finally {
    Write-Host "Stopping local Help Desk services..."
    $jobs | Stop-Job -ErrorAction SilentlyContinue
    $jobs | Remove-Job -Force -ErrorAction SilentlyContinue
}
