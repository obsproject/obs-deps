param(
    [string] $Name = 'mbedtls',
    [string] $Version = '3.2.1',
    [string] $Uri = 'https://github.com/Mbed-TLS/mbedtls.git',
    [string] $Hash = '869298bffeea13b205343361b7a7daf2b210e33d',
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/mbedtls/0001-enable-alt-threading-mode.patch"
            HashSum = "64e8d40a6be9721108220e667ac61c9219335be0a3f2c438c2e17a35a1b74109"
        }
        @{
            PatchFile = "${PSScriptRoot}/patches/mbedtls/0002-add-alt-threading-header-file.patch"
            HashSum = "1c42a3bd74ada543f8852ccf8e55f482022f08d3888e0b5d0d101ab0beff409d"
        }
        @{
            PatchFile = "${PSScriptRoot}/patches/mbedtls/0003-enable-dtls-srtp-support.patch"
            HashSum = "6bc1af2b09800e99279f1cc462d9c58a0cf850da541072c7b43b6b5aac57f09e"
        }
    ),
    [switch] $Shared = $false
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

    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
        "-DUSE_SHARED_MBEDTLS_LIBRARY=$($OnOff[$Shared.isPresent])"
        '-DUSE_STATIC_MBEDTLS_LIBRARY=ON'
        '-DENABLE_PROGRAMS=OFF'
        '-DENABLE_TESTING=OFF'
        '-DLIB_INSTALL_DIR=bin'
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
    )

    if ( $Configuration -match "(Release|MinSizeRel)" ) {
        $Options += '--strip'
    }

    Invoke-External cmake @Options
}
