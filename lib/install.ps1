# Sakura Install System
# Application installation pipeline

function Install-SakuraApp {
    param([string]$Name)

    Write-Host ""
    Write-Host "  Installing $Name..." -ForegroundColor Magenta
    Write-Host "  ─────────────────" -ForegroundColor DarkGray

    # Check if already installed
    $installedPath = Join-Path $Script:SakuraApps $Name
    if (Test-Path $installedPath) {
        Write-SakuraWarning "'$Name' is already installed. Use 'sakura update $Name' to update."
        return
    }

    # Resolve manifest
    $manifest = Get-SakuraManifest -AppName $Name
    if (-not $manifest) {
        Write-SakuraError "App '$Name' not found in any bucket."
        Write-SakuraInfo "Use 'sakura search $Name' to find available packages."
        return
    }

    Write-SakuraInfo "Found: $($manifest.name) v$($manifest.version)"
    Write-SakuraInfo "$($manifest.description)"

    # Validate manifest
    if (-not (Test-SakuraManifest -AppName $Name -Manifest $manifest)) {
        Write-SakuraError "Invalid manifest for '$Name'."
        return
    }

    # Resolve dependencies
    $deps = Resolve-Dependencies -Manifest $manifest
    foreach ($dep in $deps) {
        $depManifest = Get-SakuraManifest -AppName $dep
        if ($depManifest) {
            $depPath = Join-Path $Script:SakuraApps $dep
            if (-not (Test-Path $depPath)) {
                Write-SakuraProgress "Installing dependency: $dep"
                Install-SakuraApp -Name $dep
            }
        }
    }

    # Create app directory
    $appDir = Join-Path $Script:SakuraApps $Name
    $currentDir = Join-Path $appDir "current"
    if (-not (Test-Path $currentDir)) {
        New-Item -ItemType Directory -Path $currentDir -Force | Out-Null
    }

    # Download
    $downloadPath = Join-Path $Script:SakuraCache "$Name.$([System.IO.Path]::GetExtension($manifest.url))"

    Write-SakuraProgress "Downloading..."
    try {
        $url = if ($manifest.url -is [array]) { $manifest.url[0] } else { $manifest.url }
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $downloadPath -UseBasicParsing
        Write-SakuraSuccess "Downloaded successfully."
    } catch {
        Write-SakuraError "Download failed: $_"
        return
    }

    # Verify hash
    if ($manifest.hash) {
        Write-SakuraProgress "Verifying integrity..."
        $fileHash = (Get-FileHash -Path $downloadPath -Algorithm SHA256).Hash.ToLower()
        $expectedHash = $manifest.hash.ToLower().Replace("sha256:", "")

        if ($fileHash -ne $expectedHash) {
            Write-SakuraError "Hash mismatch! Expected: $expectedHash, Got: $fileHash"
            Remove-Item -Path $downloadPath -Force
            return
        }
        Write-SakuraSuccess "Hash verified."
    }

    # Extract
    Write-SakuraProgress "Extracting..."
    try {
        $extractDir = if ($manifest.extract_dir) { $manifest.extract_dir } else { "" }
        Expand-SakuraArchive -ArchivePath $downloadPath -DestinationPath $currentDir -ExtractDir $extractDir
        Write-SakuraSuccess "Extracted to $currentDir"
    } catch {
        Write-SakuraError "Extraction failed: $_"
        return
    }

    # Create shims
    if ($manifest.bin) {
        Write-SakuraProgress "Creating shims..."
        $bins = if ($manifest.bin -is [array]) { $manifest.bin } else { @($manifest.bin) }
        foreach ($bin in $bins) {
            $binPath = Join-Path $currentDir $bin
            if (Test-Path $binPath) {
                New-SakuraShim -AppName $Name -BinPath $binPath -ShimName ([System.IO.Path]::GetFileNameWithoutExtension($bin))
            } else {
                # Try to find the binary
                $found = Get-ChildItem -Path $currentDir -Recurse -Filter $bin -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($found) {
                    New-SakuraShim -AppName $Name -BinPath $found.FullName -ShimName ([System.IO.Path]::GetFileNameWithoutExtension($bin))
                }
            }
        }
    }

    # Handle shortcuts
    if ($manifest.shortcuts) {
        Write-SakuraProgress "Creating shortcuts..."
        foreach ($shortcut in $manifest.shortcuts) {
            New-SakuraShortcut -AppName $Name -ExecutablePath (Join-Path $currentDir $shortcut[0]) -Label $shortcut[1]
        }
    }

    # Create persist directory for persistent data
    $persistDir = Join-Path $Script:SakuraPersist $Name
    if (-not (Test-Path $persistDir)) {
        New-Item -ItemType Directory -Path $persistDir -Force | Out-Null
    }

    # Save manifest
    $manifestHash = @{}
    $manifest.PSObject.Properties | ForEach-Object { $manifestHash[$_.Name] = $_.Value }
    Save-InstalledManifest -AppName $Name -Version $manifest.version -Manifest $manifestHash

    # Clean up
    Remove-Item -Path $downloadPath -Force -ErrorAction SilentlyContinue

    # Update pet
    Add-PetExperience -Amount 25 -Reason "Installed $Name"

    # Update stats
    $statsFile = Join-Path $Script:SakuraData "stats.json"
    $stats = if (Test-Path $statsFile) {
        Get-Content -Path $statsFile -Raw | ConvertFrom-Json
    } else {
        [PSCustomObject]@{ installs = 0; updates = 0; searches = 0; uninstalls = 0 }
    }
    $stats.installs++
    $stats | ConvertTo-Json | Set-Content -Path $statsFile -Encoding UTF8

    Write-Host ""
    Write-Host "  ✅ $Name v$($manifest.version) installed successfully!" -ForegroundColor Green
    Write-Host "  🌸 Your pet gained 25 experience!" -ForegroundColor Magenta
    Write-Host ""
}

function Uninstall-SakuraApp {
    param([string]$Name)

    $appPath = Join-Path $Script:SakuraApps $Name
    if (-not (Test-Path $appPath)) {
        Write-SakuraError "'$Name' is not installed."
        return
    }

    Write-Host ""
    Write-Host "  Uninstalling $Name..." -ForegroundColor Yellow

    # Remove shims
    $manifest = Get-InstalledManifest -AppName $Name
    if ($manifest -and $manifest.bin) {
        $bins = if ($manifest.bin -is [array]) { $manifest.bin } else { @($manifest.bin) }
        foreach ($bin in $bins) {
            Remove-SakuraShim -ShimName ([System.IO.Path]::GetFileNameWithoutExtension($bin))
        }
    }

    # Remove app directory
    Remove-Item -Path $appPath -Recurse -Force

    # Remove shortcuts
    Remove-SakuraShortcuts -AppName $Name

    # Keep persist directory (user data)
    $persistDir = Join-Path $Script:SakuraPersist $Name
    if (Test-Path $persistDir) {
        Write-SakuraInfo "Persistent data kept at: $persistDir"
    }

    # Update pet
    Add-PetExperience -Amount 10 -Reason "Uninstalled $Name"

    Write-Host "  ✅ $Name uninstalled successfully!" -ForegroundColor Green
    Write-Host ""
}
