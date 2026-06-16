# Sakura WSL Installer
# Handles installing custom WSL distros

function Install-WslDistro {
    param(
        [string]$Name,
        [string]$DistroName,
        [string]$TarPath,
        [int]$Version = 2,
        [array]$PostInstall = @()
    )

    Write-Host ""
    Write-Host "  Installing WSL Distribution: $DistroName" -ForegroundColor Cyan
    Write-Host "  ==========================================" -ForegroundColor DarkGray

    # Check if WSL is enabled
    $wslStatus = wsl --status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-SakuraWarning "WSL may not be enabled on this system."
        Write-Host ""
        Write-Host "  To enable WSL, run as Administrator:" -ForegroundColor Yellow
        Write-Host "    wsl --install" -ForegroundColor White
        Write-Host ""
        $answer = Read-Host "  Try to enable WSL now? (y/n)"
        if ($answer -eq "y" -or $answer -eq "Y") {
            Write-SakuraProgress "Enabling WSL..."
            try {
                Start-Process powershell -Verb RunAs -ArgumentList "-Command wsl --install --no-distribution" -Wait
                Write-SakuraSuccess "WSL enabled. You may need to restart your computer."
                Write-SakuraInfo "After restart, run: sak install $Name -viab sakura-wsl"
                return
            } catch {
                Write-SakuraError "Failed to enable WSL. Please enable manually."
                return
            }
        } else {
            return
        }
    }

    # Check if distro already exists
    $existing = wsl --list --quiet 2>&1 | Select-String $DistroName
    if ($existing) {
        Write-SakuraWarning "Distribution '$DistroName' is already installed."
        Write-Host "  Use: wsl -d $DistroName" -ForegroundColor DarkGray
        return
    }

    # Check if the tar file exists
    if (-not (Test-Path $TarPath)) {
        Write-SakuraError "Distribution file not found: $TarPath"
        return
    }

    # Import the distro
    $installDir = Join-Path $Script:SakuraApps "wsl\$Name"
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }

    Write-SakuraProgress "Importing $DistroName into WSL..."
    try {
        & wsl --import $DistroName $installDir $TarPath
        if ($LASTEXITCODE -ne 0) {
            throw "WSL import failed"
        }
        Write-SakuraSuccess "Distribution imported successfully."
    } catch {
        Write-SakuraError "Failed to import distribution: $_"
        return
    }

    # Set default version
    if ($Version -eq 2) {
        Write-SakuraProgress "Setting WSL version 2..."
        wsl --set-version $DistroName 2 2>&1 | Out-Null
    }

    # Run post-install scripts
    if ($PostInstall.Count -gt 0) {
        Write-SakuraProgress "Running post-install setup..."
        foreach ($cmd in $PostInstall) {
            Write-SakuraProgress "  > $cmd"
            try {
                & wsl -d $DistroName -- bash -c $cmd
            } catch {
                Write-SakuraWarning "  Post-install step failed (non-fatal): $_"
            }
        }
    }

    # Create launch shim
    $shimPath = Join-Path $Script:SakuraShims "$DistroName.cmd"
    $shimContent = @"
@echo off
wsl -d $DistroName %*
"@
    Set-Content -Path $shimPath -Value $shimContent -Encoding ASCII

    Write-Host ""
    Write-Host "  OK: $DistroName installed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Launch with:" -ForegroundColor Yellow
    Write-Host "    wsl -d $DistroName" -ForegroundColor White
    Write-Host "    $DistroName" -ForegroundColor White
    Write-Host ""
}

function Uninstall-WslDistro {
    param([string]$DistroName)

    Write-Host ""
    Write-Host "  Uninstalling WSL Distribution: $DistroName" -ForegroundColor Yellow

    $existing = wsl --list --quiet 2>&1 | Select-String $DistroName
    if (-not $existing) {
        Write-SakuraError "Distribution '$DistroName' not found."
        return
    }

    Write-SakuraProgress "Terminating distro..."
    wsl --terminate $DistroName 2>&1 | Out-Null

    Write-SakuraProgress "Unregistering distro..."
    wsl --unregister $DistroName 2>&1 | Out-Null

    # Remove shim
    $shimPath = Join-Path $Script:SakuraShims "$DistroName.cmd"
    if (Test-Path $shimPath) {
        Remove-Item -Path $shimPath -Force
    }

    Write-SakuraSuccess "$DistroName uninstalled."
}

function Show-WslDistros {
    Write-Host ""
    Write-Host "  Installed WSL Distributions:" -ForegroundColor Cyan
    Write-Host "  -----------------------------" -ForegroundColor DarkGray

    $distros = wsl --list --verbose 2>&1
    if ($distros -match "There are no installed distributions") {
        Write-SakuraInfo "No WSL distributions installed."
        Write-Host "  Install one with: sak install <distro> -viab sakura-wsl" -ForegroundColor DarkGray
    } else {
        Write-Host ""
        foreach ($line in $distros) {
            if ($line -match "^\s*(\*?\s*)(\S+)\s+(Running|Stopped)\s+(\d+)\s+(1|2)") {
                $default = $matches[1].Trim()
                $name = $matches[2]
                $state = $matches[3]
                $version = $matches[5]
                $color = if ($state -eq "Running") { "Green" } else { "DarkGray" }
                $marker = if ($default -eq "*") { " *" } else { "  " }
                Write-Host "    $marker $($name.PadRight(28))" -NoNewline -ForegroundColor White
                Write-Host " v$version".PadRight(6) -NoNewline -ForegroundColor DarkGray
                Write-Host " [$state]" -ForegroundColor $color
            }
        }
    }
    Write-Host ""
}
