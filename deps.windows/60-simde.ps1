param(
    [string] $Name = 'simde',
    [string] $Version = '0.8.2',
    [string] $Uri = 'https://github.com/simd-everywhere/simde.git',
    [string] $Hash = '71fd833d9666141edcd1d3c109a80e228303d8d7',
    [array] $Targets = @('x64', 'arm64'),
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/simde/0001-generate-cross-compile-files-windows-native.patch"
            HashSum = "AF937409D5965654CA254B7AF8C3D9EF59FB42759F8F1BF36F26797FBEE16193"
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

    $ConfigStrings = @{
        Debug = 'debug'
        RelWithDebInfo = 'debugoptimized'
        Release = 'release'
        MinSizeRel = 'minsize'
    }

    $VisualStudioData = Find-VisualStudio
    $VisualStudioId = ($VisualStudioData.DisplayName -split ' ')[-1]

    $Options = @(
        '--buildtype', "$($ConfigStrings[$Configuration])"
        '--backend', "vs${VisualStudioId}"
        '--prefix', "$($script:ConfigData.OutputPath)"
        '-Dtests=false'
        '--cross-file', "windows-${Target}.txt"
    )

     $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = '.'
        BuildCommand = "meson setup build_${Target} $($Options -join ' ')"
        Target = $Target
    }

    Invoke-DevShell @Params
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = '.'
        BuildCommand = "meson compile -C build_${Target}"
        Target = $Target
    }

    Invoke-DevShell @Params
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    Invoke-External meson install -C "build_${Target}"
}
