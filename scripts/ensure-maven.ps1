param(
    [string]$MavenVersion = "3.9.9"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$toolsDir = Join-Path $root ".tools"
$downloadsDir = Join-Path $toolsDir "downloads"
$mavenDir = Join-Path $toolsDir "apache-maven-$MavenVersion"
$mvnCmd = Join-Path $mavenDir "bin\mvn.cmd"

if (Test-Path -LiteralPath $mvnCmd) {
    Write-Output $mvnCmd
    exit 0
}

New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null

$zipPath = Join-Path $downloadsDir "apache-maven-$MavenVersion-bin.zip"
$downloadUrls = @(
    "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$MavenVersion/apache-maven-$MavenVersion-bin.zip",
    "https://dlcdn.apache.org/maven/maven-3/$MavenVersion/binaries/apache-maven-$MavenVersion-bin.zip",
    "https://archive.apache.org/dist/maven/maven-3/$MavenVersion/binaries/apache-maven-$MavenVersion-bin.zip"
)

if (-not (Test-Path -LiteralPath $zipPath)) {
    Write-Host "Downloading Apache Maven $MavenVersion..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $downloaded = $false
    foreach ($downloadUrl in $downloadUrls) {
        try {
            if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
                & curl.exe -L --fail --output $zipPath $downloadUrl
                if ($LASTEXITCODE -ne 0) {
                    throw "curl.exe exited with code $LASTEXITCODE"
                }
            }
            else {
                Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
            }

            $downloaded = $true
            break
        }
        catch {
            if (Test-Path -LiteralPath $zipPath) {
                Remove-Item -LiteralPath $zipPath -Force
            }
            Write-Host "Download failed from $downloadUrl"
        }
    }

    if (-not $downloaded) {
        throw "Could not download Apache Maven $MavenVersion. Check your internet connection or download the zip manually into $zipPath"
    }
}

Write-Host "Extracting Apache Maven $MavenVersion..."
Expand-Archive -LiteralPath $zipPath -DestinationPath $toolsDir -Force

if (-not (Test-Path -LiteralPath $mvnCmd)) {
    throw "Maven download finished, but mvn.cmd was not found at $mvnCmd"
}

Write-Output $mvnCmd
