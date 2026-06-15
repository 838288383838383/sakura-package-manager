# Sakura Search System

function Search-SakuraPackages {
    param([string]$Query)

    Write-Host ""
    Write-Host "  Searching for: $Query" -ForegroundColor Cyan
    Write-Host "  ─────────────────────" -ForegroundColor DarkGray

    $results = Search-SakuraBuckets -Query $Query

    if ($results.Count -eq 0) {
        Write-SakuraInfo "No packages found matching '$Query'."
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "    Name        Version   Description" -ForegroundColor Yellow
    Write-Host "    ────        ───────   ───────────" -ForegroundColor DarkGray

    foreach ($result in $results) {
        $name = $result.Name.PadRight(13)
        $version = $result.Version.PadRight(10)
        $desc = if ($result.Description.Length -gt 50) {
            $result.Description.Substring(0, 47) + "..."
        } else {
            $result.Description
        }
        Write-Host "    $name$version$desc" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "  Found $($results.Count) result(s). Use 'sakura install <name>' to install." -ForegroundColor DarkGray
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
    Write-Host "  ════════════════════════════════════════" -ForegroundColor DarkGray
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
