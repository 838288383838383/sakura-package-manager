# Build all Sakura distros as WSL rootfs tarballs
# Requires Docker

$distros = @("ubuntu-sakura", "arch-sakura", "fedora-sakura", "alpine-sakura", "debian-sakura", "void-sakura")

foreach ($distro in $distros) {
    Write-Host ""
    Write-Host "  🌸 Building $distro..." -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor DarkGray

    $buildDir = Join-Path $PSScriptRoot $distro

    if (-not (Test-Path "$buildDir\Dockerfile")) {
        Write-Host "  [SKIP] No Dockerfile found" -ForegroundColor Yellow
        continue
    }

    try {
        # Build Docker image
        Write-Host "  Building Docker image..." -ForegroundColor Cyan
        docker build -t "sakura-$distro" $buildDir

        # Export to tarball
        Write-Host "  Exporting rootfs..." -ForegroundColor Cyan
        $containerId = docker create "sakura-$distro"
        $tarPath = Join-Path $PSScriptRoot "$distro.tar.gz"
        docker export $containerId | gzip -c > $tarPath
        docker rm $containerId | Out-Null

        Write-Host "  ✅ Built: $tarPath" -ForegroundColor Green
        Write-Host "  Size: $([Math]::Round((Get-Item $tarPath).Length / 1MB, 2)) MB" -ForegroundColor DarkGray
    } catch {
        Write-Host "  [ERR] Build failed: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  🌸 All builds complete!" -ForegroundColor Magenta
