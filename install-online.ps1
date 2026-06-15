# Sakura Package Manager - Remote Installer
# Run with: powershell -NoProfile -Command "irm https://raw.githubusercontent.com/838288383838383/sakura-package-manager/main/install-online.ps1 | iex"

$ErrorActionPreference = "Stop"

# Bypass execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Host ""
Write-Host "    S A K U R A   I N S T A L L E R" -ForegroundColor Magenta
Write-Host "    ==================================" -ForegroundColor DarkGray
Write-Host ""

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "  [ERR] PowerShell 5.0 or higher required." -ForegroundColor Red
    exit 1
}

$InstallDir = "$env:USERPROFILE\.sakura"
$RepoUrl = "https://github.com/838288383838383/sakura-package-manager/archive/refs/heads/main.zip"
$ZipPath = "$env:TEMP\sakura-main.zip"
$isInstalled = Test-Path "$InstallDir\bin\sakura.ps1"

function Ensure-ShimsDir {
    param([string]$Dir)
    $shimsDir = "$Dir\shims"
    if (-not (Test-Path $shimsDir)) {
        New-Item -ItemType Directory -Path $shimsDir -Force | Out-Null
    }
}

function Update-ByGit {
    param([string]$Dir)
    Write-Host "  Updating via git..." -ForegroundColor Cyan
    $gitCheck = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCheck) {
        Write-Host "  [ERR] Git not found on this system." -ForegroundColor Red
        return $false
    }
    try {
        $ProgressPreference = 'SilentlyContinue'
        if (Test-Path "$Dir\.git") {
            Push-Location $Dir
            git pull origin main 2>&1 | Out-Null
            Pop-Location
        } else {
            # Must remove existing dir before cloning
            Write-Host "  Removing old install..." -ForegroundColor DarkGray
            Remove-Item -Recurse -Force $Dir -ErrorAction Stop
            git clone https://github.com/838288383838383/sakura-package-manager.git $Dir 2>&1 | Out-Null
        }
        Write-Host "  Updated via git!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [ERR] Git failed: $_" -ForegroundColor Red
        return $false
    }
}

function Update-ByDownload {
    param([string]$Dir, [string]$Url, [string]$Zip)
    Write-Host "  Downloading update..." -ForegroundColor Cyan
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Zip -UseBasicParsing
    } catch {
        Write-Host "  [ERR] Download failed: $_" -ForegroundColor Red
        return $false
    }
    Write-Host "  Extracting..." -ForegroundColor Cyan
    Expand-Archive -Path $Zip -DestinationPath $Dir -Force
    $extractedDir = Join-Path $Dir "sakura-package-manager-main"
    if (Test-Path $extractedDir) {
        Copy-Item -Path "$extractedDir\*" -Destination $Dir -Recurse -Force
        Remove-Item -Path $extractedDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -Path $Zip -Force -ErrorAction SilentlyContinue
    Write-Host "  Updated via download!" -ForegroundColor Green
    return $true
}

function Repair-Shims {
    param([string]$Dir)
    Ensure-ShimsDir -Dir $Dir
    Write-Host "  Repairing shims..." -ForegroundColor Cyan
    $sakuraCmd = "$Dir\bin\sakura.ps1"
    $sakuraShim = "$Dir\shims\sakura.cmd"
    $sakContent = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$sakuraCmd" %*
"@
    Set-Content -Path $sakuraShim -Value $sakContent -Encoding ASCII
    Copy-Item -Path $sakuraShim -Destination "$Dir\shims\sak.cmd" -Force
    Write-Host "  Shims repaired with -NoProfile!" -ForegroundColor Green
}

# If already installed, show update menu
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
        if ($choice -ne "1" -and $choice -ne "2") {
            Write-Host "  Please enter 1 or 2" -ForegroundColor Yellow
        }
    }
    Write-Host ""

    $success = $false

    if ($choice -eq "1") {
        $success = Update-ByGit -Dir $InstallDir
        if (-not $success) {
            Write-Host "  Falling back to download..." -ForegroundColor Yellow
            $success = Update-ByDownload -Dir $InstallDir -Url $RepoUrl -Zip $ZipPath
        }
    } else {
        $success = Update-ByDownload -Dir $InstallDir -Url $RepoUrl -Zip $ZipPath
    }

    # Always repair shims
    Repair-Shims -Dir $InstallDir

    if ($success) {
        Write-Host ""
        Write-Host "  Sakura updated successfully!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "  Update failed. Try reinstalling from scratch." -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "  Closing in 3 seconds..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 3
    exit 0
}

