# 🌸 Sakura Package Manager - Remote Installer
# Run with: irm https://raw.githubusercontent.com/838288383838383/sakura-package-manager/main/install-online.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "    🌸 S A K U R A   I N S T A L L E R 🌸" -ForegroundColor Magenta
Write-Host "    ════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""

# Bypass execution policy (like Scoop)
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -ne "RemoteSigned" -and $currentPolicy -ne "Unrestricted" -and $currentPolicy -ne "Bypass") {
    Write-Host "  Setting execution policy..." -ForegroundColor Cyan
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    } catch {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    }
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "  [ERR] PowerShell 5.0 or higher required." -ForegroundColor Red
    exit 1
}

$InstallDir = "$env:USERPROFILE\.sakura"
$RepoUrl = "https://github.com/838288383838383/sakura-package-manager/archive/refs/heads/main.zip"
$ZipPath = "$env:TEMP\sakura-main.zip"

# Create directories
Write-Host "  Creating directories..." -ForegroundColor Cyan
$dirs = @($InstallDir, "$InstallDir\apps", "$InstallDir\shims", "$InstallDir\buckets", "$InstallDir\cache", "$InstallDir\persist", "$InstallDir\data", "$InstallDir\pet")
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

# Download
Write-Host "  Downloading Sakura v2.0.1..." -ForegroundColor Cyan
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

# Move files from extracted folder
$extractedDir = Join-Path $InstallDir "sakura-package-manager-main"
if (Test-Path $extractedDir) {
    # Copy all files
    Copy-Item -Path "$extractedDir\*" -Destination $InstallDir -Recurse -Force
    Remove-Item -Path $extractedDir -Recurse -Force -ErrorAction SilentlyContinue
}
Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue

# Create shims
Write-Host "  Creating shims..." -ForegroundColor Cyan
$sakuraCmd = "$InstallDir\bin\sakura.ps1"
$sakuraShim = "$InstallDir\shims\sakura.cmd"
$sakContent = @"
@echo off
powershell -ExecutionPolicy Bypass -File "$sakuraCmd" %*
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
Write-Host "  ✅ Sakura v2.0.1 installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "  Usage:" -ForegroundColor Yellow
Write-Host "    Open a NEW terminal, then:" -ForegroundColor White
Write-Host "    sak help          Show help" -ForegroundColor White
Write-Host "    sak pet           Meet your companion!" -ForegroundColor White
Write-Host "    sak install git   Install an app" -ForegroundColor White
Write-Host ""
Write-Host "  🌸 Your pet Sakura-chan is waiting!" -ForegroundColor Magenta
Write-Host "     Run 'sak pet' to say hello!" -ForegroundColor Magenta
Write-Host ""
