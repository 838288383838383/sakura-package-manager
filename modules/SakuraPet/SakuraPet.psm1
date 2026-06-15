# Sakura Pet Module - Built-in Tamagotchi System
# Your digital companion that grows as you use Sakura!

$Script:PetDataPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "pet"

# Pet species and evolution stages
$Script:PetSpecies = @{
    "sakura-spirit" = @{
        name = "Sakura Spirit"
        stages = @(
            @{ name = "bud";       min_level = 1;  max_level = 5;  art = @(
                "    /\_/\\  ",
                "   ( o.o ) ",
                "   > ^ <   ",
                "  /|   |\\ ",
                " (_|   |_)"
            )}
            @{ name = "sprout";    min_level = 6;  max_level = 15; art = @(
                "    @     ",
                "    |\\    ",
                "   /||\\  ",
                "  / |||\\ ",
                "    |||   ",
                "    |||   ",
                "   /|||\\ ",
                "  /_|||_\\"
            )}
            @{ name = "sapling";   min_level = 16; max_level = 30; art = @(
                "   @@@   ",
                "  @|||@  ",
                "   \\|/    ",
                "    |     ",
                "    |     ",
                "   /|\\   ",
                "  / || \\ ",
                "   /|||\\ ",
                "  |_|||_| "
            )}
            @{ name = "blossom";   min_level = 31; max_level = 50; art = @(
                "  @@@@  ",
                " @@@@@@ ",
                "  \\@@@/  ",
                "   \\|@|/  ",
                "    \\| |/  ",
                "     \\|/   ",
                "      |    ",
                "     /|\\   ",
                "    / || \\ ",
                "   /_|||_\\ "
            )}
            @{ name = "elder";     min_level = 51; max_level = 999; art = @(
                " * @ * @ *",
                " @@@@@@@@ ",
                "@@@@@@@@@@",
                "  \\@@@/   ",
                "   \\|@|/   ",
                "    \\| |/   ",
                "     \\|/    ",
                "      |     ",
                "     /|\\    ",
                "    / || \\   ",
                "   /_|||_\\  "
            )}
        )
    }
}

# Mood states
$Script:PetMoods = @{
    "ecstatic"  = @{ emoji = ":D"; message = "is over the moon!"; color = "Yellow" }
    "happy"     = @{ emoji = ":)"; message = "feels wonderful!"; color = "Green" }
    "content"   = @{ emoji = ":|"; message = "feels content."; color = "Cyan" }
    "neutral"   = @{ emoji = "-";  message = "feels okay."; color = "White" }
    "bored"     = @{ emoji = ":/"; message = "wants attention..."; color = "DarkYellow" }
    "sad"       = @{ emoji = ":("; message = "feels lonely."; color = "DarkCyan" }
    "hungry"    = @{ emoji = "D:"; message = "is starving!"; color = "DarkRed" }
    "tired"     = @{ emoji = "zZ"; message = "needs rest..."; color = "DarkGray" }
    "sick"      = @{ emoji = "~_~"; message = "doesn't feel well..."; color = "DarkMagenta" }
}

# Achievements
$Script:Achievements = @{
    "first_install"   = @{ name = "First Steps";       desc = "Install your first app";      icon = "[1st]" }
    "ten_installs"    = @{ name = "Collector";          desc = "Install 10 apps";             icon = "[10]" }
    "hundred_installs"= @{ name = "Package Master";    desc = "Install 100 apps";            icon = "[100]" }
    "first_evolution" = @{ name = "Growing Up";         desc = "Evolve your pet once";        icon = "[Evo]" }
    "five_evolutions" = @{ name = "Ancient One";        desc = "Evolve 5 times";              icon = "[Anc]" }
    "daily_user"      = @{ name = "Daily Devotee";     desc = "Use Sakura 7 days in a row";  icon = "[Day]" }
    "night_owl"       = @{ name = "Night Owl";         desc = "Install an app after midnight";icon = "[Owl]" }
    "early_bird"      = @{ name = "Early Bird";         desc = "Install an app before 7 AM";  icon = "[Brd]" }
    "max_happiness"   = @{ name = "Pure Joy";           desc = "Reach max happiness";         icon = "[Joy]" }
    "first_pet"       = @{ name = "Animal Lover";       desc = "Pet your companion";          icon = "[Pet]" }
    "hungry_master"   = @{ name = "Master Feeder";      desc = "Feed 50 times";               icon = "[Fdr]" }
    "playful"         = @{ name = "Playtime!";           desc = "Play 50 times";               icon = "[Ply]" }
}

