param(
    [string] $Name = 'mbedtls',
    [string] $Version = '3.6.2',
    [string] $Uri = 'https://github.com/Mbed-TLS/mbedtls.git',
    [string] $Hash = '107ea89daaefb9867ea9121002fbbdf926780e98',
    [array] $Targets = @('x64', 'arm64'),
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/mbedtls/0001-enable-dtls-srtp-support-windows.patch"
            HashSum = "38dbaff859242c5a4f8196a08e35f0251d2966b22e1d9547ecaaea2aec4aae1b"
        }
    ),
    [switch] $ForceStatic = $true
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

    if ( $ForceStatic -and $script:Shared ) {
        $Shared = $false
    } else {
        $Shared = $script:Shared.isPresent
    }

    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
        "-DUSE_SHARED_MBEDTLS_LIBRARY:BOOL=$($OnOff[$Shared])"
        "-DUSE_STATIC_MBEDTLS_LIBRARY:BOOL=$($OnOff[$Shared -ne $true]))"
        '-DENABLE_PROGRAMS:BOOL=OFF'
        '-DENABLE_TESTING:BOOL=OFF'
        '-DGEN_FILES:BOOL=OFF'
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
