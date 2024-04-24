param(
    [string] $Name = 'vpl',
    [string] $Version = 'v2.10.2',
    [string] $Uri = 'https://github.com/intel/libvpl.git',
    [string] $Hash = '383b5caac6df614e76ade5a07c4f53be702e9176',
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
        '-DBUILD_DISPATCHER_ONLY:BOOL=ON'
        '-DBUILD_EXAMPLES:BOOL=OFF'
        '-DBUILD_DISPATCHER_ONEVPL_EXPERIMENTAL:BOOL=OFF'
        "-DBUILD_SHARED_LIBS:BOOL=$($OnOff[$Shared])"
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

    $Params = @{
        ErrorAction = "SilentlyContinue"
        Path = @(
            "$($ConfigData.OutputPath)/lib"
            "$($ConfigData.OutputPath)/include"
        )
        ItemType = "Directory"
        Force = $true
    }

    New-Item @Params *> $null

    $Items = @(
        @{
            Path = "api/vpl"
            Destination = "$($ConfigData.OutputPath)/include"
            Recurse = $true
            ErrorAction = 'SilentlyContinue'
        }
        @{
            Path = "build_${Target}/$Configuration/vpl.lib"
            Destination = "$($ConfigData.OutputPath)/lib"
            ErrorAction = 'SilentlyContinue'
        }
        @{
            Path = "build_${Target}/$Configuration/vpld.lib"
            Destination = "$($ConfigData.OutputPath)/lib"
            ErrorAction = 'SilentlyContinue'
        }
    )

    $Items | ForEach-Object {
        $Item = $_
        Log-Output ('{0} => {1}' -f ($Item.Path -join ", "), $Item.Destination)
        Copy-Item @Item
    }
}
