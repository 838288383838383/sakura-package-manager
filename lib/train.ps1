# Sakura Train - Built-in Steam Locomotive
# Port of the classic Linux 'sl' command
# Type 'sl' instead of 'ls' and get a train!

function Invoke-SakuraTrain {
    param(
        [switch]$F,
        [switch]$L,
        [switch]$A,
        [switch]$W
    )

    $train = @(
        "                                        (@@)               (@@)               (@@)"
        "                                       (@@)             (@@@)             (@@@)"
        "                                     (@@@)            (@@@@@)           (@@@@@)"
        "                                    (@@@@)           (@@@@@@@)         (@@@@@@@)"
        "                                   (@@@@@)          (@@@@@@@@@)       (@@@@@@@@@)"
        "                                  (@@@@@@@)        (@@@@@@@@@@@)     (@@@@@@@@@@@)"
        "                                 (@@@@@@@@@)      (@@@@@@@@@@@@@)   (@@@@@@@@@@@@@)"
        "                                (@@@@@@@@@@@)    (@@@@@@@@@@@@@@@) (@@@@@@@@@@@@@@@)"
        "                                (@@@@@@@@@@@)   (@@@@@@@@@@@@@@@@@)(@@@@@@@@@@@@@@@)"
        "                               (@@@@@@@@@@@@@) (@@@@@@@@@@@@@@@@@@)(@@@@@@@@@@@@@@@)"
        "  _  _  _  _  _  _  _  _  _  _ (_@@@@@@@@@@@@@)(@@@@@@@@@@@@@@@@@)(@@@@@@@@@@@@@@@)"
        "  |/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|/ \|"
        "  ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^ ^^"
        "  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  ="
    )

    $width = $Host.UI.RawUI.WindowSize.Width
    $height = $Host.UI.RawUI.WindowSize.Height

    # Animate the train
    for ($pos = -$train[0].Length; $pos -lt ($width + 20); $pos += 2) {
        Clear-Host

        # Draw train
        for ($i = 0; $i -lt $train.Count; $i++) {
            $y = [Math]::Min($height - 3, 5 + $i)
            $x = [Math]::Max(0, $pos)
            if ($y -ge 0 -and $y -lt $height -and $x -lt $width) {
                $line = $train[$i]
                if ($x + $line.Length -gt $width) {
                    $line = $line.Substring(0, [Math]::Max(0, $width - $x))
                }
                Write-Host -NoNewline ("`e[{0};{1}H" -f $y, $x) -ForegroundColor Yellow
                Write-Host -NoNewline $line -ForegroundColor Yellow
            }
        }

        Start-Sleep -Milliseconds 50
    }

    # Final message
    Write-Host ""
    Write-Host "  Choo choo! You meant 'ls' not 'sl'!" -ForegroundColor Yellow
    Write-Host ""
}

function Show-SakuraTrainHelp {
    Write-Host ""
    Write-Host "  Sakura Train - Built-in Steam Locomotive" -ForegroundColor Yellow
    Write-Host "  =========================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Usage: sl [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Options:" -ForegroundColor White
    Write-Host "    -F    Fly! The train flies across the screen" -ForegroundColor DarkGray
    Write-Host "    -L    Show a big locomotive" -ForegroundColor DarkGray
    Write-Host "    -A    Show all (locomotive + cars)" -ForegroundColor DarkGray
    Write-Host "    -W    Show warning" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Tip: Type 'sl' instead of 'ls' and see what happens!" -ForegroundColor Magenta
    Write-Host ""
}
