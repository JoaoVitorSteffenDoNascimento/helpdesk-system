param(
    [string]$MongoVersion = "7.0.15"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$toolsDir = Join-Path $root ".tools"
$downloadsDir = Join-Path $toolsDir "downloads"
$possibleMongoDirs = @(
    (Join-Path $toolsDir "mongodb-windows-x86_64-$MongoVersion"),
    (Join-Path $toolsDir "mongodb-win32-x86_64-windows-$MongoVersion")
)
$mongodExe = $possibleMongoDirs |
    ForEach-Object { Join-Path $_ "bin\mongod.exe" } |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1

if ($mongodExe) {
    Write-Output $mongodExe
    exit 0
}

New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null

$zipPath = Join-Path $downloadsDir "mongodb-windows-x86_64-$MongoVersion.zip"
$downloadUrl = "https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-$MongoVersion.zip"

if (-not (Test-Path -LiteralPath $zipPath)) {
    Write-Host "Downloading MongoDB Server $MongoVersion. This file is large, so it can take a few minutes..."
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -L --fail --output $zipPath $downloadUrl
        if ($LASTEXITCODE -ne 0) {
            if (Test-Path -LiteralPath $zipPath) {
                Remove-Item -LiteralPath $zipPath -Force
            }
            throw "curl.exe failed to download MongoDB Server."
        }
    }
    else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
    }
}

Write-Host "Extracting MongoDB Server $MongoVersion..."
Expand-Archive -LiteralPath $zipPath -DestinationPath $toolsDir -Force

$mongodExe = $possibleMongoDirs |
    ForEach-Object { Join-Path $_ "bin\mongod.exe" } |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1

if (-not $mongodExe) {
    throw "MongoDB download finished, but mongod.exe was not found under $toolsDir"
}

Write-Output $mongodExe
