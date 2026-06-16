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

$HomeDir = "$env:USERPROFILE\.sakura"
$RepoUrl = "https://github.com/838288383838383/sakura-package-manager/archive/refs/heads/main.zip"
$TmpZip = "$env:TEMP\sakura_installer.zip"
$TmpExtract = "$env:TEMP\sakura_extract"
$isInstalled = Test-Path "$HomeDir\bin\sakura.ps1"

function Install-Shims {
    param([string]$Target)
    $shimsDir = "$Target\shims"
    if (-not (Test-Path $shimsDir)) {
        cmd /c mkdir "$shimsDir" 2>&1 | Out-Null
    }
    $ps1 = "$Target\bin\sakura.ps1"
    $bat = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0..\bin\sakura.ps1`" %*"
    [System.IO.File]::WriteAllText("$shimsDir\sakura.cmd", $bat, [System.Text.Encoding]::ASCII)
    [System.IO.File]::WriteAllText("$shimsDir\sak.cmd", $bat, [System.Text.Encoding]::ASCII)
    Write-Host "  Shims created" -ForegroundColor Green
}

function Download-Repo {
    # Clean temp
    if (Test-Path $TmpExtract) { Remove-Item -Recurse -Force $TmpExtract }
    if (Test-Path $TmpZip) { Remove-Item -Force $TmpZip }

    Write-Host "  Downloading..." -ForegroundColor Cyan
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $RepoUrl -OutFile $TmpZip -UseBasicParsing

    Write-Host "  Extracting..." -ForegroundColor Cyan
    Expand-Archive -Path $TmpZip -DestinationPath $TmpExtract -Force
    Remove-Item -Force $TmpZip -ErrorAction SilentlyContinue

    $src = "$TmpExtract\sakura-package-manager-main"
    if (-not (Test-Path $src)) {
        Write-Host "  [ERR] Bad zip structure" -ForegroundColor Red
        return $false
    }
    return $true
}

function Copy-ToTarget {
    param([string]$Target)
    $src = "$TmpExtract\sakura-package-manager-main"

    # Ensure target dirs exist
    foreach ($sub in @("bin", "lib", "modules", "buckets", "apps", "shims", "cache", "persist", "data", "pet")) {
        $p = "$Target\$sub"
        if (-not (Test-Path $p)) { cmd /c mkdir "$p" 2>&1 | Out-Null }
    }

    # Copy files
    Copy-Item -Path "$src\bin\*" -Destination "$Target\bin" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$src\lib\*" -Destination "$Target\lib" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$src\modules\*" -Destination "$Target\modules" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$src\install-online.ps1" -Destination "$Target" -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$src\install.ps1" -Destination "$Target" -Force -ErrorAction SilentlyContinue

    # Copy bucket manifests
    if (Test-Path "$src\buckets\sakura-main\bucket") {
        if (-not (Test-Path "$Target\buckets\sakura-main\bucket")) { cmd /c mkdir "$Target\buckets\sakura-main\bucket" 2>&1 | Out-Null }
        Copy-Item -Path "$src\buckets\sakura-main\bucket\*" -Destination "$Target\buckets\sakura-main\bucket" -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path "$src\buckets\langs\bucket") {
        if (-not (Test-Path "$Target\buckets\langs\bucket")) { cmd /c mkdir "$Target\buckets\langs\bucket" 2>&1 | Out-Null }
        Copy-Item -Path "$src\buckets\langs\bucket\*" -Destination "$Target\buckets\langs\bucket" -Force -ErrorAction SilentlyContinue
    }

    # Cleanup temp
    Remove-Item -Recurse -Force $TmpExtract -ErrorAction SilentlyContinue
}

# ===== UPDATE =====
if ($isInstalled) {
    Write-Host "  Sakura is already installed!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  How would you like to update?" -ForegroundColor Yellow
    Write-Host "    [1] Git pull" -ForegroundColor White
    Write-Host "    [2] Download ZIP" -ForegroundColor White
    Write-Host ""
    $ch = ""
    while ($ch -ne "1" -and $ch -ne "2") { $ch = Read-Host "  Enter 1 or 2" }

    $ok = $false

    if ($ch -eq "1") {
        $git = Get-Command git -ErrorAction SilentlyContinue
        if ($git) {
            Write-Host "  Updating via git..." -ForegroundColor Cyan
            try {
                Push-Location $HomeDir
                git pull origin main 2>&1 | Out-Null
                Pop-Location
                $ok = $true
                Write-Host "  Git update done!" -ForegroundColor Green
            } catch {
                Write-Host "  Git failed, trying download..." -ForegroundColor Yellow
                Pop-Location -ErrorAction SilentlyContinue
            }
        } else {
            Write-Host "  Git not found, using download..." -ForegroundColor Yellow
        }
    }

    if (-not $ok) {
        $ok = Download-Repo
        if ($ok) { Copy-ToTarget -Target $HomeDir }
    }

    Install-Shims -Target $HomeDir

    if ($ok) { Write-Host "`n  Sakura updated!" -ForegroundColor Green }
    else { Write-Host "`n  Update failed." -ForegroundColor Red }
    Write-Host ""
    Start-Sleep -Seconds 3
    exit 0
}

# ===== FRESH INSTALL =====
Write-Host "  Fresh install..." -ForegroundColor Cyan

foreach ($sub in @("bin", "lib", "modules", "buckets", "apps", "shims", "cache", "persist", "data", "pet")) {
    $p = "$HomeDir\$sub"
    if (-not (Test-Path $p)) { cmd /c mkdir "$p" 2>&1 | Out-Null }
}

$ok = Download-Repo
if (-not $ok) { exit 1 }
Copy-ToTarget -Target $HomeDir
Install-Shims -Target $HomeDir

# Config
$cfgPath = "$HomeDir\config.json"
if (-not (Test-Path $cfgPath)) {
    @{ version = "2.0.3"; default_bucket = "sakura-main"; use_isolated_path = $true; proxy = ""; last_update = (Get-Date).ToString("o") } | ConvertTo-Json | Set-Content -Path $cfgPath -Encoding UTF8
}

# Pet
$petPath = "$HomeDir\pet\pet.json"
if (-not (Test-Path $petPath)) {
    @{ name = "Sakura-chan"; species = "sakura-spirit"; level = 1; experience = 0; exp_to_next = 100; mood = "happy"; hunger = 50; energy = 100; happiness = 80; cleanliness = 70; health = 100; stage = "baby"; evolution_count = 0; created = (Get-Date).ToString("o"); last_fed = (Get-Date).ToString("o"); last_played = (Get-Date).ToString("o"); last_interaction = (Get-Date).ToString("o"); total_installs = 0; total_updates = 0; total_searches = 0; achievements = @(); items = @() } | ConvertTo-Json | Set-Content -Path $petPath -Encoding UTF8
}

# PATH
$curPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($curPath -notlike "*$HomeDir\shims*") {
    [Environment]::SetEnvironmentVariable("PATH", "$HomeDir\shims;$curPath", "User")
}

Write-Host ""
Write-Host "  Sakura v2.0.3 installed!" -ForegroundColor Green
Write-Host "    sak help    | sak pet    | sak install <app>" -ForegroundColor White
Write-Host ""
Start-Sleep -Seconds 3
exit
