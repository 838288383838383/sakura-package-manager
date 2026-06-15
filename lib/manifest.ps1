# Sakura Manifest System
# Handles JSON app manifests (better than Scoop's!)

function Get-SakuraManifest {
    param([string]$AppName, [string]$FromBucket = "")

    # If specific bucket requested, only look there
    if ($FromBucket) {
        $bucketPath = Join-Path $Script:SakuraBuckets $FromBucket "bucket" "$AppName.json"
        if (Test-Path $bucketPath) {
            $content = Get-Content -Path $bucketPath -Raw -Encoding UTF8
            return $content | ConvertFrom-Json
        }
        return $null
    }

    $buckets = Get-ChildItem -Path $Script:SakuraBuckets -Directory -ErrorAction SilentlyContinue
    foreach ($bucket in $buckets) {
        $manifestPath = Join-Path $bucket.FullName "bucket" "$AppName.json"
        if (Test-Path $manifestPath) {
            $content = Get-Content -Path $manifestPath -Raw -Encoding UTF8
            return $content | ConvertFrom-Json
        }
    }

    # Check installed manifests
    $installedPath = Join-Path $Script:SakuraApps "$AppName" "current" "manifest.json"
    if (Test-Path $installedPath) {
        $content = Get-Content -Path $installedPath -Raw -Encoding UTF8
        return $content | ConvertFrom-Json
    }

    return $null
}

function Get-SakuraManifestAll {
    param([string]$AppName)

    $results = @()
    $buckets = Get-ChildItem -Path $Script:SakuraBuckets -Directory -ErrorAction SilentlyContinue
    foreach ($bucket in $buckets) {
        $manifestPath = Join-Path $bucket.FullName "bucket" "$AppName.json"
        if (Test-Path $manifestPath) {
            $content = Get-Content -Path $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $results += [PSCustomObject]@{
                Bucket = $bucket.Name
                Manifest = $content
            }
        }
    }
    return $results
}

function Show-BucketSelection {
    param(
        [string]$AppName,
        [array]$Options
    )

    if ($Options.Count -eq 1) {
        return $Options[0]
    }

    Write-Host ""
    Write-Host "  📦 Multiple sources found for '$AppName':" -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    $selected = 0
    $total = $Options.Count

    # Render function
    function Draw-Menu {
        param([int]$Highlight)
        # Move cursor up to redraw
        if ($Host.UI.RawUI) {
            for ($i = 0; $i -lt $total; $i++) {
                Write-Host "`r`e[2K" -NoNewline
            }
        }

        for ($i = 0; $i -lt $total; $i++) {
            $opt = $Options[$i]
            $marker = if ($i -eq $Highlight) { "  →" } else { "   " }
            $color = if ($i -eq $Highlight) { "Cyan" } else { "White" }
            $version = $opt.Manifest.version
            $desc = $opt.Manifest.description
            $nonportable = if ($opt.Manifest.nonportable) { " [installer]" } else { "" }
            Write-Host "`r$marker $($opt.Bucket)/$AppName v$version$nonportable" -ForegroundColor $color
            Write-Host "`r     └─ $desc" -ForegroundColor DarkGray
        }
        Write-Host ""
        Write-Host "  Use ↑/↓ arrows + Enter, or type bucket name, or 'q' to cancel" -ForegroundColor DarkGray
    }

    Draw-Menu -Highlight $selected

    # Arrow key input loop
    while ($true) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                $selected = if ($selected -gt 0) { $selected - 1 } else { $total - 1 }
                # Clear and redraw
                for ($i = 0; $i -lt ($total + 2); $i++) { Write-Host "`r`e[2K" }
                if ($Host.UI.RawUI.CursorPosition.Y -ge ($total + 2)) {
                    $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $Host.UI.RawUI.CursorPosition.Y - ($total + 2) }
                }
                Draw-Menu -Highlight $selected
            }
            40 { # Down arrow
                $selected = if ($selected -lt ($total - 1)) { $selected + 1 } else { 0 }
                for ($i = 0; $i -lt ($total + 2); $i++) { Write-Host "`r`e[2K" }
                if ($Host.UI.RawUI.CursorPosition.Y -ge ($total + 2)) {
                    $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $Host.UI.RawUI.CursorPosition.Y - ($total + 2) }
                }
                Draw-Menu -Highlight $selected
            }
            13 { # Enter
                Write-Host ""
                return $Options[$selected]
            }
            27 { # Escape
                Write-Host ""
                return $null
            }
            default {
                # If user types a bucket name directly
                $char = $key.Character
                if ($char -match '[a-zA-Z0-9\-_]') {
                    $typed = ""
                    while ($key.VirtualKeyCode -ne 13 -and $key.VirtualKeyCode -ne 27) {
                        $typed += $char
                        Write-Host -NoNewline $char
                        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        $char = $key.Character
                    }
                    # Find matching bucket
                    $match = $Options | Where-Object { $_.Bucket -like "*$typed*" } | Select-Object -First 1
                    if ($match) {
                        Write-Host ""
                        return $match
                    }
                    Write-Host ""
                    Draw-Menu -Highlight $selected
                }
            }
        }
    }
}