function Get-PetFilePath {
    return Join-Path $Script:PetDataPath "pet.json"
}

function Get-PetData {
    $petFile = Get-PetFilePath
    if (Test-Path $petFile) {
        $content = Get-Content -Path $petFile -Raw -Encoding UTF8
        return $content | ConvertFrom-Json
    }
    return $null
}

function Save-PetData {
    param([PSCustomObject]$PetData)
    $petFile = Get-PetFilePath
    $json = $PetData | ConvertTo-Json -Depth 10
    Set-Content -Path $petFile -Value $json -Encoding UTF8
}

function Update-PetMood {
    param([PSCustomObject]$Pet)

    # Calculate mood based on stats
    $score = 0
    $score += $Pet.happiness / 10
    $score += $Pet.hunger / 10
    $score += $Pet.energy / 10
    $score += $Pet.health / 10

    # Time since last interaction
    $lastInteraction = [DateTime]::Parse($Pet.last_interaction)
    $hoursSince = ((Get-Date) - $lastInteraction).TotalHours

    if ($hoursSince -gt 24) { $score -= 20 }
    elseif ($hoursSince -gt 12) { $score -= 10 }
    elseif ($hoursSince -gt 6) { $score -= 5 }

    # Determine mood
    if ($Pet.health -lt 20) { $Pet.mood = "sick" }
    elseif ($Pet.hunger -lt 10) { $Pet.mood = "hungry" }
    elseif ($Pet.energy -lt 10) { $Pet.mood = "tired" }
    elseif ($score -ge 35) { $Pet.mood = "ecstatic" }
    elseif ($score -ge 28) { $Pet.mood = "happy" }
    elseif ($score -ge 22) { $Pet.mood = "content" }
    elseif ($score -ge 15) { $Pet.mood = "neutral" }
    elseif ($score -ge 8) { $Pet.mood = "bored" }
    else { $Pet.mood = "sad" }

    return $Pet
}

function Update-PetStats {
    param([PSCustomObject]$Pet)

    $now = Get-Date

    # Hunger decreases over time
    $lastFed = [DateTime]::Parse($Pet.last_fed)
    $hoursSinceFed = ($now - $lastFed).TotalHours
    $Pet.hunger = [Math]::Max(0, $Pet.hunger - [Math]::Floor($hoursSinceFed * 2))

    # Energy regenerates when not playing
    $lastPlayed = [DateTime]::Parse($Pet.last_played)
    $hoursSincePlayed = ($now - $lastPlayed).TotalHours
    if ($hoursSincePlayed -gt 1) {
        $Pet.energy = [Math]::Min(100, $Pet.energy + [Math]::Floor($hoursSincePlayed * 5))
    }

    # Happiness decreases over time without interaction
    $lastInteraction = [DateTime]::Parse($Pet.last_interaction)
    $hoursSinceInteraction = ($now - $lastInteraction).TotalHours
    $Pet.happiness = [Math]::Max(0, $Pet.happiness - [Math]::Floor($hoursSinceInteraction))

    # Health affected by other stats
    if ($Pet.hunger -lt 10) { $Pet.health = [Math]::Max(0, $Pet.health - 1) }
    if ($Pet.energy -lt 10) { $Pet.health = [Math]::Max(0, $Pet.health - 1) }
    if ($Pet.hunger -gt 80 -and $Pet.energy -gt 80) {
        $Pet.health = [Math]::Min(100, $Pet.health + 1)
    }

    # Cleanliness decreases over time
    $Pet.cleanliness = [Math]::Max(0, $Pet.cleanliness - 1)

    $Pet = Update-PetMood -Pet $Pet
    return $Pet
}

