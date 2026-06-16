# Sakura Install System
# Application installation pipeline

function Test-InstallConflict {
    param([string]$AppName)

    $conflicts = @()

    # Check Scoop
    $scoopCheck = Get-Command scoop -ErrorAction SilentlyContinue
    if ($scoopCheck) {
        $scoopApps = scoop list 2>&1 | Out-String
        if ($scoopApps -match "(?i)$AppName") {
            $conflicts += "Scoop (already installed)"
        }
    }

    # Check Chocolatey
    $chocoCheck = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoCheck) {
        $chocoApps = choco list --local-only 2>&1 | Out-String
        if ($chocoApps -match "(?i)$AppName") {
            $conflicts += "Chocolatey (already installed)"
        }
    }

    # Check winget
    $wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCheck) {
        $wingetApps = winget list --name $AppName 2>&1 | Out-String
        if ($wingetApps -match "(?i)$AppName") {
            $conflicts += "winget (already installed)"
        }
    }

    # Check common Program Files locations
    $pfPaths = @(
        "${env:ProgramFiles}\$AppName",
        "${env:ProgramFiles(x86)}\$AppName",
        "$env:LOCALAPPDATA\$AppName"
    )
    foreach ($p in $pfPaths) {
        if (Test-Path $p) {
            $conflicts += "Manual install at: $p"
        }
    }

    # Check if command exists in PATH
    $cmdCheck = Get-Command $AppName -ErrorAction SilentlyContinue
    if ($cmdCheck) {
        $cmdPath = $cmdCheck.Source
        if ($cmdPath -and $cmdPath -notlike "*$env:USERPROFILE\.sakura*") {
            $conflicts += "Command exists at: $cmdPath"
        }
    }

    return $conflicts
}

