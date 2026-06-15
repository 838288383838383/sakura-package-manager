# Sakura Dependency Resolution System

function Resolve-Dependencies {
    param(
        [PSCustomObject]$Manifest,
        [System.Collections.Generic.HashSet[string]]$Visited = $null
    )

    if ($Visited -eq $null) {
        $Visited = [System.Collections.Generic.HashSet[string]]::new()
    }

    $deps = @()

    if ($Manifest.dependencies) {
        foreach ($dep in $Manifest.dependencies) {
            $depName = if ($dep -is [string]) { $dep } else { $dep.name }

            if (-not $Visited.Contains($depName)) {
                $Visited.Add($depName) | Out-Null
                $deps += $depName

                # Recursively resolve sub-dependencies
                $depManifest = Get-SakuraManifest -AppName $depName
                if ($depManifest) {
                    $subDeps = Resolve-Dependencies -Manifest $depManifest -Visited $Visited
                    $deps += $subDeps
                }
            }
        }
    }

    return $deps
}

function Test-CircularDependencies {
    param(
        [string]$AppName,
        [System.Collections.Generic.List[string]]$Chain
    )

    if ($Chain -contains $AppName) {
        return $true  # Circular dependency found
    }

    $Chain.Add($AppName)

    $manifest = Get-SakuraManifest -AppName $AppName
    if ($manifest -and $manifest.dependencies) {
        foreach ($dep in $manifest.dependencies) {
            $depName = if ($dep -is [string]) { $dep } else { $dep.name }
            $newChain = [System.Collections.Generic.List[string]]::new($Chain)
            if (Test-CircularDependencies -AppName $depName -Chain $newChain) {
                return $true
            }
        }
    }

    return $false
}

function Show-DependencyTree {
    param(
        [string]$AppName,
        [int]$Depth = 0,
        [System.Collections.Generic.HashSet[string]]$Visited = $null
    )

    if ($Visited -eq $null) {
        $Visited = [System.Collections.Generic.HashSet[string]]::new()
    }

    $indent = "    " * $Depth
    $marker = if ($Depth -eq 0) { "" } else { "|-- " }

    if ($Visited.Contains($AppName)) {
        Write-Host "$indent$marker$AppName (already shown)" -ForegroundColor DarkGray
        return
    }

    $Visited.Add($AppName) | Out-Null

    $installed = Test-Path (Join-Path $Script:SakuraApps $AppName)
    $status = if ($installed) { "[OK]" } else { "[--]" }
    $color = if ($installed) { "Green" } else { "Red" }

    Write-Host "$indent$marker$status $AppName" -ForegroundColor $color

    $manifest = Get-SakuraManifest -AppName $AppName
    if ($manifest -and $manifest.dependencies) {
        foreach ($dep in $manifest.dependencies) {
            $depName = if ($dep -is [string]) { $dep } else { $dep.name }
            Show-DependencyTree -AppName $depName -Depth ($Depth + 1) -Visited $Visited
        }
    }
}
