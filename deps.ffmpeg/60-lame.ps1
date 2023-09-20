param(
    [string] $Name = 'lame',
    [string] $Version = '3.100',
    [string] $Uri = 'https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz',
    [string] $Hash = "${PSScriptRoot}/checksums/lame-3.100.tar.gz.win.sha256",
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/lame/0001-fix-nmake-64-bit-builds.patch"
            HashSum = "0772e07d3d0c484d281e3bfdb4f93e81adf303623fe57d955b98196795725f39"
        }
    )
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath .
    Invoke-External tar -xf "${Name}-${Version}.tar"
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

function Build {
    Log-Information "Build (${Target})"
    Set-Location "${Name}-${Version}"

    $BuildMachines = @{
        x64 = 'x64'
        x86 = 'I686'
    }

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "."
        BuildCommand = "nmake -f Makefile.MSVC MACHINE=/machine:$($BuildMachines[$Target]) COMP=MS ASM=NO MSVCVER=Win64"
        Target = $Target
        HostArchitecture = $Target
    }

    Invoke-DevShell @Params
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location "${Name}-${Version}"

    $Params = @{
        ErrorAction = "SilentlyContinue"
        Path = @(
            "$($ConfigData.OutputPath)/include/lame"
            "$($ConfigData.OutputPath)/lib"
        )
        ItemType = "Directory"
        Force = $true
    }

    New-Item @Params *> $null

    $Items = @(
        @{
            Path = "include/lame.h"
            Destination = "$($ConfigData.OutputPath)/include/lame"
            Recurse = $true
            Force = $true
        },
        @{
            Path = "output/libmp3lame-static.lib"
            Destination = "$($ConfigData.OutputPath)/lib/mp3lame.lib"
            Recurse = $true
            Force = $true
        }
    )

    $Items | ForEach-Object {
        $Item = $_
        Log-Output ('{0} => {1}' -f ($Item.Path -join ", "), $Item.Destination)
        Copy-Item @Item
    }
}
