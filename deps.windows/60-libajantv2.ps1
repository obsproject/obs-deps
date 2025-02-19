param(
    [string] $Name = 'ntv2',
    [string] $Version = '17.1.3',
    [string] $Uri = 'https://github.com/aja-video/libajantv2.git',
    [string] $Hash = 'bf5649fc95c9d40cb6028373630f2805109268e4',
    [array] $Targets = @('x64'),
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
        "-DAJANTV2_BUILD_SHARED:BOOL=$($OnOff[$Shared])"
        '-DAJANTV2_DISABLE_DEMOS:BOOL=ON'
        '-DAJANTV2_DISABLE_DRIVER:BOOL=ON'
        '-DAJANTV2_DISABLE_TESTS:BOOL=ON'
        '-DAJANTV2_DISABLE_TOOLS:BOOL=ON'
        '-DAJANTV2_DISABLE_PLUGINS:BOOL=ON'
        '-DAJA_INSTALL_SOURCES:BOOL=OFF'
        '-DAJA_INSTALL_HEADERS:BOOL=ON'
        '-DAJA_INSTALL_MISC:BOOL=OFF'
        '-DAJA_INSTALL_CMAKE:BOOL=OFF'
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

function Fixup {
    Log-Information "Fixup (${Target})"
    Set-Location $Path

    $Params = @{
        ErrorAction = "SilentlyContinue"
        Path = @(
            "$($ConfigData.OutputPath)/bin"
            "$($ConfigData.OutputPath)/lib"
        )
        ItemType = "Directory"
        Force = $true
    }

    New-Item @Params *> $null

    $Items = @(
        @{
            Path = "$($ConfigData.OutputPath)/lib/ajantv2_vs[0-9]*_M[DT]$(if ( $Configuration -eq 'Debug' ) { 'd' }).lib"
            Destination = "$($ConfigData.OutputPath)/lib"
            Force = $true
        }
    )

    $Items | ForEach-Object {
        $Item = $_
        Log-Output ('{0} => {1}' -f ($Item.Path -join ", "), $Item.Destination)
        Move-Item @Item
    }
}
