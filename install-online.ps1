# Sakura Package Manager - Remote Installer
# Run with: powershell -NoProfile -Command "irm https://raw.githubusercontent.com/838288383838383/sakura-package-manager/main/install-online.ps1 | iex"

$ErrorActionPreference = "Stop"

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Host ""
Write-Host "    S A K U R A   I N S T A L L E R" -ForegroundColor Magenta
Write-Host "    ==================================" -ForegroundColor DarkGray
Write-Host ""

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "  [ERR] PowerShell 5.0 or higher required." -ForegroundColor Red
    exit 1
}

$InstallDir = "$env:USERPROFILE\.sakura"
$RepoUrl = "https://github.com/838288383838383/sakura-package-manager/archive/refs/heads/main.zip"
$ZipPath = "$env:TEMP\sakura-main.zip"
$isInstalled = Test-Path "$InstallDir\bin\sakura.ps1"

function Write-Shims {
    param([string]$Dir)
    $shimsDir = Join-Path $Dir "shims"
    if (-not (Test-Path $shimsDir)) {
        New-Item -ItemType Directory -Path $shimsDir -Force | Out-Null
    }
    $sakuraCmd = Join-Path $Dir "bin\sakura.ps1"
    $sakShim = Join-Path $shimsDir "sak.cmd"
    $sakuraShim = Join-Path $shimsDir "sakura.cmd"
    $content = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"$sakuraCmd`" %*"
    [System.IO.File]::WriteAllText($sakuraShim, $content, [System.Text.Encoding]::ASCII)
    Copy-Item -Path $sakuraShim -Destination $sakShim -Force
    Write-Host "  Shims created with -NoProfile!" -ForegroundColor Green
}

function Do-GitUpdate {
    param([string]$Dir)
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        Write-Host "  Git not found, skipping." -ForegroundColor Yellow
        return $false
    }
    Write-Host "  Updating via git..." -ForegroundColor Cyan
    try {
        if (Test-Path "$Dir\.git") {
            Push-Location $Dir
            git pull origin main 2>&1
            Pop-Location
        } else {
            if (Test-Path $Dir) { Remove-Item -Recurse -Force $Dir -ErrorAction Stop }
            git clone https://github.com/838288383838383/sakura-package-manager.git $Dir 2>&1
        }
        Write-Host "  Git update done!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  Git failed: $_" -ForegroundColor Red
        return $false
    }
}

function Do-DownloadUpdate {
    param([string]$Dir)
    Write-Host "  Downloading..." -ForegroundColor Cyan
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $RepoUrl -OutFile $ZipPath -UseBasicParsing
    } catch {
        Write-Host "  Download failed: $_" -ForegroundColor Red
        return $false
    }
    Write-Host "  Extracting..." -ForegroundColor Cyan
    Expand-Archive -Path $ZipPath -DestinationPath $Dir -Force
    $src = Join-Path $Dir "sakura-package-manager-main"
    if (Test-Path $src) {
        Copy-Item -Path "$src\*" -Destination $Dir -Recurse -Force
        Remove-Item -Path $src -Recurse -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue
    Write-Host "  Download update done!" -ForegroundColor Green
    return $true
}

# ===== UPDATE PATH =====
if ($isInstalled) {
    Write-Host "  Sakura is already installed!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  How would you like to update?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    [1] Git pull   (faster, requires git)" -ForegroundColor White
    Write-Host "    [2] Download   (always works)" -ForegroundColor White
    Write-Host ""

    $choice = ""
    while ($choice -ne "1" -and $choice -ne "2") {
        $choice = Read-Host "  Enter 1 or 2"
    }
    Write-Host ""

    $ok = $false
    if ($choice -eq "1") {
        $ok = Do-GitUpdate -Dir $InstallDir
        if (-not $ok) {
            Write-Host "  Falling back to download..." -ForegroundColor Yellow
            $ok = Do-DownloadUpdate -Dir $InstallDir
        }
    } else {
        $ok = Do-DownloadUpdate -Dir $InstallDir
    }

    Write-Shims -Dir $InstallDir

    if ($ok) {
        Write-Host ""
        Write-Host "  Sakura updated!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "  Update failed." -ForegroundColor Red
    }
    Write-Host ""
    Start-Sleep -Seconds 3
    exit 0
}

# ===== FRESH INSTALL =====
Write-Host "  Fresh install..." -ForegroundColor Cyan
Write-Host ""

$dirs = @($InstallDir, "$InstallDir\apps", "$InstallDir\buckets", "$InstallDir\cache", "$InstallDir\persist", "$InstallDir\data", "$InstallDir\pet")
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$ProgressPreference = 'SilentlyContinue'
try {
    Invoke-WebRequest -Uri $RepoUrl -OutFile $ZipPath -UseBasicParsing
} catch {
    Write-Host "  [ERR] Download failed: $_" -ForegroundColor Red
    exit 1
}

Expand-Archive -Path $ZipPath -DestinationPath $InstallDir -Force
$src = Join-Path $InstallDir "sakura-package-manager-main"
if (Test-Path $src) {
    Copy-Item -Path "$src\*" -Destination $InstallDir -Recurse -Force
    Remove-Item -Path $src -Recurse -Force -ErrorAction SilentlyContinue
}
Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue

Write-Shims -Dir $InstallDir

$configPath = "$InstallDir\config.json"
if (-not (Test-Path $configPath)) {
    @{ version = "2.0.1"; default_bucket = "sakura-main"; use_isolated_path = $true; proxy = ""; last_update = (Get-Date).ToString("o") } | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8
}

$petPath = "$InstallDir\pet\pet.json"
if (-not (Test-Path $petPath)) {
    @{ name = "Sakura-chan"; species = "sakura-spirit"; level = 1; experience = 0; exp_to_next = 100; mood = "happy"; hunger = 50; energy = 100; happiness = 80; cleanliness = 70; health = 100; stage = "baby"; evolution_count = 0; created = (Get-Date).ToString("o"); last_fed = (Get-Date).ToString("o"); last_played = (Get-Date).ToString("o"); last_interaction = (Get-Date).ToString("o"); total_installs = 0; total_updates = 0; total_searches = 0; achievements = @(); items = @() } | ConvertTo-Json -Depth 5 | Set-Content -Path $petPath -Encoding UTF8
}

$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$InstallDir\shims*") {
    [Environment]::SetEnvironmentVariable("PATH", "$InstallDir\shims;$currentPath", "User")
}

Write-Host ""
Write-Host "  Sakura v2.0.1 installed!" -ForegroundColor Green
Write-Host ""
Write-Host "  Usage:" -ForegroundColor Yellow
Write-Host "    sak help          Show help" -ForegroundColor White
Write-Host "    sak pet           Meet your companion!" -ForegroundColor White
Write-Host "    sak install git   Install an app" -ForegroundColor White
Write-Host ""
Start-Sleep -Seconds 3
exit