function Install-SakuraApp {
    param(
        [string]$Name,
        [string]$FromBucket = ""
    )

    Write-Host ""
    Write-Host "  Installing $Name..." -ForegroundColor Magenta
    Write-Host "  -------------------" -ForegroundColor DarkGray

    # Check if already installed
    $installedPath = Join-Path $Script:SakuraApps $Name
    if (Test-Path $installedPath) {
        Write-SakuraWarning "$Name is already installed. Use 'sakura update $Name' to update."
        return
    }

    # Find all available manifests across buckets
    $allMatches = Get-SakuraManifestAll -AppName $Name

    if ($allMatches.Count -eq 0) {
        Write-SakuraError "App '$Name' not found in any bucket."
        Write-SakuraInfo "Use 'sakura search $Name' to find available packages."
        return
    }

    # If specific bucket requested, use it
    if ($FromBucket) {
        $selected = $allMatches | Where-Object { $_.Bucket -eq $FromBucket } | Select-Object -First 1
        if (-not $selected) {
            Write-SakuraError "App '$Name' not found in bucket '$FromBucket'."
            $available = ($allMatches | ForEach-Object { $_.Bucket }) -join ", "
            Write-SakuraInfo "Available in: $available"
            return
        }
    }
    # If multiple matches, show interactive selection
    elseif ($allMatches.Count -gt 1) {
        $selected = Show-BucketSelection -AppName $Name -Options $allMatches
        if (-not $selected) {
            Write-SakuraInfo "Installation cancelled."
            return
        }
    }
    else {
        $selected = $allMatches[0]
    }

    $manifest = $selected.Manifest
    Write-SakuraInfo "Source: $($selected.Bucket)/bucket"
    Write-Host "  Found: $($manifest.name) v$($manifest.version)" -ForegroundColor White
    Write-Host "  $($manifest.description)" -ForegroundColor DarkGray

    # Check for conflicts
    $conflicts = Test-InstallConflict -AppName $Name
    if ($conflicts.Count -gt 0) {
        Write-Host ""
        Write-Host "  Potential conflicts detected:" -ForegroundColor Yellow
        foreach ($c in $conflicts) {
            Write-Host "    - $c" -ForegroundColor Yellow
        }
        Write-Host ""
        $answer = Read-Host "  Continue anyway? (y/n)"
        if ($answer -ne "y" -and $answer -ne "Y") {
            Write-Host "  Installation cancelled." -ForegroundColor DarkGray
            return
        }
        Write-Host ""
    }

    # Handle WSL distros
    if ($manifest.wsl) {
        Write-SakuraProgress "Detected WSL distribution..."
        $tarPath = Join-Path $Script:SakuraCache "$Name.tar.gz"

        Write-SakuraProgress "Downloading distro..."
        try {
            $url = if ($manifest.url -is [array]) { $manifest.url[0] } else { $manifest.url }
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $url -OutFile $tarPath -UseBasicParsing
            Write-SakuraSuccess "Downloaded."
        } catch {
            Write-SakuraError "Download failed: $_"
            return
        }

        $postInstall = @()
        if ($manifest.installer -and $manifest.installer.post_install) {
            $postInstall = if ($manifest.installer.post_install -is [array]) {
                $manifest.installer.post_install
            } else {
                @($manifest.installer.post_install)
            }
        }

        Install-WslDistro -Name $Name -DistroName $manifest.wsl_name -TarPath $tarPath -Version $manifest.wsl_version -PostInstall $postInstall

        Remove-Item -Path $tarPath -Force -ErrorAction SilentlyContinue
        Add-PetExperience -Amount 30 -Reason "Installed WSL distro: $Name"
        return
    }

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
    $url = if ($manifest.url -is [array]) { $manifest.url[0] } else { $manifest.url }
    $ext = [System.IO.Path]::GetExtension($url)
    $downloadPath = Join-Path $Script:SakuraCache "$Name$ext"

    Write-SakuraProgress "Downloading..."
    try {
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

    # Handle non-portable installer OR extract
    if ($manifest.installer -or $manifest.nonportable) {
        # Non-portable install (MSI, EXE, Inno, NSIS, etc.)
        $installer = $manifest.installer
        if (-not $installer) { $installer = @{} }

        $installType = if ($installer.type) { $installer.type } else {
            $ext2 = [System.IO.Path]::GetExtension($downloadPath).ToLower()
            switch ($ext2) {
                ".msi" { "msi" }
                ".exe" { "exe" }
                default { "exe" }
            }
        }

        Write-SakuraProgress "Running $installType installer..."

        $installArgs = @()
        $silentArgs = @()

        switch ($installType) {
            "msi" {
                $silentArgs = @("/i", "`"$downloadPath`"", "/quiet", "/norestart")
                if ($installer.args) { $silentArgs += $installer.args }
                if ($installer.admin) {
                    $installArgs = @("-Command", "Start-Process msiexec -ArgumentList '$($silentArgs -join ' ')' -Verb RunAs -Wait")
                } else {
                    $installArgs = @("-Command", "msiexec $($silentArgs -join ' ')")
                }
            }
            "inno" {
                $silentArgs = @("/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/SP-")
                if ($installer.args) { $silentArgs += $installer.args }
                $installArgs = @("-Command", "Start-Process `"$downloadPath`" -ArgumentList '$($silentArgs -join ' ')' -Wait")
            }
            "nsis" {
                $silentArgs = @("/S")
                if ($installer.args) { $silentArgs += $installer.args }
                $installArgs = @("-Command", "Start-Process `"$downloadPath`" -ArgumentList '$($silentArgs -join ' ')' -Wait")
            }
            "7z" {
                $extractDir = if ($installer.install_dir) { $installer.install_dir } else { $currentDir }
                Expand-SakuraArchive -ArchivePath $downloadPath -DestinationPath $extractDir
            }
            default {
                # Generic EXE
                $exeArgs = @()
                if (-not $installer.interactive) {
                    $exeArgs += @("/S", "/SILENT", "/VERYSILENT", "/quiet", "/qn", "/norestart")
                }
                if ($installer.args) { $exeArgs = $installer.args }
                $installArgs = @("-Command", "Start-Process `"$downloadPath`" -ArgumentList '$($exeArgs -join ' ')' -Wait")
            }
        }

        if ($installType -ne "7z") {
            try {
                if ($installer.script) {
                    $script = $installer.script
                    if ($script -is [array]) { $script = $script -join "`n" }
                    Invoke-Expression $script
                } else {
                    if ($installType -eq "msi" -and -not $installer.admin) {
                        & msiexec $silentArgs
                    } else {
                        Invoke-Expression $installArgs
                    }
                }
                Write-SakuraSuccess "Installer completed."
            } catch {
                Write-SakuraError "Installation failed: $_"
                return
            }
        }

        # Find installed binaries
        $installDir = if ($installer.install_dir) { $installer.install_dir } else { "${env:ProgramFiles}\$Name" }
        if ($manifest.bin) {
            $bins = if ($manifest.bin -is [array]) { $manifest.bin } else { @($manifest.bin) }
            foreach ($bin in $bins) {
                $locations = @(
                    $installDir,
                    "${env:ProgramFiles}\$Name",
                    "${env:ProgramFiles(x86)}\$Name",
                    "$env:LOCALAPPDATA\$Name"
                )
                $found = $false
                foreach ($loc in $locations) {
                    $binPath = Join-Path $loc $bin
                    if (Test-Path $binPath) {
                        New-SakuraShim -AppName $Name -BinPath $binPath -ShimName ([System.IO.Path]::GetFileNameWithoutExtension($bin))
                        $found = $true
                        break
                    }
                }
                if (-not $found) {
                    $searchResult = Get-ChildItem -Path "${env:ProgramFiles}" -Recurse -Filter $bin -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($searchResult) {
                        New-SakuraShim -AppName $Name -BinPath $searchResult.FullName -ShimName ([System.IO.Path]::GetFileNameWithoutExtension($bin))
                    }
                }
            }
        }

        # Run post_install if any
        if ($manifest.post_install) {
            $postScripts = if ($manifest.post_install -is [array]) { $manifest.post_install } else { @($manifest.post_install) }
            foreach ($cmd in $postScripts) {
                Write-SakuraProgress "Running post-install: $cmd"
                try {
                    Invoke-Expression $cmd
                } catch {
                    Write-SakuraWarning "Post-install command failed: $_"
                }
            }
        }

    } else {
        # Portable install (extract)
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
                New-SakuraShortcut -AppName $Name -ExecutablePath (Join-Path $currentDir $shortcut[1]) -Label $shortcut[0]
            }
        }
    }

    # Create persist directory for persistent data
    $persistDir = Join-Path $Script:SakuraPersist $Name
    if (-not (Test-Path $persistDir)) {
        New-Item -ItemType Directory -Path $persistDir -Force | Out-Null
    }

    # Handle setup prompts
    if ($manifest.setup_prompts) {
        Write-Host ""
        Write-Host "  Setup Options:" -ForegroundColor Cyan
        $setupAnswers = @{}
        foreach ($prompt in $manifest.setup_prompts) {
            if ($prompt.requires) {
                $reqApp = $prompt.requires.app
                $reqVer = $prompt.requires.min_version
                $reqInstalled = Test-Path (Join-Path $Script:SakuraApps $reqApp)
                if (-not $reqInstalled) { continue }
                if ($reqVer) {
                    $reqManifest = Get-InstalledManifest -AppName $reqApp
                    if ($reqManifest -and (Compare-SakuraVersions -Current $reqManifest.version -Latest $reqVer) -lt 0) {
                        continue
                    }
                }
            }

            switch ($prompt.type) {
                "yesno" {
                    $default = if ($prompt.default) { $prompt.default } else { "no" }
                    $indicator = if ($default -eq "yes") { "[Y/n]" } else { "[y/N]" }
                    Write-Host ""
                    Write-Host "  $($prompt.question) $indicator" -ForegroundColor Yellow
                    $answer = Read-Host "  "
                    if ([string]::IsNullOrWhiteSpace($answer)) { $answer = $default }
                    $setupAnswers[$prompt.id] = $answer.ToLower() -eq "yes" -or $answer.ToLower() -eq "y"
                }
                "choice" {
                    Write-Host ""
                    Write-Host "  $($prompt.question)" -ForegroundColor Yellow
                    for ($i = 0; $i -lt $prompt.options.Count; $i++) {
                        $opt = $prompt.options[$i]
                        $marker = if ($i -eq 0) { ">>" } else { "  " }
                        Write-Host "  $marker [$($i+1)] $($opt.label) - $($opt.description)" -ForegroundColor White
                    }
                    $default = if ($prompt.default) { $prompt.default } else { "1" }
                    $answer = Read-Host "  Select (default: $default)"
                    if ([string]::IsNullOrWhiteSpace($answer)) { $answer = $default }
                    $idx = [int]$answer - 1
                    if ($idx -ge 0 -and $idx -lt $prompt.options.Count) {
                        $setupAnswers[$prompt.id] = $prompt.options[$idx].value
                    } else {
                        $setupAnswers[$prompt.id] = $prompt.options[0].value
                    }
                }
                "text" {
                    Write-Host ""
                    Write-Host "  $($prompt.question)" -ForegroundColor Yellow
                    $answer = Read-Host "  "
                    if ([string]::IsNullOrWhiteSpace($answer) -and $prompt.default) {
                        $answer = $prompt.default
                    }
                    $setupAnswers[$prompt.id] = $answer
                }
            }
        }

        # Run setup scripts based on answers
        if ($manifest.setup_scripts) {
            foreach ($key in $setupAnswers.Keys) {
                $value = $setupAnswers[$key]
                if ($value -and $manifest.setup_scripts.PSObject.Properties[$key]) {
                    $script = $manifest.setup_scripts.$key
                    if ($script -is [string]) {
                        $script = @($script)
                    }
                    foreach ($cmd in $script) {
                        Write-SakuraProgress "Running setup: $cmd"
                        $cmd = $cmd -replace '\$install_dir', $currentDir
                        $cmd = $cmd -replace '\$app_name', $Name
                        $cmd = $cmd -replace '\$pet_dir', $Script:SakuraPetData
                        try {
                            Invoke-Expression $cmd
                        } catch {
                            Write-SakuraWarning "Setup command failed: $_"
                        }
                    }
                }
            }
        }
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
    Write-Host "  OK: $Name v$($manifest.version) installed successfully!" -ForegroundColor Green
    Write-Host "  Your pet gained 25 experience!" -ForegroundColor Magenta
    Write-Host ""
}

function Uninstall-SakuraApp {
    param([string]$Name)

    $appPath = Join-Path $Script:SakuraApps $Name
    if (-not (Test-Path $appPath)) {
        Write-SakuraError "$Name is not installed."
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

    Write-Host "  OK: $Name uninstalled successfully!" -ForegroundColor Green
    Write-Host ""
}
