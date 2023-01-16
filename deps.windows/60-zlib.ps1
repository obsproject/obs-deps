param(
    [string] $Name = 'zlib',
    [string] $Version = '1.2.12',
    [string] $Uri = 'https://github.com/madler/zlib.git',
    [string] $Hash = '21767c654d31d2dccdde4330529775c6c5fd5389'
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
        '-DBUILD_SHARED_LIBS=$($OnOff[$script:Shared.isPresent])'
        '-DCMAKE_C_FLAGS_RELEASE="/MT"'
        '-DCMAKE_C_FLAGS_RELWITHDEBINFO="/MT"'
        '-DCMAKE_C_FLAGS_DEBUG="/MTd"'
    )
    Log-Information "Shared: $($OnOff[$script:Shared.isPresent])"

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
