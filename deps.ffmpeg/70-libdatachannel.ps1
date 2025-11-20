param(
    [string] $Name = 'libdatachannel',
    [string] $Version = 'v0.24.0',
    [string] $Uri = 'https://github.com/paullouisageneau/libdatachannel.git',
    [string] $Hash = '8c31097ea78f051e857d0aa1b2f6efb26cd12b7e',
    [array] $Targets = @('x64', 'arm64'),
    [switch] $ForceShared = $true
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

    if ( $ForceShared -and ( $script:Shared -eq $false ) ) {
        $Shared = $true
    } else {
        $Shared = $script:Shared.isPresent
    }

    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
        "-DBUILD_SHARED_LIBS:BOOL=$($OnOff[$Shared])"
        '-DUSE_MBEDTLS:BOOL=ON'
        '-DNO_WEBSOCKET:BOOL=ON'
        '-DNO_TESTS:BOOL=ON'
        '-DNO_EXAMPLES:BOOL=ON'
        '-DCMAKE_POLICY_VERSION_MINIMUM=3.5'
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

    $Options += @($CmakePostfix)

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
