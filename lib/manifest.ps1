# Sakura Manifest System
# Handles JSON app manifests (better than Scoop's!)

function Get-SakuraManifest {
    param([string]$AppName)

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
