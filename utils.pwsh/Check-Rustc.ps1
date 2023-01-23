function Check-Rustc {
    <#
        .SYNOPSIS
            Ensure available rustc environment on host system.
        .DESCRIPTION
            Checks whether required rustc command is available on the host system. If none is
            found, an error is emitted.
        .EXAMPLE
            Check-Rustc
    #>

    if ( ! ( Test-Path function:Log-Information ) ) {
        . $PSScriptRoot/Logger.ps1
    }

    if ( ! ( Test-Path function:Test-CommandExists ) ) {
        . $PSScriptRoot/Test-CommandExists.ps1
    }

    Log-Information 'Check for rustc executable'

    if ( ! ( Test-CommandExists rustc ) ) {
        if ( ! ( Test-Path function:Invoke-External ) ) {
            . $PSScriptRoot/Invoke-External.ps1
        }

        if ( $Env:CI ) {
            Log-Warning 'No rustc executable found. Installing rustup via Chocolatey'
            Invoke-External choco install rust
        } else {
            Log-Error 'No rustc executable found. Please install rust.'
        }
    } else {
        Log-Debug "rustc found at $(Get-Command rustc)"
        Log-Status 'rustc found'
    }
}
