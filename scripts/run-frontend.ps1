$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$frontendPath = Join-Path $root "frontend"

if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
    throw "npm.cmd was not found. Install Node.js first, then run this script again."
}

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