function Get-PetStage {
    param([PSCustomObject]$Pet)

    $species = $Script:PetSpecies[$Pet.species]
    if (-not $species) { return "unknown" }

    foreach ($stage in $species.stages) {
        if ($Pet.level -ge $stage.min_level -and $Pet.level -le $stage.max_level) {
            return $stage
        }
    }
    return $species.stages[-1]
}

function Show-Pet {
    $pet = Get-PetData
    if (-not $pet) {
        Write-SakuraError "No pet found. Try restarting Sakura."
        return
    }

    $pet = Update-PetStats -Pet $pet
    $stage = Get-PetStage -Pet $pet
    $mood = $Script:PetMoods[$pet.mood]

    Save-PetData -PetData $pet

    Write-Host ""
    Write-Host "  +-----------------------------------------------+" -ForegroundColor Magenta
    Write-Host "  |          Your Digital Companion               |" -ForegroundColor Magenta
    Write-Host "  +-----------------------------------------------+" -ForegroundColor Magenta
    Write-Host "  |                                               |" -ForegroundColor Magenta

    # Draw pet art
    foreach ($line in $stage.art) {
        $padding = ' ' * [Math]::Max(0, 43 - $line.Length)
        Write-Host "  |  $line$padding|" -ForegroundColor Magenta
    }

    Write-Host "  |                                               |" -ForegroundColor Magenta
    Write-Host "  +-----------------------------------------------+" -ForegroundColor Magenta
    Write-Host "  |  Name:       $($pet.name.PadRight(30)) |" -ForegroundColor White
    Write-Host "  |  Species:    $($pet.species.PadRight(30)) |" -ForegroundColor White
    Write-Host "  |  Stage:      $($stage.name.PadRight(30)) |" -ForegroundColor White
    Write-Host "  |  Level:      $($pet.level.ToString().PadRight(30)) |" -ForegroundColor Yellow
    Write-Host "  |  Mood:       $($mood.emoji) $($pet.mood.PadRight(28)) |" -ForegroundColor $mood.color
    Write-Host "  +-----------------------------------------------+" -ForegroundColor Magenta
    Write-Host "  |  EXP:        $($pet.experience)/$($pet.exp_to_next)$(' ' * [Math]::Max(0, 28 - $pet.experience.ToString().Length - $pet.exp_to_next.ToString().Length))|" -ForegroundColor Cyan
    Write-Host "  |  Hunger:     $(Get-StatBar $pet.hunger) $(($pet.hunger).ToString().PadRight(3))% |" -ForegroundColor $(if ($pet.hunger -lt 30) { "Red" } else { "Green" })
    Write-Host "  |  Energy:     $(Get-StatBar $pet.energy) $(($pet.energy).ToString().PadRight(3))% |" -ForegroundColor $(if ($pet.energy -lt 30) { "Red" } else { "Yellow" })
    Write-Host "  |  Happiness:  $(Get-StatBar $pet.happiness) $(($pet.happiness).ToString().PadRight(3))% |" -ForegroundColor $(if ($pet.happiness -lt 30) { "Red" } else { "Magenta" })
    Write-Host "  |  Clean:      $(Get-StatBar $pet.cleanliness) $(($pet.cleanliness).ToString().PadRight(3))% |" -ForegroundColor $(if ($pet.cleanliness -lt 30) { "Red" } else { "Cyan" })
    Write-Host "  |  Health:     $(Get-StatBar $pet.health) $(($pet.health).ToString().PadRight(3))% |" -ForegroundColor $(if ($pet.health -lt 30) { "Red" } else { "Green" })
    Write-Host "  +-----------------------------------------------+" -ForegroundColor Magenta
    Write-Host "  |  $($mood.message.PadRight(43))|" -ForegroundColor $mood.color
    Write-Host "  +-----------------------------------------------+" -ForegroundColor Magenta
    Write-Host ""

    # Show stats
    Write-Host "  Lifetime Stats:" -ForegroundColor Cyan
    Write-Host "    Apps Installed:    $($pet.total_installs)" -ForegroundColor White
    Write-Host "    Apps Updated:      $($pet.total_updates)" -ForegroundColor White
    Write-Host "    Searches Made:     $($pet.total_searches)" -ForegroundColor White
    Write-Host "    Evolutions:        $($pet.evolution_count)" -ForegroundColor White
    Write-Host "    Achievements:      $($pet.achievements.Count)/$($Script:Achievements.Count)" -ForegroundColor White
    Write-Host ""

    # Show achievements if any
    if ($pet.achievements.Count -gt 0) {
        Write-Host "  Recent Achievements:" -ForegroundColor Yellow
        $recentAch = $pet.achievements | Select-Object -Last 3
        foreach ($ach in $recentAch) {
            $achData = $Script:Achievements[$ach]
            if ($achData) {
                Write-Host "    $($achData.icon) $($achData.name) - $($achData.desc)" -ForegroundColor Yellow
            }
        }
        Write-Host ""
    }

    # Show commands
    Write-Host "  Commands:" -ForegroundColor DarkGray
    Write-Host "    sakura pet feed  - Feed your pet" -ForegroundColor DarkGray
    Write-Host "    sakura pet play  - Play with your pet" -ForegroundColor DarkGray
    Write-Host "    sakura pet pet   - Pet your companion" -ForegroundColor DarkGray
    Write-Host "    sakura pet nap   - Let your pet nap" -ForegroundColor DarkGray
    Write-Host "    sakura pet evolve - Check evolution progress" -ForegroundColor DarkGray
    Write-Host ""
}

