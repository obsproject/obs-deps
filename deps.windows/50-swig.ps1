param(
    [string] $Name = 'swig',
    [string] $Version = '4.1.1',
    [string] $Uri = 'https://github.com/swig/swig.git',
    [string] $Hash = "c85e7f1625f8b421c92b8c1a8279d134ba050ecc",
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/swig/0001-add-Python-3-stable-abi.patch"
            HashSum = '4a2d8a3180127f2b72c4484fb0f421a6edacc7636243857e721d23a2bfc5bb13'
        },
        @{
            PatchFile = "${PSScriptRoot}/patches/swig/0002-remove-PCRE-cmake-finder.patch"
            HashSum = 'fc11c4493bf8857a38bd52e76586112a95c286a9059d84216c3e963d3cf103b3'
        }
    )
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Clean {
    Set-Location $Path

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Patch {
    Log-Information "Patch (${Target})"
    Set-Location $Path

    $Patches | ForEach-Object {
        $Params = $_
        Safe-Patch @Params
    }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

    $Options = $CmakeOptions

    Invoke-External cmake -S . -B "build_${Target}" @Options

    if ( $env:M4 -eq '' ) {
        $env:M4 = "$($ConfigData.OutputPath)/bin/m4.exe"
    }
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    $Options = @(
        '--build', "build_${Target}"
        '--config', $Configuration
    )

    if ( $VerbosePreference -eq 'Continue' ) {
        $Options += '--verbose'
    }

    Invoke-External cmake @Options
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    $Options = @(
        '--install', "build_${Target}"
        '--config', $Configuration
        '--prefix', "$($ConfigData.OutputPath)/swig"
    )

    if ( $Configuration -match "(Release|MinSizeRel)" ) {
        $Options += '--strip'
    }

    Invoke-External cmake @Options
}

function Fixup {
    Log-Information "Fixup (${Target})"

    $Items = @(
        @{
            Path = "$($ConfigData.OutputPath)/swig/bin/swig.exe"
            Destination = "$($ConfigData.OutputPath)/swig/swig.exe"
            Force = $true
        }
    )

    if ( $Version -le '4.1.0' ) {
        $Items += @{
            Path = "$($ConfigData.OutputPath)/swig/share/swig/${Version}"
            Destination = "$($ConfigData.OutputPath)/swig/Lib"
            Force = $true
        }
    } else {
        $Items += @{
            Path = "$($ConfigData.OutputPath)/swig/bin/Lib"
            Destination = "$($ConfigData.OutputPath)/swig/Lib"
            Force = $true
        }
    }

    $Items | ForEach-Object {
        $Item = $_
        Log-Status ('{0} => {1}' -f $Item.Path, $Item.Destination)
        Move-Item @Item
    }

    Remove-Item "$($ConfigData.OutputPath)/swig/share" -Recurse -ErrorAction 'SilentlyContinue'
    Remove-Item "$($ConfigData.OutputPath)/swig/bin" -Recurse -ErrorAction 'SilentlyContinue'
}
