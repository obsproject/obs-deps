param(
    [string] $Name = 'uthash',
    [string] $Version = '2.3.0',
    [string] $Uri = 'https://github.com/troydhanson/uthash.git',
    [string] $Hash = "e493aa90a2833b4655927598f169c31cfcdf7861",
    [array] $Targets = @('x64', 'arm64')
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location "$Path"

    New-Item -Path "$($ConfigData.OutputPath)/include" -ItemType Directory -Force *> $null

    $Items = @(
        @{
            Path = @("src/utarray.h", "src/uthash.h", "src/utlist.h", "src/utringbuffer.h", "src/utstack.h", "src/utstring.h")
            Destination = "$($ConfigData.OutputPath)/include"
            ErrorAction = 'SilentlyContinue'
        }
    )

    $Items | ForEach-Object {
        $Item = $_
        Log-Output ('{0} => {1}' -f ($Item.Path -join ", "), $Item.Destination)
        Copy-Item @Item
    }
}
