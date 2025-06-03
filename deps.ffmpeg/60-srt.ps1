param(
    [string] $Name = 'srt',
    [string] $Version = '1.5.2',
    [string] $Uri = 'https://github.com/Haivision/srt/archive/refs/tags/v1.5.2.zip',
    [string] $Hash = "${PSScriptRoot}/checksums/v1.5.2.zip.sha256",
    [switch] $ForceShared = $true
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
