param(
    [string] $Name = 'asio',
    [string] $Version = '1.29.0',
    [string] $Uri = 'https://github.com/chriskohlhoff/asio.git',
    [string] $Hash = "814f67e730e154547aea3f4d99f709cbdf1ea4a0"
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location "$Path/asio"

    New-Item -Path "$($ConfigData.OutputPath)/include" -ItemType Directory -Force *> $null

    $Items = @(
        @{
            Path = "include/asio.hpp"
            Destination = "$($ConfigData.OutputPath)/include"
            ErrorAction = 'SilentlyContinue'    
        }
        @{
            Path = "include/asio"
            Destination = "$($ConfigData.OutputPath)/include"
            Recurse = $true
            ErrorAction = 'SilentlyContinue'    
        }
    )

    $Items | ForEach-Object {
        $Item = $_
        Log-Output ('{0} => {1}' -f ($Item.Path -join ", "), $Item.Destination)
        Copy-Item @Item
    }
}
