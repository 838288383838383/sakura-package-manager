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
