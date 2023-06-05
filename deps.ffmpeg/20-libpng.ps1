param(
    [string] $Name = 'libpng',
    [string] $Version = '1.6.43',
    [string] $Uri = 'https://sourceforge.net/projects/libpng/files/libpng16/1.6.43/lpng1643.zip',
    [string] $Hash = "${PSScriptRoot}/checksums/lpng1643.zip.sha256",
    [array] $Targets = @('x64', 'arm64'),
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/libpng/0001-enable-ARM-NEON-optimisations-windows.patch"
            HashSum = "6d84fe660b89a4841a67e8167172af2dcc72cef7a1f9bfec981fc84fc7421dd8"
        }
    )
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath .
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
        '-DPNG_TESTS:BOOL=OFF'
        '-DPNG_STATIC:BOOL=ON'
        "-DPNG_SHARED:BOOL=$($OnOff[$script:Shared.isPresent])"
    )

    if ( $Target -eq 'arm64' ) {
        $Options += @(
            '-DCMAKE_ASM_FLAGS="-DPNG_ARM_NEON_IMPLEMENTATION=1'
            '-DPNG_ARM_NEON=on'
        )
    }

    if ( $Configuration -eq 'Debug' ) {
        $Options += '-DPNG_DEBUG:BOOL=ON'
    } else {
        $Options += '-DPNG_DEBUG:BOOL=OFF'
    }

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
