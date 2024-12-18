param(
    [string] $Name = 'zlib',
    [string] $Version = '1.3.1',
    [string] $Uri = 'https://github.com/madler/zlib.git',
    [string] $Hash = "51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf",
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/zlib/0001-fix-unistd-detection.patch"
            HashSum = "2114ff9ebfc79765019353b06915a09f4dc4802ce722d2df6e640a59666dd875"
        }
    ),
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
        '-DZ_HAVE_UNISTD_H:BOOL=OFF'
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
