# Sakura Bucket System
# Git-based package repositories (like Scoop but better)

function Show-SakuraBuckets {
    $buckets = Get-ChildItem -Path $Script:SakuraBuckets -Directory -ErrorAction SilentlyContinue
    if ($buckets.Count -eq 0) {
        Write-SakuraInfo "No buckets added. Use: sakura bucket add <name>"
        return
    }

    Write-Host "`n  Available Buckets:" -ForegroundColor Cyan
    Write-Host "  ─────────────────" -ForegroundColor DarkGray
    foreach ($bucket in $buckets) {
        $manifestCount = (Get-ChildItem -Path (Join-Path $bucket.FullName "bucket") -Filter "*.json" -ErrorAction SilentlyContinue).Count
        $defaultMarker = ""
        $config = Get-SakuraConfigObj
        if ($config.default_bucket -eq $bucket.Name) { $defaultMarker = " (default)" }
        Write-Host "    $($bucket.Name) [$manifestCount apps]$defaultMarker" -ForegroundColor White
    }
    Write-Host ""
}

function Add-SakuraBucket {
    param([string]$Name)

    $bucketPath = Join-Path $Script:SakuraBuckets $Name
    if (Test-Path $bucketPath) {
        Write-SakuraWarning "Bucket '$Name' already exists."
        return
    }

    Write-SakuraProgress "Adding bucket: $Name"

    # For now, create local bucket directory
    # In future, support git clone from GitHub
    New-Item -ItemType Directory -Path "$bucketPath\bucket" -Force | Out-Null

    # Create a placeholder README
    $readme = @"
# $Name Bucket
This is a Sakura package bucket.
Add JSON manifests to the bucket/ directory.

Each manifest should follow this format:
{
    "name": "app-name",
    "version": "1.0.0",
    "description": "App description",
    "url": "https://example.com/app.zip",
    "hash": "sha256-hash-here",
    "bin": ["app.exe"],
    "checkver": {
        "url": "https://example.com/releases",
        "regex": "v([\d.]+)"
    }
}
"@
    Set-Content -Path (Join-Path $bucketPath "README.md") -Value $readme -Encoding UTF8

    Write-SakuraSuccess "Bucket '$Name' added successfully."
}

function Remove-SakuraBucket {
    param([string]$Name)

    $bucketPath = Join-Path $Script:SakuraBuckets $Name
    if (-not (Test-Path $bucketPath)) {
        Write-SakuraError "Bucket '$Name' not found."
        return
    }

    Remove-Item -Path $bucketPath -Recurse -Force
    Write-SakuraSuccess "Bucket '$Name' removed."
}

function Search-SakuraBuckets {
    param([string]$Query)

    $results = @()
    $buckets = Get-ChildItem -Path $Script:SakuraBuckets -Directory -ErrorAction SilentlyContinue

    foreach ($bucket in $buckets) {
        $manifests = Get-ChildItem -Path (Join-Path $bucket.FullName "bucket") -Filter "*.json" -ErrorAction SilentlyContinue
        foreach ($manifest in $manifests) {
            $content = Get-Content -Path $manifest.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($content.name -like "*$Query*" -or $content.description -like "*$Query*") {
                $results += [PSCustomObject]@{
                    Name = $content.name
                    Version = $content.version
                    Description = $content.description
                    Bucket = $bucket.Name
                }
            }
        }
    }

    return $results
}

function Get-SakuraBucketManifests {
    param([string]$BucketName)

    $bucketPath = Join-Path $Script:SakuraBuckets $BucketName "bucket"
    if (-not (Test-Path $bucketPath)) {
        return @()
    }

    return Get-ChildItem -Path $bucketPath -Filter "*.json" -ErrorAction SilentlyContinue
}
