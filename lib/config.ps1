# Sakura Configuration System

function Get-SakuraConfigObj {
    $configPath = Join-Path $Script:SakuraHome "config.json"
    if (Test-Path $configPath) {
        $content = Get-Content -Path $configPath -Raw -Encoding UTF8
        return $content | ConvertFrom-Json
    }
    return $null
}

function Save-SakuraConfigObj {
    param([PSCustomObject]$Config)

    $configPath = Join-Path $Script:SakuraHome "config.json"
    $json = $Config | ConvertTo-Json -Depth 10
    Set-Content -Path $configPath -Value $json -Encoding UTF8
}

function Get-SakuraConfig {
    param([string]$Key)

    $config = Get-SakuraConfigObj
    if ($config -and $config.PSObject.Properties[$Key]) {
        Write-Host "  $Key = $($config.$Key)" -ForegroundColor Cyan
    } else {
        Write-SakuraWarning "Config key '$Key' not found."
    }
}

function Set-SakuraConfig {
    param(
        [string]$Key,
        [string]$Value
    )

    $config = Get-SakuraConfigObj
    if (-not $config) {
        Write-SakuraError "Config not found."
        return
    }

    # Type coercion
    if ($Value -eq "true") { $Value = $true }
    elseif ($Value -eq "false") { $Value = $false }
    elseif ($Value -match '^\d+$') { $Value = [int]$Value }

    if ($config.PSObject.Properties[$Key]) {
        $config.$Key = $Value
    } else {
        $config | Add-Member -NotePropertyName $Key -NotePropertyValue $Value
    }

    Save-SakuraConfigObj -Config $config
    Write-SakuraSuccess "Config updated: $Key = $Value"
}

function Show-SakuraConfig {
    $config = Get-SakuraConfigObj
    if (-not $config) {
        Write-SakuraError "Config not found."
        return
    }

    Write-Host ""
    Write-Host "  Sakura Configuration:" -ForegroundColor Cyan
    Write-Host "  ----------------------" -ForegroundColor DarkGray
    foreach ($prop in $config.PSObject.Properties) {
        $value = $prop.Value
        if ($prop.Name -like "*token*" -or $prop.Name -like "*key*") {
            $value = "***"
        }
        Write-Host "    $($prop.Name) = $value" -ForegroundColor White
    }
    Write-Host ""
}
