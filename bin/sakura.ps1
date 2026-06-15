#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sakura Package Manager - Main CLI Entry Point
.DESCRIPTION
    A modern Windows package manager with built-in Tamagotchi pet.
    Install, update, and manage software with style.
.EXAMPLE
    sakura install git
    sakura pet
    sakura search vim
#>

param(
    [Parameter(Position=0)]
    [string]$Command,
    [Parameter(Position=1, ValueFromRemainingArguments)]
    [string[]]$Arguments
)

# Force bypass execution policy (like Scoop)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$ErrorActionPreference = "Stop"
$SakuraRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$SakuraVersion = "2.0.1"

# Load core libraries
. "$SakuraRoot\lib\core.ps1"
. "$SakuraRoot\lib\manifest.ps1"
. "$SakuraRoot\lib\bucket.ps1"
. "$SakuraRoot\lib\install.ps1"
. "$SakuraRoot\lib\shim.ps1"
. "$SakuraRoot\lib\config.ps1"
. "$SakuraRoot\lib\search.ps1"
. "$SakuraRoot\lib\update.ps1"
. "$SakuraRoot\lib\depends.ps1"
. "$SakuraRoot\lib\train.ps1"
. "$SakuraRoot\lib\wsl.ps1"

# Load pet module
Import-Module "$SakuraRoot\modules\SakuraPet\SakuraPet.psm1" -Force

# Initialize
Initialize-Sakura

# Show banner
function Show-Banner {
    Write-Host ""
    Write-Host "    =======================================" -ForegroundColor Magenta
    Write-Host "    |                                    |" -ForegroundColor Magenta
    Write-Host "    |    S A K U R A   P A C K A G E R    |" -ForegroundColor Magenta
    Write-Host "    |                                    |" -ForegroundColor Magenta
    Write-Host "    |    v$SakuraVersion - Blossom Edition       |" -ForegroundColor Magenta
    Write-Host "    |    Your friendly package manager    |" -ForegroundColor Magenta
    Write-Host "    |    with a digital friend inside     |" -ForegroundColor Magenta
    Write-Host "    |                                    |" -ForegroundColor Magenta
    Write-Host "    =======================================" -ForegroundColor Magenta
    Write-Host ""
}

function Show-Help {
    Show-Banner
    Write-Host "  Usage: sakura <command> [arguments]" -ForegroundColor Cyan
    Write-Host "         sak <command> [arguments]  (short alias)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Package Commands:" -ForegroundColor Yellow
    Write-Host "    install <app> [-viab <bucket>]  Install an app from a specific bucket"
    Write-Host "    uninstall <app>                Remove an application"
    Write-Host "    update [app]                   Update app(s) or all"
    Write-Host "    search <query>                 Search for applications"
    Write-Host "    list                           List installed apps"
    Write-Host "    info <app>                     Show app information"
    Write-Host "    upgrade                        Upgrade all apps"
    Write-Host ""
    Write-Host "  Self Update:" -ForegroundColor Yellow
    Write-Host "    updt                           Update Sakura itself"
    Write-Host "    update -sak                    Update Sakura (short form)"
    Write-Host ""
    Write-Host "  WSL Commands:" -ForegroundColor Yellow
    Write-Host "    wsl                            List installed WSL distros"
    Write-Host "    wsl launch <distro>            Launch a WSL distro"
    Write-Host "    wsl rm <distro>                Uninstall a WSL distro"
    Write-Host ""
    Write-Host "  Bucket Commands:" -ForegroundColor Yellow
    Write-Host "    bucket list                    List added buckets"
    Write-Host "    bucket add <name>              Add a bucket"
    Write-Host "    bucket rm <name>               Remove a bucket"
    Write-Host ""
    Write-Host "  Pet Commands:" -ForegroundColor Yellow
    Write-Host "    pet                            Interact with your pet"
    Write-Host "    pet feed/play/nap/pet          Pet interactions"
    Write-Host "    pet evolve                     Check evolution progress"
    Write-Host ""
    Write-Host "  Config Commands:" -ForegroundColor Yellow
    Write-Host "    config get/set/list            Manage configuration"
    Write-Host ""
    Write-Host "  Other:" -ForegroundColor Yellow
    Write-Host "    sl                 All aboard! Choo choo!"
    Write-Host "    version            Show version"
    Write-Host "    help               Show this help"
    Write-Host ""
    Write-Host "  Examples:" -ForegroundColor Cyan
    Write-Host "    sak install git                Install from best source"
    Write-Host "    sak install obsidian -viab nonportable  Install MSI/EXE version"
    Write-Host "    sak install vim -viab sakura-main       Force specific bucket"
    Write-Host ""
}