function Get-StatBar {
    param([int]$Percent)

    $filled = [Math]::Floor($Percent / 10)
    $empty = 10 - $filled
    return ("|" * $filled) + ("." * $empty)
}

function Feed-Pet {
    $pet = Get-PetData
    if (-not $pet) { return }

    if ($pet.hunger -ge 100) {
        Write-Host ""
        Write-Host "  $($pet.name) is already full!" -ForegroundColor Cyan
        Write-Host ""
        return
    }

    $pet.hunger = [Math]::Min(100, $pet.hunger + 25)
    $pet.health = [Math]::Min(100, $pet.health + 2)
    $pet.last_fed = (Get-Date).ToString("o")
    $pet.last_interaction = (Get-Date).ToString("o")
    $pet = Update-PetMood -Pet $pet

    Add-PetExperience -Amount 5 -Reason "Fed pet"

    Write-Host ""
    Write-Host "  Feeding $($pet.name)..." -ForegroundColor Green
    Write-Host "  $($pet.name) says: 'Yummy! Thank you!'" -ForegroundColor Magenta
    Write-Host ""

    Save-PetData -PetData $pet
}

function Play-Pet {
    $pet = Get-PetData
    if (-not $pet) { return }

    if ($pet.energy -lt 15) {
        Write-Host ""
        Write-Host "  $($pet.name) is too tired to play..." -ForegroundColor Yellow
        Write-Host "  Try letting them nap first with: sakura pet nap" -ForegroundColor DarkGray
        Write-Host ""
        return
    }

    $pet.energy = [Math]::Max(0, $pet.energy - 15)
    $pet.happiness = [Math]::Min(100, $pet.happiness + 20)
    $pet.cleanliness = [Math]::Max(0, $pet.cleanliness - 5)
    $pet.last_played = (Get-Date).ToString("o")
    $pet.last_interaction = (Get-Date).ToString("o")
    $pet = Update-PetMood -Pet $pet

    Add-PetExperience -Amount 10 -Reason "Played with pet"

    # Random play events
    $events = @(
        "chased a butterfly!",
        "found a shiny coin!",
        "played peekaboo!",
        "did a little dance!",
        "found a pretty flower!",
        "played hide and seek!",
        "made a new friend!"
    )
    $event = $events | Get-Random

    Write-Host ""
    Write-Host "  Playing with $($pet.name)..." -ForegroundColor Cyan
    Write-Host "  $($pet.name) $event" -ForegroundColor Magenta
    Write-Host "  Happiness +20, Energy -15" -ForegroundColor DarkGray
    Write-Host ""

    Save-PetData -PetData $pet
}

