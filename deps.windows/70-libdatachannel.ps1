param(
    [string] $Name = 'libdatachannel',
    [string] $Version = '0.18.3',
    [string] $Uri = 'https://github.com/Sean-Der/libdatachannel.git',
    [string] $Hash = 'bffcbeec9db0ba3f1493e0cf1398aa153b8a6682'
)

function Setup {
    Invoke-GitCheckout -Uri $Uri -Commit $Hash
}

function Clean {
    Set-Location $Path

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Patch {
    Log-Information "Patch (${Target})"
    Set-Location $Path

    $Patches | ForEach-Object {
        $Params = $_
        Safe-Patch @Params
    }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

    $Options = @(
        $CmakeOptions
        '-DUSE_MBEDTLS=1'
        '-DNO_WEBSOCKET=1'
        '-DNO_TESTS=1'
        '-DNO_EXAMPLES=1'
        '-DUSE_SYSTEM_MBEDTLS=1'
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
