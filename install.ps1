# Sakura Installer
# Run this to install Sakura Package Manager on your system

param(
    [string]$InstallDir = "$env:USERPROFILE\.sakura"
)

$ErrorActionPreference = "Stop"
$SakuraVersion = "0.1.0"

Write-Host ""
Write-Host "    🌸 S A K U R A   I N S T A L L E R 🌸" -ForegroundColor Magenta
Write-Host "    ════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "  [ERR] PowerShell 5.0 or higher required." -ForegroundColor Red
    exit 1
}

# Create directories
Write-Host "  Creating directories..." -ForegroundColor Cyan
$dirs = @(
    $InstallDir,
    "$InstallDir\apps",
    "$InstallDir\shims",
    "$InstallDir\buckets",
    "$InstallDir\cache",
    "$InstallDir\persist",
    "$InstallDir\data",
    "$InstallDir\pet"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "    Created: $dir" -ForegroundColor DarkGray
    }
}

# Copy Sakura files
Write-Host "`n  Installing Sakura files..." -ForegroundColor Cyan
$SakuraSource = Split-Path -Parent $MyInvocation.MyCommand.Path

# Copy lib files
Copy-Item -Path "$SakuraSource\lib\*" -Destination "$InstallDir\lib" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$SakuraSource\bin\*" -Destination "$InstallDir\bin" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$SakuraSource\modules\*" -Destination "$InstallDir\modules" -Recurse -Force -ErrorAction SilentlyContinue

# Create default bucket
if (-not (Test-Path "$InstallDir\buckets\sakura-main")) {
    New-Item -ItemType Directory -Path "$InstallDir\buckets\sakura-main" -Force | Out-Null
}

# Copy bucket manifests
if (Test-Path "$SakuraSource\buckets\sakura-main\bucket") {
    Copy-Item -Path "$SakuraSource\buckets\sakura-main\bucket\*" -Destination "$InstallDir\buckets\sakura-main\bucket" -Force -ErrorAction SilentlyContinue
}

# Create default config
$configPath = "$InstallDir\config.json"
if (-not (Test-Path $configPath)) {
    $config = @{
        version = $SakuraVersion
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

# Create shim directory and add to PATH
Write-Host "`n  Configuring PATH..." -ForegroundColor Cyan
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$InstallDir\shims*") {
    [Environment]::SetEnvironmentVariable("PATH", "$InstallDir\shims;$currentPath", "User")
    Write-Host "    Added shims to PATH" -ForegroundColor DarkGray
}

# Create sakura command script
$sakuraCmd = "$InstallDir\bin\sakura.ps1"
$sakuraShim = "$InstallDir\shims\sakura.cmd"
$shimContent = @"
@echo off
powershell -ExecutionPolicy Bypass -File "$sakuraCmd" %*
"@
Set-Content -Path $sakuraShim -Value $shimContent -Encoding ASCII

Write-Host "`n  ✅ Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Usage:" -ForegroundColor Yellow
Write-Host "    sakura help          Show help" -ForegroundColor White
Write-Host "    sakura install <app> Install an app" -ForegroundColor White
Write-Host "    sakura pet           Meet your new companion!" -ForegroundColor White
Write-Host ""
Write-Host "  🌸 Your pet Sakura-chan is waiting to meet you!" -ForegroundColor Magenta
Write-Host "     Run 'sakura pet' to say hello!" -ForegroundColor Magenta
Write-Host ""
