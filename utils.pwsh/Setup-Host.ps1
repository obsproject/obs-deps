function Setup-Host {
    if ( ! ( Test-Path function:Log-Output ) ) {
        . $PSScriptRoot/Logger.ps1
    }

    if ( ! ( Test-Path function:Check-Git ) ) {
        . $PSScriptRoot/Check-Git.ps1
    }

    Check-Git

    if ( ! ( Test-Path function:Invoke-External ) ) {
        . $PSScriptRoot/Invoke-External.ps1
    }

    try {
        $script:ProjectRoot = Invoke-External git rev-parse --show-toplevel 2>$null
    } catch {
        Log-Warning "Not running in a git repository, interpreting project root instead"
        $script:ProjectRoot = $($script:PSScriptRoot)
    }

    $script:WorkRoot = "${ProjectRoot}\windows_build_temp"

    if ( ! ( $script:SkipAll ) && ( $script:SkipDeps ) ) {
        if ( ! ( Test-Path function:Install-BuildDependencies ) ) {
            . $PSScriptRoot/Install-BuildDependencies.ps1
        }

        Install-BuildDependencies -WingetFile ${script:PSScriptRoot}/.Wingetfile
        Invoke-External bash.exe -c "rm -rf /etc/pacman.d/gnupg; pacman-key --init && pacman-key --populate msys2"
        Invoke-External pacman.exe -S --sysupgrade --refresh --refresh --noconfirm --needed --noprogressbar
    }
}

function Cleanup {
    Log-Debug "Running Cleanup actions"
}

$script:HostArchitecture = ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture).ToString().ToLower()