# Command routing
switch ($Command.ToLower()) {
    { $_ -in @("install", "i", "in") } {
        if ($Arguments.Count -eq 0) {
            Write-Host "Error: No app specified. Usage: sakura install <app>" -ForegroundColor Red
            exit 1
        }
        $appName = $null
        $fromBucket = ""
        for ($i = 0; $i -lt $Arguments.Count; $i++) {
            if ($Arguments[$i] -eq "-viab" -or $Arguments[$i] -eq "--via-bucket") {
                if ($i + 1 -lt $Arguments.Count) {
                    $fromBucket = $Arguments[$i + 1]
                    $i++
                } else {
                    Write-Host "Error: -viab requires a bucket name" -ForegroundColor Red
                    exit 1
                }
            } elseif (-not $Arguments[$i].StartsWith("-")) {
                $appName = $Arguments[$i]
            }
        }
        if (-not $appName) {
            Write-Host "Error: No app specified." -ForegroundColor Red
            exit 1
        }
        Install-SakuraApp -Name $appName -FromBucket $fromBucket
    }
    { $_ -in @("uninstall", "rm", "remove") } {
        if ($Arguments.Count -eq 0) {
            Write-Host "Error: No app specified. Usage: sakura uninstall <app>" -ForegroundColor Red
            exit 1
        }
        foreach ($app in $Arguments) {
            Uninstall-SakuraApp -Name $app
        }
    }
    { $_ -in @("update", "up") } {
        if ($Arguments -contains "-sak" -or $Arguments -contains "--self") {
            Update-SakuraSelf
        } elseif ($Arguments.Count -gt 0 -and $Arguments[0] -ne "-sak") {
            Update-SakuraPackages -Names $Arguments
        } else {
            Update-SakuraPackages -All
        }
    }
    { $_ -in @("updt", "selfupdate", "self-update") } {
        Update-SakuraSelf
    }
    { $_ -in @("upgrade", "ug") } {
        Update-SakuraPackages -All
    }
    { $_ -in @("search", "s", "find") } {
        $query = $Arguments -join " "
        Search-SakuraPackages -Query $query
    }
    { $_ -in @("list", "ls") } {
        Show-SakuraInstalled
    }
    { $_ -in @("info", "show") } {
        if ($Arguments.Count -eq 0) {
            Write-Host "Error: No app specified." -ForegroundColor Red
            exit 1
        }
        Show-SakuraAppInfo -Name $Arguments[0]
    }
    "bucket" {
        if ($Arguments.Count -eq 0) {
            Write-Host "Usage: sakura bucket <list|add|rm> [name]" -ForegroundColor Yellow
            exit 0
        }
        switch ($Arguments[0].ToLower()) {
            { $_ -in @("list", "ls") } { Show-SakuraBuckets }
            { $_ -in @("add", "a") } {
                if ($Arguments.Count -lt 2) {
                    Write-Host "Error: Bucket name required." -ForegroundColor Red
                    exit 1
                }
                Add-SakuraBucket -Name $Arguments[1]
            }
            { $_ -in @("rm", "remove", "delete") } {
                if ($Arguments.Count -lt 2) {
                    Write-Host "Error: Bucket name required." -ForegroundColor Red
                    exit 1
                }
                Remove-SakuraBucket -Name $Arguments[1]
            }
        }
    }
    "pet" {
        if ($Arguments.Count -eq 0) {
            Show-Pet
        } else {
            switch ($Arguments[0].ToLower()) {
                "status" { Show-Pet }
                "feed" { Feed-Pet }
                "play" { Play-Pet }
                "evolve" { Show-PetEvolution }
                "pet" { Pet-Pet }
                "nap" { Nap-Pet }
                default { Show-Pet }
            }
        }
    }
    "wsl" {
        if ($Arguments.Count -eq 0) {
            Show-WslDistros
        } else {
            switch ($Arguments[0].ToLower()) {
                { $_ -in @("list", "ls") } { Show-WslDistros }
                { $_ -in @("rm", "remove", "uninstall") } {
                    if ($Arguments.Count -lt 2) { Write-Host "Distro name required." -ForegroundColor Red; exit 1 }
                    Uninstall-WslDistro -DistroName $Arguments[1]
                }
                { $_ -in @("launch", "run", "open") } {
                    if ($Arguments.Count -lt 2) { Write-Host "Distro name required." -ForegroundColor Red; exit 1 }
                    wsl -d $Arguments[1]
                }
                default { Show-WslDistros }
            }
        }
    }
    { $_ -in @("config", "cfg", "c") } {
        if ($Arguments.Count -eq 0) {
            Write-Host "Usage: sakura config <get|set|list> [key] [value]" -ForegroundColor Yellow
            exit 0
        }
        switch ($Arguments[0].ToLower()) {
            "get" {
                if ($Arguments.Count -lt 2) { Write-Host "Key required." -ForegroundColor Red; exit 1 }
                Get-SakuraConfig -Key $Arguments[1]
            }
            "set" {
                if ($Arguments.Count -lt 3) { Write-Host "Key and value required." -ForegroundColor Red; exit 1 }
                Set-SakuraConfig -Key $Arguments[1] -Value $Arguments[2]
            }
            { $_ -in @("list", "ls") } { Show-SakuraConfig }
        }
    }
    { $_ -in @("version", "-v", "--version") } {
        Write-Host "Sakura Package Manager v$SakuraVersion (Blossom Edition)" -ForegroundColor Magenta
    }
    { $_ -in @("sl", "train", "choo") } {
        Invoke-SakuraTrain
    }
    { $_ -in @("help", "-h", "--help", $null, "") } {
        Show-Help
    }
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Write-Host "Run 'sakura help' for usage information." -ForegroundColor Yellow
        exit 1
    }
}
