param(
    [string] $Name = 'ducible',
    [string] $Version = 'v1.2.2',
    [string] $Uri = 'https://github.com/jasonwhite/ducible.git',
    [string] $Hash = 'b7810415529f801d98203cba00db969a6ef88a14',
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/ducible/0001-Remove-8.1-target-platform.patch"
            HashSum = 'f45851456fd93e4491e42f108ff19e60c0de3df35f1141208c95623edae14517'
        }
        @{
            PatchFile = "${PSScriptRoot}/patches/ducible/0002-Use-py-instead-of-python.patch"
            HashSum = '5922aa7639b2a364c0f90541dc15c05dc804ace9178a40a661d360bb961584c4'
        }
    )
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Patch {
    Log-Information "Patch (${Target})"
    Set-Location $Path

    $Patches | ForEach-Object {
        $Params = $_
        Safe-Patch @Params
    }
}

function Clean {
    Set-Location $Path

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    if ( $Configuration -match "Debug" ) {
        $DucibleConfig = 'Debug'
    } else {
        $DucibleConfig = 'Release'
    }

    if ( $Target -match "x64" ) {
        $DucibleTarget = 'x64'
    } else {
        $DucibleTarget = 'Win32'
    }

    $Options = @(
        '/t:Build'
        "/p:OutDir=.\..\..\..\build_${Target}\"
        "/p:Configuration=${DucibleConfig}"
        "/p:Platform=${DucibleTarget}"
        '/p:PlatformToolset=v143'
    )
    # Find MSBuild command
    $MSBUILD = &"${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe
    
    Invoke-External $MSBUILD -m vs\vs2015\ducible.sln @Options
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path
    
    $Params = @{
        ErrorAction = "SilentlyContinue"
        Path = @(
            "$($ConfigData.OutputPath)/bin"
        )
        ItemType = "Directory"
        Force = $true
    }

    New-Item @Params *> $null

    $Items = @(
        @{
            Path = "./build_${Target}/ducible.exe"
            Destination = "$($ConfigData.OutputPath)/bin/"
        }
        @{
            Path = "./build_${Target}/pdbdump.exe"
            Destination = "$($ConfigData.OutputPath)/bin/"
        }
        @{
            Path = "./build_${Target}/ducible.pdb"
            Destination = "$($ConfigData.OutputPath)/bin/"
        }
        @{
            Path = "./build_${Target}/pdbdump.pdb"
            Destination = "$($ConfigData.OutputPath)/bin/"
        }
    )

    $Items | ForEach-Object {
        $Item = $_
        Log-Status ('{0} => {1}' -f $Item.Path, $Item.Destination)
        Copy-Item @Item
    }
}
