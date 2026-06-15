# Sakura Update System

function Update-SakuraPackages {
    param(
        [string[]]$Names,
        [switch]$All
    )

    if ($All) {
        Write-Host "`n  Updating all packages..." -ForegroundColor Cyan
        $apps = Get-ChildItem -Path $Script:SakuraApps -Directory -ErrorAction SilentlyContinue
        foreach ($app in $apps) {
            Update-SinglePackage -Name $app.Name
        }
        Write-Host "`n  ✅ All packages updated!" -ForegroundColor Green
    } elseif ($Names.Count -gt 0) {
        foreach ($name in $Names) {
            Update-SinglePackage -Name $name
        }
    } else {
        Write-Host "`n  Checking for updates..." -ForegroundColor Cyan
        $apps = Get-ChildItem -Path $Script:SakuraApps -Directory -ErrorAction SilentlyContinue
        $updatesAvailable = 0

        foreach ($app in $apps) {
            $installedManifest = Get-InstalledManifest -AppName $app.Name
            $latestManifest = Get-SakuraManifest -AppName $app.Name

            if ($installedManifest -and $latestManifest) {
                $comparison = Compare-SakuraVersions -Current $installedManifest.version -Latest $latestManifest.version
                if ($comparison -lt 0) {
                    Write-Host "    $($app.Name): $($installedManifest.version) -> $($latestManifest.version)" -ForegroundColor Yellow
                    $updatesAvailable++
                }
            }
        }

        if ($updatesAvailable -eq 0) {
            Write-SakuraSuccess "All packages are up to date!"
        } else {
            Write-Host "`n  $updatesAvailable update(s) available. Run 'sakura upgrade' to update all." -ForegroundColor Yellow
        }
        Write-Host ""
    }
}

function Update-SinglePackage {
    param([string]$Name)

    $installedManifest = Get-InstalledManifest -AppName $Name
    $latestManifest = Get-SakuraManifest -AppName $Name

    if (-not $installedManifest -or -not $latestManifest) {
        return
    }

    $comparison = Compare-SakuraVersions -Current $installedManifest.version -Latest $latestManifest.version
    if ($comparison -ge 0) {
        return  # Already up to date
    }

    Write-Host "  Updating $Name: $($installedManifest.version) -> $($latestManifest.version)" -ForegroundColor Yellow

    # Uninstall old version (but keep persist)
    $appPath = Join-Path $Script:SakuraApps $Name
    $persistPath = Join-Path $Script:SakuraPersist $Name
    $tempPersist = Join-Path $env:TEMP "sakura_persist_$Name"

    if (Test-Path $persistPath) {
        Copy-Item -Path $persistPath -Destination $tempPersist -Recurse -Force
    }

    # Remove shims
    if ($installedManifest.bin) {
        $bins = if ($installedManifest.bin -is [array]) { $installedManifest.bin } else { @($installedManifest.bin) }
        foreach ($bin in $bins) {
            Remove-SakuraShim -ShimName ([System.IO.Path]::GetFileNameWithoutExtension($bin))
        }
    }

    Remove-Item -Path $appPath -Recurse -Force -ErrorAction SilentlyContinue

    # Reinstall
    Install-SakuraApp -Name $Name

    # Restore persist
    if (Test-Path $tempPersist) {
        Copy-Item -Path $tempPersist -Destination $persistPath -Recurse -Force
        Remove-Item -Path $tempPersist -Recurse -Force
    }

    # Update pet
    Add-PetExperience -Amount 15 -Reason "Updated $Name"

    Write-SakuraSuccess "$Name updated to $($latestManifest.version)"
}

function Update-SakuraSelf {
    Write-Host ""
    Write-Host "  🌸 Updating Sakura Package Manager..." -ForegroundColor Magenta
    Write-Host "  ═══════════════════════════════════════" -ForegroundColor DarkGray

    $sakuraHome = Split-Path -Parent $Script:SakuraRoot

    # Check if we're in a git repo
    $gitDir = Join-Path $sakuraHome ".git"
    if (-not (Test-Path $gitDir)) {
        Write-SakuraError "Sakura is not installed from git. Cannot self-update."
        Write-SakuraInfo "Reinstall from: https://github.com/838288383838383/sakura-package-manager"
        return
    }

    Write-SakuraProgress "Checking for updates..."
    try {
        $ProgressPreference = 'SilentlyContinue'
        git -C $sakuraHome fetch origin main 2>&1 | Out-Null

        $local = git -C $sakuraHome rev-parse HEAD
        $remote = git -C $sakuraHome rev-parse origin/main

        if ($local -eq $remote) {
            Write-SakuraSuccess "Sakura is already up to date! (v$SakuraVersion)"
            Write-Host ""
            return
        }

        # Show what's new
        Write-Host ""
        Write-Host "  📦 Updates available:" -ForegroundColor Yellow
        $commits = git -C $sakuraHome log --oneline "$local..$remote" 2>&1
        foreach ($commit in $commits) {
            Write-Host "    • $commit" -ForegroundColor DarkGray
        }
        Write-Host ""

        # Backup current version
        $backupDir = Join-Path $env:TEMP "sakura_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Copy-Item -Path "$sakuraHome\lib\*" -Destination "$backupDir" -Recurse -Force
        Copy-Item -Path "$sakuraHome\bin\*" -Destination "$backupDir" -Recurse -Force
        Copy-Item -Path "$sakuraHome\modules" -Destination "$backupDir" -Recurse -Force
        Write-SakuraInfo "Backup saved to: $backupDir"

        # Pull update
        Write-SakuraProgress "Pulling update..."
        git -C $sakuraHome pull origin main 2>&1 | Out-Null

        # Get new version
        $newVersion = git -C $sakuraHome describe --tags --abbrev=0 2>&1
        if ($LASTEXITCODE -ne 0) {
            # Try to extract from core.ps1
            $coreContent = Get-Content -Path "$sakuraHome\lib\core.ps1" -Raw
            if ($coreContent -match 'SakuraVersion\s*=\s*"(.+?)"') {
                $newVersion = $Matches[1]
            } else {
                $newVersion = "unknown"
            }
        }

        Write-Host ""
        Write-Host "  ✅ Sakura updated successfully!" -ForegroundColor Green
        Write-Host "  🌸 New version: $newVersion" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "  Restart your terminal or run:" -ForegroundColor Yellow
        Write-Host "    sakura version" -ForegroundColor White
        Write-Host ""

        # Update pet
        Add-PetExperience -Amount 50 -Reason "Updated Sakura itself"

    } catch {
        Write-SakuraError "Update failed: $_"
        Write-SakuraInfo "You can manually run: git -C $sakuraHome pull origin main"
        return
    }
}
