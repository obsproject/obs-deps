param(
    [string] $Name = 'lame',
    [string] $Version = '3.100',
    [string] $Uri = 'https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz',
    [string] $Hash = "${PSScriptRoot}/checksums/lame-3.100.tar.gz.win.sha256",
    [array] $Targets = @('x64', 'arm64'),
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

    Get-ChildItem -Recurse -Include 'lame.exe','mp3x.exe','mp3rtp.exe' | Remove-Item
    Get-ChildItem -Recurse -Include 'libmp3lame.*','libmp3lame-static.lib','lame_enc.dll' | Remove-Item
    Get-ChildItem -Recurse -Include 'lame.pdb','icl.pch' | Remove-Item
    Get-ChildItem -Recurse -Include '*.obj','*.res' | Remove-Item
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
        arm64 = 'arm64'
    }

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "."
        BuildCommand = "nmake -f Makefile.MSVC MACHINE=/machine:$($BuildMachines[$Target]) MMX=NO COMP=MS ASM=NO MSVCVER=Win64"
        Target = $Target
    }

    if ( $Target -eq 'x86' ) {
        $Params += @{
            HostArchitecture = $Target
        }
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
