# Sakura Search System

function Show-SakuraInstalled {
    $apps = Get-ChildItem -Path $Script:SakuraApps -Directory -ErrorAction SilentlyContinue
    if ($apps.Count -eq 0) {
        Write-SakuraInfo "No apps installed. Use: sakura install <app>"
        return
    }
    Write-Host ""
    Write-Host "  Installed Apps:" -ForegroundColor Cyan
    Write-Host "  ----------------" -ForegroundColor DarkGray
    foreach ($app in $apps) {
        $manifest = Get-InstalledManifest -AppName $app.Name
        $ver = if ($manifest -and $manifest.version) { $manifest.version } else { "?" }
        Write-Host "    $($app.Name) v$ver" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "  Total: $($apps.Count) app(s)" -ForegroundColor DarkGray
    Write-Host ""
}

function Search-SakuraPackages {
    param([string]$Query)

    Write-Host ""
    Write-Host "  Searching for: $Query" -ForegroundColor Cyan
    Write-Host "  ---------------------" -ForegroundColor DarkGray

    $results = Search-SakuraBuckets -Query $Query

    if ($results.Count -eq 0) {
        Write-SakuraInfo "No packages found matching '$Query'."
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "    Name          Bucket          Version   Description" -ForegroundColor Yellow
    Write-Host "    ----          ------          -------   -----------" -ForegroundColor DarkGray

    foreach ($result in $results) {
        $name = $result.Name.PadRight(14)
        $bucket = $result.Bucket.PadRight(16)
        $version = $result.Version.PadRight(10)
        $desc = if ($result.Description.Length -gt 40) {
            $result.Description.Substring(0, 37) + "..."
        } else {
            $result.Description
        }
        Write-Host "    $name$bucket$version$desc" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "  Found $($results.Count) result(s)." -ForegroundColor DarkGray
    Write-Host "  Install with: sakura install <name> [-viab <bucket>]" -ForegroundColor DarkGray
    Write-Host ""

    # Update pet
    Add-PetExperience -Amount 2 -Reason "Searched for packages"
}

function Show-SakuraAppInfo {
    param([string]$Name)

    $manifest = Get-SakuraManifest -AppName $Name
    if (-not $manifest) {
        Write-SakuraError "App '$Name' not found."
        return
    }

    $installed = Test-Path (Join-Path $Script:SakuraApps $Name)
    $installedVersion = ""
    if ($installed) {
        $installedManifest = Get-InstalledManifest -AppName $Name
        if ($installedManifest) { $installedVersion = $installedManifest.version }
    }

    Write-Host ""
    Write-Host "  $($manifest.name)" -ForegroundColor Magenta
    Write-Host "  ========================================" -ForegroundColor DarkGray
    Write-Host "  Version:       $($manifest.version)" -ForegroundColor White
    Write-Host "  Description:   $($manifest.description)" -ForegroundColor White
    if ($manifest.homepage) {
        Write-Host "  Homepage:      $($manifest.homepage)" -ForegroundColor White
    }
    if ($manifest.license) {
        Write-Host "  License:       $($manifest.license)" -ForegroundColor White
    }
    Write-Host "  Installed:     $installed" -ForegroundColor $(if ($installed) { "Green" } else { "Gray" })
    if ($installed) {
        Write-Host "  Installed Ver: $installedVersion" -ForegroundColor White
    }
    Write-Host ""
}
