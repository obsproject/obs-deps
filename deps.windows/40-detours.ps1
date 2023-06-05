param(
    [string] $Name = 'detours',
    [string] $Version = '4.0.1',
    [string] $Uri = 'https://github.com/microsoft/detours.git',
    [hashtable] $Hashes = @{
        x86 = 'e4bfd6b03e50de46b47abfbd1e46b384f0c5f833'
        x64 = 'e4bfd6b03e50de46b47abfbd1e46b384f0c5f833'
        arm64 = '734ac64899c44933151c1335f6ef54a590219221'
    }
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path -Branch main
}

function Clean {
    Set-Location $Path

    $Items = @(
        @{ErrorAction = "SilentlyContinue"; Path = "lib.$($Target.ToUpper())"}
        @{ErrorAction = "SilentlyContinue"; Path = "bin.$($Target.ToUpper())"}
        @{ErrorAction = "SilentlyContinue"; Path = "src/obj.$($Target.ToUpper())"}
    )

    $Items | ForEach-Object {
        $Item = $_
        Log-Information "Clean $($Item.Path) (${Target})"
        Get-ChildItem @Item | Remove-Item -Recurse
    }
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "src"
        BuildCommand = "nmake"
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
    Set-Location $Path

    $Params = @{
        ErrorAction = "SilentlyContinue"
        Path = @(
            "$($ConfigData.OutputPath)/bin"
            "$($ConfigData.OutputPath)/lib"
            "$($ConfigData.OutputPath)/include"
        )
        ItemType = "Directory"
        Force = $true
    }

    New-Item @Params *> $null

    $Items = @(
        @{
            Path = "include/detours.h"
            Destination = "$($ConfigData.OutputPath)/include/detours.h"
            Force = $true
        }
        @{
            Path = "lib.$($Target.ToUpper())/detours.lib"
            Destination = "$($ConfigData.OutputPath)/lib/detours.lib"
            Force = $true
        }
    )

    if ( $Configuration -match "(Debug|RelWithDebInfo)" ) {
        $Items += @{
            Path = "lib.$($Target.ToUpper())/detours.pdb"
            Destination = "$($ConfigData.OutputPath)/bin/detours.pdb"
            Force = $true
        }
    }

    $Items | ForEach-Object {
        $Item = $_
        Log-Output ('{0} => {1}' -f $Item.Path, $Item.Destination)
        Copy-Item @Item
    }
}
