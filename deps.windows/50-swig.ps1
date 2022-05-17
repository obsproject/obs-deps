param(
    [string] $Name = 'swig',
    [string] $Version = '3.0.12',
    [string] $Uri = 'https://downloads.sourceforge.net/project/swig/swigwin/swigwin-3.0.12/swigwin-3.0.12.zip',
    [string] $Hash = "${PSScriptRoot}/checksums/swigwin-3.0.12.zip.sha256"
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    Remove-Item "swigwin-${Version}/Examples", "swigwin-${Version}/Doc" -Recurse -Force -ErrorAction 'SilentlyContinue'

    New-Item -Path "$($ConfigData.OutputPath)/swig" -ItemType Directory -Force *> $null

    $Items = @(
        @{
            Path = "swigwin-${Version}/*"
            Destination = "$($ConfigData.OutputPath)/swig"
            ErrorAction = "SilentlyContinue"
            Recurse = $true
        }
    )

    $Items | ForEach-Object {
        $Item = $_
        Log-Output ('{0} => {1}' -f ($Item.Path -join ", "), $Item.Destination)
        Copy-Item @Item
    }
}
