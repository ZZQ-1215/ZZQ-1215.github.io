# ========================================
#    ZZQ Hugo Blog Local Preview
#    Visit: http://localhost:1313/
# ========================================

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = "ZZQ Hugo Preview"

function Write-Banner {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   ZZQ Hugo Blog - Local Preview" -ForegroundColor Cyan
    Write-Host "   Visit: http://localhost:1313/" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Pause-Exit {
    if ([Environment]::UserInteractive) {
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit 1
}

try {
    Write-Banner

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Push-Location $scriptDir
    Write-Host "Working dir: $scriptDir" -ForegroundColor Gray
    Write-Host ""

    # Find Node.js and add to PATH for npm
    $nodePaths = @(
        "C:\Users\ASUS\.workbuddy\binaries\node\versions\22.22.2\node.exe",
        "$env:APPDATA\npm\node.exe",
        "C:\Program Files\nodejs\node.exe"
    )
    foreach ($p in $nodePaths) {
        if (Test-Path $p) {
            $env:Path = "$(Split-Path $p);" + $env:Path
            Write-Host "Node.js found: $p" -ForegroundColor Gray
            break
        }
    }

    # Check node_modules
    if (-not (Test-Path "node_modules")) {
        Write-Host "[First run] Installing PostCSS dependencies (1-2 min)..." -ForegroundColor Yellow
        & $nodeExe $env:APPDATA\npm\node_modules\npm\cli.js install --no-audit --no-fund 2>$null
        if ($LASTEXITCODE -ne 0) { npm install --no-audit --no-fund }
        Write-Host "Dependencies installed" -ForegroundColor Gray
        Write-Host ""
    }

    # Pre-build CSS (PostCSS via Node.js) - call build-css.js directly
    Write-Host "[Pre-build] Compiling CSS with PostCSS..." -ForegroundColor Green
    & $nodeExe build-css.js
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    [ERROR] CSS pre-build failed" -ForegroundColor Red
        Pop-Location
        Pause-Exit
    }
    Write-Host "    CSS ready" -ForegroundColor Gray
    Write-Host ""

    # Add node_modules/.bin to PATH so Hugo can find postcss
    $nodeBinPath = Join-Path $PWD "node_modules\.bin"
    if (Test-Path $nodeBinPath) {
        $env:Path = "$nodeBinPath;" + $env:Path
    }

    $hugoPath = "D:\Hugo\hugo.exe"
    if (-not (Test-Path $hugoPath)) {
        Write-Host "[ERROR] Hugo not found at: $hugoPath" -ForegroundColor Red
        Pause-Exit
    }

    Write-Host "Starting Hugo dev server..." -ForegroundColor Green
    Write-Host "  - URL: http://localhost:1313/" -ForegroundColor Cyan
    Write-Host "  - Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""

    & $hugoPath server -D --bind 0.0.0.0 --port 1313

    Pop-Location
}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Pause-Exit
}
