param(
    [string] $Name = 'freetype',
    [string] $Version = '2.13.0',
    [string] $Uri = 'https://github.com/freetype/freetype.git',
    [string] $Hash = 'de8b92dd7ec634e9e2b25ef534c54a3537555c11'
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

    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
        "-DBUILD_SHARED_LIBS:BOOL=$($OnOff[$script:Shared.isPresent])"
        '-DFT_DISABLE_BROTLI:BOOL=ON'
        '-DFT_DISABLE_BZIP2:BOOL=ON'
        '-DFT_DISABLE_HARFBUZZ:BOOL=ON'
        '-DFT_DISABLE_PNG:BOOL=ON'
        '-DFT_DISABLE_ZLIB:BOOL=ON'
    )

    Invoke-External cmake -S . -B "build_${Target}" @Options
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
