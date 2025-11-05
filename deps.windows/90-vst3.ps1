param(
    [string] $Name = 'vst3sdk',
    [string] $Version = 'v3.8.0',
    [string] $Uri = 'https://github.com/steinbergmedia/vst3sdk.git',
    [string] $Hash = '9fad9770f2ae8542ab1a548a68c1ad1ac690abe0',
    [array] $Targets = @('x64', 'arm64')
)

function Setup {
    Log-Information "Setup (${Target})"
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    $Params = @{
        ErrorAction = "SilentlyContinue"
        Path        = @(
            "$($ConfigData.OutputPath)/include",
            "$($ConfigData.OutputPath)/licenses"
        )
        ItemType    = "Directory"
        Force       = $true
    }
    New-Item @Params *> $null

    $Items = @(
        @{
            Path        = "base"
            Destination = "$($ConfigData.OutputPath)/include/vst3sdk/base"
            Recurse     = $true
            ErrorAction = 'SilentlyContinue'
        }
        @{
            Path        = "pluginterfaces"
            Destination = "$($ConfigData.OutputPath)/include/vst3sdk/pluginterfaces"
            Recurse     = $true
            ErrorAction = 'SilentlyContinue'
        }
        @{
            Path        = "public.sdk/source"
            Destination = "$($ConfigData.OutputPath)/include/vst3sdk/public.sdk/source"
            Recurse     = $true
            ErrorAction = 'SilentlyContinue'
        }
        @{
            Path        = "LICENSE.txt"
            Destination = "$($ConfigData.OutputPath)/licenses/vst3sdk"
            Force       = $true
            ErrorAction = 'SilentlyContinue'
        }
    )

    $Items | ForEach-Object {
        $Item = $_
        Log-Output ('{0} => {1}' -f ($Item.Path -join ", "), $Item.Destination)
        Copy-Item @Item
    }
}