# ===== FRESH INSTALL =====

Write-Host "  Fresh install - downloading Sakura..." -ForegroundColor Cyan
Write-Host ""

# Create directories
$dirs = @($InstallDir, "$InstallDir\apps", "$InstallDir\shims", "$InstallDir\buckets", "$InstallDir\cache", "$InstallDir\persist", "$InstallDir\data", "$InstallDir\pet")
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

# Download
$ProgressPreference = 'SilentlyContinue'
try {
    Invoke-WebRequest -Uri $RepoUrl -OutFile $ZipPath -UseBasicParsing
} catch {
    Write-Host "  [ERR] Download failed: $_" -ForegroundColor Red
    exit 1
}

# Extract
Write-Host "  Extracting..." -ForegroundColor Cyan
Expand-Archive -Path $ZipPath -DestinationPath $InstallDir -Force
$extractedDir = Join-Path $InstallDir "sakura-package-manager-main"
if (Test-Path $extractedDir) {
    Copy-Item -Path "$extractedDir\*" -Destination $InstallDir -Recurse -Force
    Remove-Item -Path $extractedDir -Recurse -Force -ErrorAction SilentlyContinue
}
Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue

# Create shims
Ensure-ShimsDir -Dir $InstallDir
$sakuraCmd = "$InstallDir\bin\sakura.ps1"
$sakuraShim = "$InstallDir\shims\sakura.cmd"
$sakContent = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$sakuraCmd" %*
"@
Set-Content -Path $sakuraShim -Value $sakContent -Encoding ASCII
Copy-Item -Path $sakuraShim -Destination "$InstallDir\shims\sak.cmd" -Force

# Create config
$configPath = "$InstallDir\config.json"
if (-not (Test-Path $configPath)) {
    $config = @{
        version = "2.0.1"
        default_bucket = "sakura-main"
        use_isolated_path = $true
        proxy = ""
        last_update = (Get-Date).ToString("o")
    } | ConvertTo-Json -Depth 5
    Set-Content -Path $configPath -Value $config -Encoding UTF8
}

# Create pet data
$petPath = "$InstallDir\pet\pet.json"
if (-not (Test-Path $petPath)) {
    $petData = @{
        name = "Sakura-chan"
        species = "sakura-spirit"
        level = 1
        experience = 0
        exp_to_next = 100
        mood = "happy"
        hunger = 50
        energy = 100
        happiness = 80
        cleanliness = 70
        health = 100
        stage = "baby"
        evolution_count = 0
        created = (Get-Date).ToString("o")
        last_fed = (Get-Date).ToString("o")
        last_played = (Get-Date).ToString("o")
        last_interaction = (Get-Date).ToString("o")
        total_installs = 0
        total_updates = 0
        total_searches = 0
        achievements = @()
        items = @()
    } | ConvertTo-Json -Depth 5
    Set-Content -Path $petPath -Value $petData -Encoding UTF8
}

# Add to PATH
Write-Host "  Configuring PATH..." -ForegroundColor Cyan
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$InstallDir\shims*") {
    [Environment]::SetEnvironmentVariable("PATH", "$InstallDir\shims;$currentPath", "User")
}

Write-Host ""
Write-Host "  Sakura v2.0.1 installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "  Usage:" -ForegroundColor Yellow
Write-Host "    Open a NEW terminal, then:" -ForegroundColor White
Write-Host "    sak help          Show help" -ForegroundColor White
Write-Host "    sak pet           Meet your companion!" -ForegroundColor White
Write-Host "    sak install git   Install an app" -ForegroundColor White
Write-Host ""
Write-Host "  Your pet Sakura-chan is waiting!" -ForegroundColor Magenta
Write-Host "  Run 'sak pet' to say hello!" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Closing in 3 seconds..." -ForegroundColor DarkGray
Start-Sleep -Seconds 3
exit
