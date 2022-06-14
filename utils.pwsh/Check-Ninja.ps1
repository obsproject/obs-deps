function Check-Ninja {
    <#
        .SYNOPSIS
            Ensures available ninja executable on host system.
        .DESCRIPTION
            Checks whether a ninja command is available on the host system. If none is found,
            an error is emitted.
        .EXAMPLE
            Check-Ninja
    #>

    if ( ! ( Test-Path function:Log-Information ) ) {
        . $PSScriptRoot/Logger.ps1
    }

    if ( ! ( Test-Path function:Test-CommandExists ) ) {
        . $PSScriptRoot/Test-CommandExists.ps1
    }

    Log-Information 'Check for Ninja executable'

    if ( ! ( Test-CommandExists ninja ) ) {
        if ( ! ( Test-Path function:Invoke-External ) ) {
            . $PSScriptRoot/Invoke-External.ps1
        }

        if ( $Env:CI ) {
            Log-Warning 'No Ninja executable found. Installing Ninja via Chocolatey'
            Invoke-External choco install ninja
        } else {
            Log-Error 'No Ninja executable found. Please install Ninja.'
        }
    } else {
        Log-Debug "Ninja found at $(Get-Command ninja)"
        Log-Status "Ninja found"
    }
}
