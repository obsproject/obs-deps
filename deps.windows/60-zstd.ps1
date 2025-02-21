param(
    [string] $Name = 'zstd',
    [string] $Version = 'v1.5.7',
    [string] $Uri = 'https://github.com/facebook/zstd.git',
    [string] $Hash = 'f8745da6ff1ad1e7bab384bd1f9d742439278e99',
    [array] $Targets = @('x64', 'arm64')
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
        '-DZSTD_BUILD_PROGRAMS:BOOL=OFF'
        '-DZSTD_BUILD_TESTS:BOOL=OFF'
        '-DZSTD_BUILD_SHARED:BOOL=OFF'
        '-DZSTD_USE_STATIC_RUNTIME:BOOL=ON'
        '-DZSTD_LEGACY_SUPPORT:BOOL=OFF'
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
