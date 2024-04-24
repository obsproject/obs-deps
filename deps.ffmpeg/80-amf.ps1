param(
    [string] $Name = 'amf',
    [string] $Version = '1.4.33',
    [string] $Uri = 'https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git',
    [string] $Hash = 'e8c7cd7c10d4e05c1913aa8dfd2be9f9dbdb03d6'
)

function Setup {
    Log-Information "Setup (${Target})"

    New-Item -Path $Path -ItemType Directory -Force *> $null

    Invoke-GitCheckout $Uri $Hash -Sparse -SparseArgs set,amf/public/include
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    New-Item -Path "$($ConfigData.OutputPath)/include/AMF" -ItemType Directory -Force *> $null

    $Items = @(
        @{
            Path = "amf/public/include/*"
            Destination = "$($ConfigData.OutputPath)/include/AMF/"
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