function Pet-Pet {
    $pet = Get-PetData
    if (-not $pet) { return }

    $pet.happiness = [Math]::Min(100, $pet.happiness + 10)
    $pet.cleanliness = [Math]::Min(100, $pet.cleanliness + 5)
    $pet.last_interaction = (Get-Date).ToString("o")
    $pet = Update-PetMood -Pet $pet

    Add-PetExperience -Amount 5 -Reason "Petted companion"

    # Check for first pet achievement
    if (-not ($pet.achievements -contains "first_pet")) {
        $pet.achievements += "first_pet"
        Write-Host ""
        Write-Host "  Achievement Unlocked: Animal Lover!" -ForegroundColor Yellow
        Write-Host ""
    }

    Write-Host ""
    Write-Host "  Petting $($pet.name)..." -ForegroundColor Magenta
    Write-Host "  $($pet.name) purrs happily!" -ForegroundColor Magenta
    Write-Host "  Happiness +10, Cleanliness +5" -ForegroundColor DarkGray
    Write-Host ""

    Save-PetData -PetData $pet
}

function Nap-Pet {
    $pet = Get-PetData
    if (-not $pet) { return }

    $pet.energy = [Math]::Min(100, $pet.energy + 40)
    $pet.health = [Math]::Min(100, $pet.health + 5)
    $pet.last_interaction = (Get-Date).ToString("o")
    $pet = Update-PetMood -Pet $pet

    Write-Host ""
    Write-Host "  $($pet.name) takes a nap..." -ForegroundColor Yellow
    Write-Host "  Zzz... Energy +40, Health +5" -ForegroundColor DarkGray
    Write-Host "  $($pet.name) feels refreshed!" -ForegroundColor Magenta
    Write-Host ""

    Save-PetData -PetData $pet
}

