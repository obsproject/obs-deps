param(
    [string] $Name = 'bison',
    [string] $Version = '2.4.1',
    [string] $Uri = 'http://downloads.sourceforge.net/gnuwin32/bison-2.4.1-dep.zip',
    [string] $Hash = "${PSScriptRoot}/checksums/bison-2.4.1-dep.zip.sha256"
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    New-Item -Path "$($ConfigData.OutputPath)/bin" -ItemType Directory -Force *> $null

    $Items = @(
        @{
            Path = './bin/*.dll'
            Destination = "$($ConfigData.OutputPath)/bin/"
            ErrorAction = 'SilentlyContinue'
            Recurse = $true
        }
    )

    $Items | ForEach-Object {
        $Item = $_
        Log-Output ('{0} => {1}' -f ($Item.Path -join ", "), $Item.Destination)
        Copy-Item @Item
    }
}
