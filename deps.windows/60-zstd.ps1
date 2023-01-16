param(
    [string] $Name = 'zstd',
    [string] $Version = 'v1.5.2',
    [string] $Uri = 'https://github.com/facebook/zstd.git',
    [string] $Hash = 'e47e674cd09583ff0503f0f6defd6d23d8b718d3'
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
        '-DZSTD_BUILD_PROGRAMS=OFF'
        '-DZSTD_BUILD_TESTS=OFF'
        '-DZSTD_BUILD_SHARED=OFF'
        '-DZSTD_USE_STATIC_RUNTIME=ON'
        '-DZSTD_LEGACY_SUPPORT=OFF'
    )

    Invoke-External cmake -S build/cmake -B "build_${Target}" @Options
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
