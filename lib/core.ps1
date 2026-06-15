# Sakura Core Library
# Core functions and initialization

$Script:SakuraRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Script:SakuraVersion = "0.1.0"

function Initialize-Sakura {
    $Script:SakuraHome = Join-Path $env:USERPROFILE ".sakura"
    $Script:SakuraApps = Join-Path $Script:SakuraHome "apps"
    $Script:SakuraShims = Join-Path $Script:SakuraHome "shims"
    $Script:SakuraBuckets = Join-Path $Script:SakuraHome "buckets"
    $Script:SakuraCache = Join-Path $Script:SakuraHome "cache"
    $Script:SakuraPersist = Join-Path $Script:SakuraHome "persist"
    $Script:SakuraData = Join-Path $Script:SakuraHome "data"
    $Script:SakuraPetData = Join-Path $Script:SakuraHome "pet"

    $dirs = @(
        $Script:SakuraHome,
        $Script:SakuraApps,
        $Script:SakuraShims,
        $Script:SakuraBuckets,
        $Script:SakuraCache,
        $Script:SakuraPersist,
        $Script:SakuraData,
        $Script:SakuraPetData
    )

    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    # Initialize config if not exists
    $configPath = Join-Path $Script:SakuraHome "config.json"
    if (-not (Test-Path $configPath)) {
        $defaultConfig = @{
            version = $Script:SakuraVersion
            default_bucket = "sakura-main"
            use_isolated_path = $true
            proxy = ""
            last_update = (Get-Date).ToString("o")
        } | ConvertTo-Json -Depth 5
        Set-Content -Path $configPath -Value $defaultConfig -Encoding UTF8
    }

    # Initialize pet data if not exists
    $petFile = Join-Path $Script:SakuraPetData "pet.json"
    if (-not (Test-Path $petFile)) {
        $defaultPet = @{
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
        Set-Content -Path $petFile -Value $defaultPet -Encoding UTF8
    }

    # Add shims dir to PATH if not already there
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$Script:SakuraShims*") {
        [Environment]::SetEnvironmentVariable("PATH", "$Script:SakuraShims;$currentPath", "User")
    }

    # Register default bucket if none exist
    $bucketDir = Join-Path $Script:SakuraBuckets "sakura-main"
    if (-not (Test-Path $bucketDir)) {
        New-Item -ItemType Directory -Path $bucketDir -Force | Out-Null
    }
}

function Get-SakuraHome {
    return $Script:SakuraHome
}

function Write-SakuraLogo {
    $logo = @"
    @echo off
    chcp 65001 >nul 2>&1
    
    echo.
    echo     ███████╗██╗  ██╗ █████╗ ██████╗  █████╗ ██╗   ██╗
    echo     ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝
    echo     ███████╗███████║███████║██████╔╝███████║ ╚████╔╝ 
    echo     ╚════██║██╔══██║██╔══██║██╔══██╗██╔══██║  ╚██╔╝  
    echo     ███████║██║  ██║██║  ██║██████╔╝██║  ██║   ██║   
    echo     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   
    echo.
    echo     🌸 Blossom Edition v$Script:SakuraVersion 🌸
    echo.
"@
    Write-Host $logo -ForegroundColor Magenta
}

function Write-SakuraSuccess {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-SakuraError {
    param([string]$Message)
    Write-Host "  [ERR] $Message" -ForegroundColor Red
}

function Write-SakuraInfo {
    param([string]$Message)
    Write-Host "  [i] $Message" -ForegroundColor Cyan
}

function Write-SakuraWarning {
    param([string]$Message)
    Write-Host "  [!] $Message" -ForegroundColor Yellow
}

function Write-SakuraProgress {
    param([string]$Message)
    Write-Host "  [>] $Message" -ForegroundColor Magenta
}
