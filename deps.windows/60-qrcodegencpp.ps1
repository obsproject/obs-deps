param(
    [string] $Name = 'qrcodegencpp',
    [string] $Version = '1.8.0',
    [string] $Uri = 'https://github.com/nayuki/QR-Code-generator.git',
    [string] $Hash = '720f62bddb7226106071d4728c292cb1df519ceb',
    [string] $UriCMake = 'https://github.com/EasyCoding/qrcodegen-cmake.git',
    [string] $HashCMake = '0bc38a5c3ce8bc700a7e1b3082a55b82e292530e',
    [array] $Targets = @('x64', 'arm64')
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath "$Path/src"
    Setup-Dependency -Uri $UriCMake -Hash $HashCMake -DestinationPath "$Path/qrcodegen-cmake"
}

function Clean {
    Set-Location "$Path/src"

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Patch {
    Log-Information "Patch (${Target})"
    Set-Location $Path

    $Items = @(
        @{
            Path = "qrcodegen-cmake/CMakeLists.txt"
            Destination = "src"
            ErrorAction = 'SilentlyContinue'    
        }
        @{
            Path = "qrcodegen-cmake/cmake"
            Destination = "src"
            Recurse = $true
            ErrorAction = 'SilentlyContinue'    
        }
    )

    $Items | ForEach-Object {
        $Item = $_
        Copy-Item @Item
    }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location "$Path/src"

    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
        '-DCMAKE_DEBUG_POSTFIX:STRING=d'
        "-DBUILD_SHARED_LIBS:BOOL=$($OnOff[$script:Shared.isPresent])"
    )

    Invoke-External cmake -S . -B "build_${Target}" @Options
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location "$Path/src"

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
    Set-Location "$Path/src"

    $Options = @(
        '--install', "build_${Target}"
        '--config', $Configuration
    )

    if ( $Configuration -match "(Release|MinSizeRel)" ) {
        $Options += '--strip'
    }

    Invoke-External cmake @Options
}

function Fixup {
    Log-Information "Fixup (${Target})"
    Set-Location $Path

    $Items = @(
        @{ FullPath = "$($ConfigData.OutputPath)/include/qrcodegen" }
        @{ FullPath = "$($ConfigData.OutputPath)/lib/cmake/qrcodegen" }
        @{ FullPath = "$($ConfigData.OutputPath)/lib/pkgconfig/qrcodegen.pc" }
        @{ FullPath = "$($ConfigData.OutputPath)/lib/qrcodegen.*" }
        @{ FullPath = "$($ConfigData.OutputPath)/lib/qrcodegend.*" }
        @{ FullPath = "$($ConfigData.OutputPath)/bin/qrcodegen.*" }
    )

    $Items | ForEach-Object {
        $Item = $_
        if ( Test-Path $Item.FullPath ) {
            Remove-Item -Recurse -Force $Item.FullPath
        }
    }
}