function Show-PetEvolution {
    $pet = Get-PetData
    if (-not $pet) { return }

    $species = $Script:PetSpecies[$pet.species]
    $currentStage = Get-PetStage -Pet $pet
    $nextStage = $null

    foreach ($stage in $species.stages) {
        if ($stage.min_level -gt $currentStage.max_level) {
            $nextStage = $stage
            break
        }
    }

    Write-Host ""
    Write-Host "  Evolution Progress" -ForegroundColor Magenta
    Write-Host "  ==================" -ForegroundColor DarkGray
    Write-Host "  Current Stage: $($currentStage.name)" -ForegroundColor White
    Write-Host "  Level:         $($pet.level)/$($currentStage.max_level)" -ForegroundColor Yellow
    Write-Host "  Experience:    $($pet.experience)/$($pet.exp_to_next)" -ForegroundColor Cyan

    if ($nextStage) {
        $progress = [Math]::Floor(($pet.level - $currentStage.min_level) / ($nextStage.min_level - $currentStage.min_level) * 100)
        Write-Host "  Next Stage:    $($nextStage.name) (Level $($nextStage.min_level))" -ForegroundColor DarkGray
        Write-Host "  Progress:      $(Get-StatBar $progress) $progress%" -ForegroundColor Magenta
    } else {
        Write-Host "  You've reached the final evolution!" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  All Stages:" -ForegroundColor Cyan
    foreach ($stage in $species.stages) {
        $marker = if ($stage.name -eq $currentStage.name) { "<-- You are here" } else { "" }
        $color = if ($stage.name -eq $currentStage.name) { "Green" } else { "DarkGray" }
        Write-Host "    Lv $($stage.min_level.ToString().PadRight(3))- $($stage.max_level.ToString().PadRight(3)): $($stage.name) $marker" -ForegroundColor $color
    }
    Write-Host ""
}

function Add-PetExperience {
    param(
        [int]$Amount,
        [string]$Reason
    )

    $pet = Get-PetData
    if (-not $pet) { return }

    $pet.experience += $Amount
    $pet.last_interaction = (Get-Date).ToString("o")

    # Level up check
    $leveledUp = $false
    while ($pet.experience -ge $pet.exp_to_next) {
        $pet.experience -= $pet.exp_to_next
        $pet.level++
        $pet.exp_to_next = [Math]::Floor(100 * [Math]::Pow(1.2, $pet.level - 1))
        $leveledUp = $true

        # Update stats on level up
        $pet.hunger = [Math]::Min(100, $pet.hunger + 10)
        $pet.energy = [Math]::Min(100, $pet.energy + 10)
        $pet.happiness = [Math]::Min(100, $pet.happiness + 15)
        $pet.health = [Math]::Min(100, $pet.health + 5)
    }

    # Check for evolution
    $oldStage = Get-PetStage -Pet $pet
    $species = $Script:PetSpecies[$pet.species]
    $newStage = $null
    foreach ($stage in $species.stages) {
        if ($pet.level -ge $stage.min_level -and $pet.level -le $stage.max_level) {
            $newStage = $stage
            break
        }
    }

    if ($newStage -and $oldStage.name -ne $newStage.name) {
        $pet.evolution_count++
        Write-Host ""
        Write-Host "  EVOLUTION!" -ForegroundColor Yellow
        Write-Host "  $($pet.name) evolved from $($oldStage.name) to $($newStage.name)!" -ForegroundColor Magenta
        Write-Host ""

        # Check evolution achievements
        if ($pet.evolution_count -eq 1 -and -not ($pet.achievements -contains "first_evolution")) {
            $pet.achievements += "first_evolution"
            Write-Host "  Achievement Unlocked: Growing Up!" -ForegroundColor Yellow
        }
        if ($pet.evolution_count -ge 5 -and -not ($pet.achievements -contains "five_evolutions")) {
            $pet.achievements += "five_evolutions"
            Write-Host "  Achievement Unlocked: Ancient One!" -ForegroundColor Yellow
        }
    }

    # Update stats
    if ($Reason -like "*Installed*") { $pet.total_installs++ }
    if ($Reason -like "*Updated*") { $pet.total_updates++ }
    if ($Reason -like "*Searched*") { $pet.total_searches++ }

    # Check achievements
    if ($pet.total_installs -eq 1 -and -not ($pet.achievements -contains "first_install")) {
        $pet.achievements += "first_install"
        Write-Host "  Achievement Unlocked: First Steps!" -ForegroundColor Yellow
    }
    if ($pet.total_installs -ge 10 -and -not ($pet.achievements -contains "ten_installs")) {
        $pet.achievements += "ten_installs"
        Write-Host "  Achievement Unlocked: Collector!" -ForegroundColor Yellow
    }
    if ($pet.total_installs -ge 100 -and -not ($pet.achievements -contains "hundred_installs")) {
        $pet.achievements += "hundred_installs"
        Write-Host "  Achievement Unlocked: Package Master!" -ForegroundColor Yellow
    }
    if ($pet.happiness -ge 100 -and -not ($pet.achievements -contains "max_happiness")) {
        $pet.achievements += "max_happiness"
        Write-Host "  Achievement Unlocked: Pure Joy!" -ForegroundColor Yellow
    }

    # Time-based achievements
    $hour = (Get-Date).Hour
    if ($hour -lt 7 -and -not ($pet.achievements -contains "early_bird")) {
        $pet.achievements += "early_bird"
        Write-Host "  Achievement Unlocked: Early Bird!" -ForegroundColor Yellow
    }
    if ($hour -ge 0 -and $hour -lt 5 -and -not ($pet.achievements -contains "night_owl")) {
        $pet.achievements += "night_owl"
        Write-Host "  Achievement Unlocked: Night Owl!" -ForegroundColor Yellow
    }

    if ($leveledUp) {
        Write-Host ""
        Write-Host "  Level Up! $($pet.name) is now Level $($pet.level)!" -ForegroundColor Yellow
        Write-Host ""
    }

    Save-PetData -PetData $pet
}
