param(
    [string] $Name = 'carla',
    [string] $Version = '2.6.0-alpha1',
    [string] $Uri = 'https://github.com/falkTX/Carla.git',
    [string] $Hash = 'cb7f1a975790dda458481e88de0a29c433b706c9'
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Clean {
    Set-Location $Path

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

    $Options = @(
        $CmakeOptions
        '-DCARLA_USE_JACK:BOOL=OFF'
        '-DCARLA_USE_OSC:BOOL=OFF'
    )

    Invoke-External cmake -S cmake -B "build_${Target}" @Options
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    $Options = @(
        '--build', "build_${Target}"
        '--config', $Configuration
    )

    if ( $VerbosePreference -eq 'Continue' ) {
        $Options += '--verbose'
    }

    Invoke-External cmake @Options
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    $Options = @(
        '--install', "build_${Target}"
        '--config', $Configuration
    )

    if ( $Configuration -match "(Release|MinSizeRel)" ) {
        $Options += '--strip'
    }

    Invoke-External cmake @Options
}

function Fixup {
    Log-Information "Fixup (${Target})"
    Set-Location $Path

    Remove-Item -ErrorAction 'SilentlyContinue' "$($ConfigData.OutputPath)/bin/libcarla_native-plugin.dll"
    Remove-Item -ErrorAction 'SilentlyContinue' "$($ConfigData.OutputPath)/bin/libcarla_standalone2.dll"

    Remove-Item -ErrorAction 'SilentlyContinue' "$($ConfigData.OutputPath)/lib/libcarla_native-plugin.lib"
    Remove-Item -ErrorAction 'SilentlyContinue' "$($ConfigData.OutputPath)/lib/libcarla_standalone2.lib"
}
