# Sakura Bucket System
# Git-based package repositories (like Scoop but better)

function Show-SakuraBuckets {
    $buckets = Get-ChildItem -Path $Script:SakuraBuckets -Directory -ErrorAction SilentlyContinue
    if ($buckets.Count -eq 0) {
        Write-SakuraInfo "No buckets added. Use: sakura bucket add <name>"
        return
    }

    Write-Host ""
    Write-Host "  Available Buckets:" -ForegroundColor Cyan
    Write-Host "  ------------------" -ForegroundColor DarkGray
    foreach ($bucket in $buckets) {
        $bucketDir = Join-Path $bucket.FullName "bucket"
        $manifestCount = 0
        if (Test-Path $bucketDir) {
            $manifestCount = (Get-ChildItem -Path $bucketDir -Filter "*.json" -ErrorAction SilentlyContinue).Count
        }
        $defaultMarker = ""
        $config = Get-SakuraConfigObj
        if ($config.default_bucket -eq $bucket.Name) { $defaultMarker = " (default)" }
        Write-Host "    $($bucket.Name) [$manifestCount apps]$defaultMarker" -ForegroundColor White
    }
    Write-Host ""
}

function Add-SakuraBucket {
    param(
        [string]$Name,
        [string]$Url = ""
    )

    $bucketPath = Join-Path $Script:SakuraBuckets $Name
    if (Test-Path $bucketPath) {
        Write-SakuraWarning "Bucket '$Name' already exists."
        return
    }

    Write-SakuraProgress "Adding bucket: $Name"

    $knownBuckets = @{
        "community" = "https://github.com/838288383838383/sakura-community-bucket.git"
        "nonportable" = "https://github.com/838288383838383/sakura-nonportable-bucket.git"
        "wsl" = "https://github.com/838288383838383/sakura-wsl-bucket.git"
    }

    if (-not $Url -and $knownBuckets.ContainsKey($Name)) {
        $Url = $knownBuckets[$Name]
    }

    if ($Url) {
        Write-SakuraProgress "Cloning from: $Url"
        try {
            $ProgressPreference = 'SilentlyContinue'
            git clone $Url $bucketPath 2>&1
            if (-not (Test-Path $bucketPath)) {
                Write-SakuraError "Failed to clone bucket."
                return
            }
            $bucketDir = Join-Path $bucketPath "bucket"
            $manifestCount = 0
            if (Test-Path $bucketDir) {
                $manifestCount = (Get-ChildItem -Path $bucketDir -Filter "*.json" -ErrorAction SilentlyContinue).Count
            }
            Write-SakuraSuccess "Bucket '$Name' added with $manifestCount packages."
        } catch {
            Write-SakuraError "Failed to clone bucket: $_"
            return
        }
    } else {
        New-Item -ItemType Directory -Path "$bucketPath\bucket" -Force | Out-Null
        Write-SakuraSuccess "Bucket '$Name' created locally."
    }
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
        $bucketDir = Join-Path $bucket.FullName "bucket"
        if (-not (Test-Path $bucketDir)) { continue }
        $manifests = Get-ChildItem -Path $bucketDir -Filter "*.json" -ErrorAction SilentlyContinue
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
