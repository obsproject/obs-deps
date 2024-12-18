function Install-BuildDependencies {
    <#
        .SYNOPSIS
            Installs required build dependencies.
        .DESCRIPTION
            Additional packages might be needed for successful builds. This module contains additional
            dependencies available for installation via winget and, if possible, adds their locations
            to the environment path for future invocation.
        .EXAMPLE
            Install-BuildDependencies
    #>

    param(
        [string] $WingetFile = "$PSScriptRoot/.Wingetfile"
    )

    if ( ! ( Test-Path function:Log-Warning ) ) {
        . Logger.ps1
    }

    $Prefixes = @{
        'arm64' = ${env:ProgramFiles(arm)}
        'x64' = ${env:ProgramFiles}
        'x86' = ${env:ProgramFiles(x86)}
    }

    $Paths = $env:Path -split [System.IO.Path]::PathSeparator
    $Paths = $Paths | Get-Unique | Where-Object { ( ! ( $_ -match 'Strawberry' ) ) }

    $WingetOptions = @('install', '--accept-package-agreements', '--accept-source-agreements')

    if ( $script:Quiet ) {
        $WingetOptions += '--silent'
    }

    Get-Content $WingetFile | ForEach-Object {
        $PackageEntry = $_
        $_, $Package, $_, $Path, $_, $Binary, $_, $Version = $PackageEntry -replace ',','' -split " +(?=(?:[^\']*\'[^\']*\')*[^\']*$)" -replace "'",''

        if ( $Package -eq 'MSYS2.MSYS2' ) {
            if ( ( Test-Path "${Path}\${Binary}*" ) -and ! ( $Paths -contains $Path ) ) {
                $Paths = @($Path) + $Paths
            }
        } else {
            foreach($Prefix in $Prefixes.GetEnumerator()) {
                $FullPath = "$($Prefix.value)\${Path}"

                if ( ( Test-Path "${FullPath}\${Binary}*" ) -and ! ( $Paths -contains $FullPath ) ) {
                    $Paths = @($FullPath) + $Paths
                    break
                }
            }
        }

        $env:Path = $Paths -join [System.IO.Path]::PathSeparator

        Log-Debug "Checking for command ${Binary}"
        $Found = Get-Command -ErrorAction SilentlyContinue $Binary

        if ( $Found ) {
            Log-Status "Found dependency ${Binary} as $($Found.Source)"
        } else {
            Log-Status "Installing package ${Package}$(if ( $Version -ne $null ) { " Version: ${Version}" } )"

            if ( $Version -ne $null ) {
                $WingetOptions += '--version', ${Version}
            }

            try {
                if ( $env:CI -eq $null ) {
                    $Params = $WingetOptions + $Package

                    Invoke-External winget @Params
                } else {
                    if ( $Package -eq 'meson' ) {
                        python3 -m pip install meson
                    }
                }
            } catch {
                throw "Error while installing winget package ${Package}: $_"
            }
        }
    }

    $env:Path = $Paths -join [System.IO.Path]::PathSeparator
}
