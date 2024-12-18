param(
    [string] $Name = 'srt',
    [string] $Version = '1.5.4',
    [string] $Uri = 'https://github.com/Haivision/srt/archive/refs/tags/v1.5.4.zip',
    [string] $Hash = "${PSScriptRoot}/checksums/v1.5.4.zip.sha256",
    [array] $Targets = @('x64', 'arm64'),
    [switch] $ForceShared = $true,
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/srt/0002-update-mbedtls-discovery-windows.patch"
            HashSum = "c6b236a15e36767cc516c626c410be42b9ff05bd42338c194e1cf6247e4cbdc5"
        }
    )
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath .
}

function Clean {
    Set-Location "${Name}-${Version}"

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Patch {
    Log-Information "Patch (${Target})"
    Set-Location "${Name}-${Version}"

    $Patches | ForEach-Object {
        $Params = $_
        Safe-Patch @Params
    }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location "${Name}-${Version}"

   if ( $ForceShared -and ( $script:Shared -eq $false ) ) {
        $Shared = $true
    } else {
        $Shared = $script:Shared.isPresent
    }

    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
        "-DENABLE_SHARED:BOOL=$($OnOff[$Shared])"
        '-DENABLE_STATIC:BOOL=ON'
        '-DENABLE_APPS:BOOL=OFF'
        '-DUSE_ENCLIB:STRING=mbedtls'
    )

    Invoke-External cmake -S . -B "build_${Target}" @Options
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location "${Name}-${Version}"

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
    Set-Location "${Name}-${Version}"

    $Options = @(
        '--install', "build_${Target}"
        '--config', $Configuration
    )

    if ( $Configuration -match "(Release|MinSizeRel)" ) {
        $Options += '--strip'
    }

    Invoke-External cmake @Options
}
