param(
    [string] $Name = 'websocketpp',
    [string] $Version = '0.8.2',
    [string] $Uri = 'https://github.com/zaphoyd/websocketpp.git',
    [string] $Hash = '56123c87598f8b1dd471be83ca841ceae07f95ba',
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/websocketpp/0001-update-minimum-cmake.patch"
            HashSum = 'eddbee3dccbfee5909e26fa02d7c0f54d71318e92aacf0375eda379778b79bc3'
        }
    )
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

    $Options = @(
        $CmakeOptions
        '-DENABLE_CPP11:BOOL=ON'
        '-DBUILD_EXAMPLES:BOOL=OFF'
        '-DBUILD_TESTS:BOOL=OFF'
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
