# Sakura Manifest System
# Handles JSON app manifests (better than Scoop's!)

function Get-SakuraManifest {
    param([string]$AppName, [string]$FromBucket = "")

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
    Write-Host "  Multiple sources found for '$AppName':" -ForegroundColor Yellow
    Write-Host "  ---------------------------------------" -ForegroundColor DarkGray
    Write-Host ""

    $selected = 0
    $total = $Options.Count

    # Draw the menu
    for ($i = 0; $i -lt $total; $i++) {
        $opt = $Options[$i]
        $version = $opt.Manifest.version
        $desc = $opt.Manifest.description
        $np = ""
        if ($opt.Manifest.nonportable) { $np = " [installer]" }

        if ($i -eq $selected) {
            Write-Host "  >> $($opt.Bucket)/$AppName v$version$np" -ForegroundColor Cyan
        } else {
            Write-Host "     $($opt.Bucket)/$AppName v$version$np" -ForegroundColor White
        }
        Write-Host "        $desc" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  Use UP/DOWN arrows + Enter, or 'q' to cancel" -ForegroundColor DarkGray

    # Arrow key input
    while ($true) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        if ($key.VirtualKeyCode -eq 38) {
            # Up arrow
            $selected = $selected - 1
            if ($selected -lt 0) { $selected = $total - 1 }
        }
        elseif ($key.VirtualKeyCode -eq 40) {
            # Down arrow
            $selected = $selected + 1
            if ($selected -ge $total) { $selected = 0 }
        }
        elseif ($key.VirtualKeyCode -eq 13) {
            # Enter
            Write-Host ""
            return $Options[$selected]
        }
        elseif ($key.VirtualKeyCode -eq 27) {
            # Escape
            Write-Host ""
            return $null
        }

        # Redraw menu
        $topY = $Host.UI.RawUI.CursorPosition.Y - ($total * 2)
        if ($topY -gt 0) {
            $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $topY }
        }

        for ($i = 0; $i -lt $total; $i++) {
            $opt = $Options[$i]
            $version = $opt.Manifest.version
            $np = ""
            if ($opt.Manifest.nonportable) { $np = " [installer]" }

            # Clear line
            Write-Host ("`r" + " " * 80 + "`r") -NoNewline

            if ($i -eq $selected) {
                Write-Host "`r  >> $($opt.Bucket)/$AppName v$version$np" -ForegroundColor Cyan -NoNewline
            } else {
                Write-Host "`r     $($opt.Bucket)/$AppName v$version$np" -ForegroundColor White -NoNewline
            }
            Write-Host ""

            # Clear desc line
            Write-Host ("`r" + " " * 80 + "`r") -NoNewline
            Write-Host "`r        $($opt.Manifest.description)" -ForegroundColor DarkGray -NoNewline
            Write-Host ""
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
            $7zPath = Get-Command "7z" -ErrorAction SilentlyContinue
            if ($7zPath) {
                & 7z x $ArchivePath -o"$DestinationPath" -y
            } else {
                Write-SakuraWarning "7-Zip not found. Trying .NET extraction..."
                [System.IO.Compression.ZipFile]::ExtractToDirectory($ArchivePath, $DestinationPath)
            }
        }
        ".msi" {
            $msiPath = Join-Path $env:TEMP "sakura_msi_extract"
            if (-not (Test-Path $msiPath)) {
                New-Item -ItemType Directory -Path $msiPath -Force | Out-Null
            }
            & msiexec /a $ArchivePath /qb "TARGETDIR=$msiPath"
            Move-Item -Path "$msiPath\*" -Destination $DestinationPath -Force
        }
        default {
            Write-SakuraWarning "Unknown archive format: $ext"
            Expand-Archive -Path $ArchivePath -DestinationPath $DestinationPath -Force
        }
    }
}
