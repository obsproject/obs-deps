param(
    [string] $Name = 'freetype',
    [string] $Version = '2.10.4',
    [string] $Uri = 'https://github.com/freetype/freetype.git',
    [string] $Hash = '6a2b3e4007e794bfc6c91030d0ed987f925164a8'
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
        "-DBUILD_SHARED_LIBS=$($OnOff[$script:Shared.isPresent])"
        '-DFT_WITH_BROTLI=OFF'
        '-DFT_WITH_BZIP2=OFF'
        '-DFT_WITH_HARFBUZZ=OFF'
        '-DFT_WITH_PNG=OFF'
        '-DFT_WITH_ZLIB=OFF'
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
