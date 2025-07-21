param(
    [string] $Name = 'amf',
    [string] $Version = '1.4.36',
    [string] $Uri = 'https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git',
    [string] $Hash = '16f7d73e0b45c473e903e46981ed0b91efc4c091',
    [array] $Targets = @('x64')
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