function Test-SakuraManifest {
    param(
        [string]$AppName,
        [hashtable]$Manifest
    )

    $required = @("name", "version", "url")
    foreach ($field in $required) {
        if (-not $Manifest.ContainsKey($field)) {
            Write-SakuraError "Manifest for '$AppName' missing required field: $field"
            return $false
        }
    }

    # Validate URL format
    if ($Manifest.url -isnot [string] -and $Manifest.url -isnot [array]) {
        Write-SakuraError "Invalid URL format in manifest for '$AppName'"
        return $false
    }

    return $true
}

function Save-InstalledManifest {
    param(
        [string]$AppName,
        [string]$Version,
        [hashtable]$Manifest
    )

    $appDir = Join-Path $Script:SakuraApps $AppName "current"
    if (-not (Test-Path $appDir)) {
        New-Item -ItemType Directory -Path $appDir -Force | Out-Null
    }

    $manifestData = $Manifest.Clone()
    $manifestData["installed_at"] = (Get-Date).ToString("o")
    $manifestData["installed_version"] = $Version

    $json = $manifestData | ConvertTo-Json -Depth 10
    Set-Content -Path (Join-Path $appDir "manifest.json") -Value $json -Encoding UTF8
}

function Get-InstalledManifest {
    param([string]$AppName)

    $manifestPath = Join-Path $Script:SakuraApps $AppName "current" "manifest.json"
    if (Test-Path $manifestPath) {
        $content = Get-Content -Path $manifestPath -Raw -Encoding UTF8
        return $content | ConvertFrom-Json
    }
    return $null
}

function Compare-SakuraVersions {
    param(
        [string]$Current,
        [string]$Latest
    )

    if ($Current -eq $Latest) { return 0 }

    try {
        $v1 = [version]$Current
        $v2 = [version]$Latest
        return $v1.CompareTo($v2)
    } catch {
        # Fallback to string comparison
        return [string]::Compare($Current, $Latest, [StringComparison]::OrdinalIgnoreCase)
    }
}

function Expand-SakuraArchive {
    param(
        [string]$ArchivePath,
        [string]$DestinationPath,
        [string]$ExtractDir = ""
    )

    $ext = [System.IO.Path]::GetExtension($ArchivePath).ToLower()

    switch ($ext) {
        ".zip" {
            Expand-Archive -Path $ArchivePath -DestinationPath $DestinationPath -Force
        }
        ".7z" {
            # Use 7-Zip if available
            $7zPath = Get-Command "7z" -ErrorAction SilentlyContinue
            if ($7zPath) {
                & 7z x $ArchivePath -o"$DestinationPath" -y
            } else {
                Write-SakuraWarning "7-Zip not found. Trying to use .NET extraction..."
                [System.IO.Compression.ZipFile]::ExtractToDirectory($ArchivePath, $DestinationPath)
            }
        }
        ".msi" {
            # Extract MSI contents
            $msiPath = Join-Path $env:TEMP "sakura_msi_extract"
            if (-not (Test-Path $msiPath)) {
                New-Item -ItemType Directory -Path $msiPath -Force | Out-Null
            }
            & msiexec /a $ArchivePath /qb "TARGETDIR=$msiPath"
            Move-Item -Path "$msiPath\*" -Destination $DestinationPath -Force
        }
        default {
            Write-SakuraWarning "Unknown archive format: $ext"
            # Try as zip
            Expand-Archive -Path $ArchivePath -DestinationPath $DestinationPath -Force
        }
    }
}
