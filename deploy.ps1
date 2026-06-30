# ========================================
#    ZZQ Hugo Blog Deploy Script
#    Target: https://zzq-1215.github.io/
# ========================================

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = "ZZQ Hugo Deploy"

function Write-Banner {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   ZZQ Hugo Blog Deploy" -ForegroundColor Cyan
    Write-Host "   Target: https://zzq-1215.github.io/" -ForegroundColor Cyan
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

    # ----- 1. Environment check -----
    Write-Host "[1/7] Checking environment..." -ForegroundColor Green

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Push-Location $scriptDir
    Write-Host "    Working dir: $scriptDir" -ForegroundColor Gray

    if (-not (Test-Path "hugo.toml")) {
        Write-Host "    [ERROR] hugo.toml not found in current directory" -ForegroundColor Red
        Write-Host "    Please run this script in D:\Hugo\dev\" -ForegroundColor Yellow
        Pop-Location
        Pause-Exit
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "    [ERROR] Git not found. Install from https://git-scm.com/download/win" -ForegroundColor Red
        Pause-Exit
    }
    # Find Node.js: check common paths
    $nodeExe = $null
    $nodePaths = @(
        "C:\Users\ASUS\.workbuddy\binaries\node\versions\22.22.2\node.exe",
        "$env:APPDATA\npm\node.exe",
        "C:\Program Files\nodejs\node.exe"
    )
    foreach ($p in $nodePaths) {
        if (Test-Path $p) {
            $nodeExe = $p
            $env:Path = "$(Split-Path $p);" + $env:Path
            break
        }
    }
    # Also try PATH-based lookup as fallback
    if (-not $nodeExe) {
        $cmd = Get-Command node -ErrorAction SilentlyContinue
        if ($cmd) { $nodeExe = $cmd.Source }
    }
    if (-not $nodeExe) {
        Write-Host "    [ERROR] Node.js not found. Install from https://nodejs.org/" -ForegroundColor Red
        Write-Host "    Or place node.exe at C:\Program Files\nodejs\" -ForegroundColor Yellow
        Pause-Exit
    }
    Write-Host "    Node.js: $nodeExe" -ForegroundColor Gray

    $hugoPath = "D:\Hugo\hugo-extended.exe"
    if (-not (Test-Path $hugoPath)) {
        Write-Host "    [ERROR] Hugo not found at: $hugoPath" -ForegroundColor Red
        Pause-Exit
    }
    Write-Host "    Environment OK" -ForegroundColor Green
    Write-Host ""

    # ----- 2. Clean old build -----
    Write-Host "[2/7] Cleaning old build artifacts..." -ForegroundColor Green
    foreach ($dir in @("public", "resources")) {
        if (Test-Path $dir) {
            Remove-Item -Recurse -Force $dir
            Write-Host "    Removed: $dir" -ForegroundColor Gray
        }
    }
    Write-Host ""

    # ----- 3. Install Node deps -----
    Write-Host "[3/7] Checking Node dependencies..." -ForegroundColor Green
    if (-not (Test-Path "node_modules")) {
        Write-Host "    First run, installing dependencies (1-2 min)..." -ForegroundColor Yellow
        & $nodeExe $env:APPDATA\npm\node_modules\npm\cli.js install --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) {
            # fallback: try npm from PATH
            npm install --no-audit --no-fund
        }
        Write-Host "    Dependencies installed" -ForegroundColor Gray
    } else {
        Write-Host "    Dependencies already installed" -ForegroundColor Gray
    }
    Write-Host ""

    # ----- 3.5 Pre-build CSS (PostCSS via Node.js) -----
    Write-Host "[3.5/7] Pre-building CSS with PostCSS..." -ForegroundColor Green
    & $nodeExe build-css.js
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    [ERROR] CSS pre-build failed" -ForegroundColor Red
        Pop-Location
        Pause-Exit
    }
    Write-Host "    CSS pre-build OK" -ForegroundColor Green
    Write-Host ""

    # ----- 4. Verify Hugo build -----
    Write-Host "[4/7] Verifying Hugo build..." -ForegroundColor Green
    $nodeBinPath = Join-Path $PWD "node_modules\.bin"
    if (Test-Path $nodeBinPath) {
        $env:Path = "$nodeBinPath;" + $env:Path
    }
    & $hugoPath --quiet --gc --minify
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    [ERROR] Hugo build failed, check errors above" -ForegroundColor Red
        Pop-Location
        Pause-Exit
    }
    Write-Host "    Hugo build OK" -ForegroundColor Green
    Write-Host ""

    # ----- 5. Configure Git -----
    Write-Host "[5/7] Configuring Git..." -ForegroundColor Green
    $userName = git config user.name
    $userEmail = git config user.email
    if ([string]::IsNullOrWhiteSpace($userName)) {
        $userName = Read-Host "    Enter Git username (for commit records)"
        git config user.name $userName
    } else {
        Write-Host "    Git user: $userName" -ForegroundColor Gray
    }
    if ([string]::IsNullOrWhiteSpace($userEmail)) {
        $userEmail = Read-Host "    Enter Git email"
        git config user.email $userEmail
    } else {
        Write-Host "    Git email: $userEmail" -ForegroundColor Gray
    }
    Write-Host ""

    # ----- 6. Commit changes -----
    Write-Host "[6/7] Staging and committing..." -ForegroundColor Green
    git add .

    $status = git status --porcelain
    if ([string]::IsNullOrWhiteSpace($status)) {
        Write-Host "    No changes to commit" -ForegroundColor Yellow
    } else {
        Write-Host "    Files to be committed:" -ForegroundColor Gray
        Write-Host $status -ForegroundColor DarkGray
        $commitMsg = Read-Host "    Enter commit message (or press Enter for default)"
        if ([string]::IsNullOrWhiteSpace($commitMsg)) {
            $commitMsg = "chore: update blog content"
        }
        git commit -m $commitMsg
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    [ERROR] Commit failed" -ForegroundColor Red
            Pop-Location
            Pause-Exit
        }
    }

    $currentBranch = git branch --show-current
    if ($currentBranch -ne "main") {
        git branch -M main
    }
    Write-Host ""

    # ----- 7. Push to GitHub -----
    Write-Host "[7/7] Pushing to GitHub..." -ForegroundColor Green

    $remoteUrl = $null
    try {
        $remoteUrl = git remote get-url origin 2>$null
    } catch {}

    if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
        Write-Host "    Remote not configured yet" -ForegroundColor Yellow
        Write-Host "    Create a repo first: https://github.com/new" -ForegroundColor Yellow
        Write-Host "    Suggested repo name: zzq-1215.github.io" -ForegroundColor Yellow
        Write-Host ""
        $repoUrl = Read-Host "    Enter repo HTTPS URL"
        if ([string]::IsNullOrWhiteSpace($repoUrl)) {
            Write-Host "    [ERROR] Repo URL cannot be empty" -ForegroundColor Red
            Pop-Location
            Pause-Exit
        }
        git remote add origin $repoUrl
        $remoteUrl = $repoUrl
    }
    Write-Host "    Remote: $remoteUrl" -ForegroundColor Gray

    git push -u origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "    [ERROR] Push failed. Possible reasons:" -ForegroundColor Red
        Write-Host "      1. GitHub repo not created yet" -ForegroundColor Yellow
        Write-Host "      2. No push permission (need SSH key or PAT)" -ForegroundColor Yellow
        Write-Host "      3. Network issue" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "    See error details above" -ForegroundColor Yellow
        Pop-Location
        Pause-Exit
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   Push successful!" -ForegroundColor Green
    Write-Host "   Wait 1-2 min, then visit:" -ForegroundColor Green
    Write-Host "   https://zzq-1215.github.io/" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Enable GitHub Pages:" -ForegroundColor Yellow
    Write-Host "   Settings -> Pages -> Source: GitHub Actions" -ForegroundColor Yellow
    Write-Host ""

    Pop-Location
}
catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "   ERROR:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    Pause-Exit
}

if ([Environment]::UserInteractive) {
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
