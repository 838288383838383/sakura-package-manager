# Sakura Update System

function Update-SakuraPackages {
    param(
        [string[]]$Names,
        [switch]$All
    )

    if ($All) {
        Write-Host ""
        Write-Host "  Updating all packages..." -ForegroundColor Cyan
        $apps = Get-ChildItem -Path $Script:SakuraApps -Directory -ErrorAction SilentlyContinue
        foreach ($app in $apps) {
            Update-SinglePackage -Name $app.Name
        }
        Write-Host ""
        Write-Host "  All packages updated!" -ForegroundColor Green
    } elseif ($Names.Count -gt 0) {
        foreach ($name in $Names) {
            Update-SinglePackage -Name $name
        }
    } else {
        Write-Host ""
        Write-Host "  Checking for updates..." -ForegroundColor Cyan
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
            Write-Host ""
            Write-Host "  $updatesAvailable update(s) available. Run 'sakura upgrade' to update all." -ForegroundColor Yellow
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

    Write-Host "  Updating ${Name}: $($installedManifest.version) -> $($latestManifest.version)" -ForegroundColor Yellow

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
    Write-Host "  Updating Sakura Package Manager..." -ForegroundColor Magenta
    Write-Host "  =====================================" -ForegroundColor DarkGray

    $sakuraHome = $Script:SakuraRoot
    $repoUrl = "https://github.com/838288383838383/sakura-package-manager/archive/refs/heads/main.zip"
    $zipPath = Join-Path $env:TEMP "sakura_update.zip"
    $extractPath = Join-Path $env:TEMP "sakura_update_extract"
    $hasGit = Test-Path (Join-Path $sakuraHome ".git")

    Write-SakuraProgress "Checking for updates..."

    if ($hasGit) {
        # Git update
        try {
            $ProgressPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            git -C $sakuraHome fetch origin main 2>&1 | Out-Null
            $local = git -C $sakuraHome rev-parse HEAD 2>&1
            $remote = git -C $sakuraHome rev-parse origin/main 2>&1
            $ErrorActionPreference = 'Stop'

            if ($local -eq $remote) {
                Write-SakuraSuccess "Sakura is already up to date! (v$SakuraVersion)"
                Write-Host ""
                return
            }

            Write-Host ""
            Write-Host "  Updates available:" -ForegroundColor Yellow
            $commits = git -C $sakuraHome log --oneline "$local..$remote" 2>&1
            foreach ($commit in $commits) {
                if ($commit -notmatch "^warning:|^error:") {
                    Write-Host "    - $commit" -ForegroundColor DarkGray
                }
            }
            Write-Host ""

            # Backup
            $backupDir = Join-Path $env:TEMP "sakura_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Copy-Item -Path "$sakuraHome\lib\*" -Destination "$backupDir" -Recurse -Force
            Copy-Item -Path "$sakuraHome\bin\*" -Destination "$backupDir" -Recurse -Force
            Copy-Item -Path "$sakuraHome\modules" -Destination "$backupDir" -Recurse -Force
            Write-SakuraInfo "Backup saved to: $backupDir"

            # Pull
            Write-SakuraProgress "Pulling update..."
            git -C $sakuraHome pull origin main 2>&1 | Out-Null

            Write-Host ""
            Write-Host "  Sakura updated!" -ForegroundColor Green
        } catch {
            Write-SakuraError "Git update failed: $_"
            return
        }
    } else {
        # Zip update (no git)
        Write-SakuraProgress "Downloading update..."
        $ProgressPreference = 'SilentlyContinue'
        try {
            if (Test-Path $extractPath) { Remove-Item -Recurse -Force $extractPath }
            Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath -UseBasicParsing
        } catch {
            Write-SakuraError "Download failed: $_"
            return
        }

        Write-SakuraProgress "Extracting..."
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        Remove-Item -Force $zipPath -ErrorAction SilentlyContinue

        $src = Join-Path $extractPath "sakura-package-manager-main"
        if (-not (Test-Path $src)) {
            Write-SakuraError "Bad zip structure"
            Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue
            return
        }

        # Check remote version
        $remoteVersion = "unknown"
        $sakuraPs1 = Join-Path $src "bin\sakura.ps1"
        if (Test-Path $sakuraPs1) {
            $content = Get-Content -Path $sakuraPs1 -Raw
            if ($content -match 'SakuraVersion\s*=\s*"(.+?)"') {
                $remoteVersion = $Matches[1]
            }
        }

        if ($remoteVersion -eq $SakuraVersion) {
            Write-Host ""
            Write-Host "  Already latest version! (v$SakuraVersion)" -ForegroundColor Green
            Write-Host ""
            Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue
            return
        }

        Write-Host ""
        Write-Host "  Update available: v$SakuraVersion -> v$remoteVersion" -ForegroundColor Yellow
        Write-Host ""

        # Backup
        $backupDir = Join-Path $env:TEMP "sakura_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Copy-Item -Path "$sakuraHome\lib\*" -Destination "$backupDir" -Recurse -Force
        Copy-Item -Path "$sakuraHome\bin\*" -Destination "$backupDir" -Recurse -Force
        Copy-Item -Path "$sakuraHome\modules" -Destination "$backupDir" -Recurse -Force
        Write-SakuraInfo "Backup saved to: $backupDir"

        # Copy files
        Copy-Item -Path "$src\lib\*" -Destination "$sakuraHome\lib" -Recurse -Force
        Copy-Item -Path "$src\bin\*" -Destination "$sakuraHome\bin" -Recurse -Force
        Copy-Item -Path "$src\modules\*" -Destination "$sakuraHome\modules" -Recurse -Force

        # Recreate shims
        $shimsDir = Join-Path $sakuraHome "shims"
        if (-not (Test-Path $shimsDir)) { cmd /c mkdir "$shimsDir" 2>&1 | Out-Null }
        $sakuraCmd = Join-Path $sakuraHome "bin\sakura.ps1"
        $bat = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0..\bin\sakura.ps1`" %*"
        [System.IO.File]::WriteAllText("$shimsDir\sakura.cmd", $bat, [System.Text.Encoding]::ASCII)
        [System.IO.File]::WriteAllText("$shimsDir\sak.cmd", $bat, [System.Text.Encoding]::ASCII)

        Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue

        Write-Host ""
        Write-Host "  Sakura updated!" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  Restart terminal or run: sak version" -ForegroundColor Yellow
    Write-Host ""

    Add-PetExperience -Amount 50 -Reason "Updated Sakura itself"
}
