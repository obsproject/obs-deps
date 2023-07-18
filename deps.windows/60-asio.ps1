param(
    [string] $Name = 'asio',
    [string] $Version = '1.28.0',
    [string] $Uri = 'https://github.com/chriskohlhoff/asio.git',
    [string] $Hash = "c465349fa5cd91a64bb369f5131ceacab2c0c1c3"
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
