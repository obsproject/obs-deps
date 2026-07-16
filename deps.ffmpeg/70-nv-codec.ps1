param(
    [string] $Name = 'nv-codec-headers',
    [string] $Version = '13.0.19.0',
    [string] $Uri = 'https://github.com/FFmpeg/nv-codec-headers.git',
    [string] $Hash = 'e844e5b26f46bb77479f063029595293aa8f812d',
    [array] $Targets = @('x64'),
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/nv-codec/0001-Load-nvEncodeAPI.dll-for-native-Windows-ARM64-Windows.patch"
            HashSum = "C8CB308261D84F3D95DAD56EF3813677D6B4EFBE2325E53F98EF2CF96B61E5B3"
        }
    )
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Patch {
    Log-Information "Patch (${Target})"
    Set-Location $Path

    $Patches | ForEach-Object {
        $Params = $_
        Safe-Patch @Params
    }
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    $env:MSYS2_PATH_TYPE = 'inherit'
    $BuildCommand = @(
        "cd `"$("$(Get-Location | Convert-Path)" -replace '([A-Fa-f]):','/$1' -replace '\\','/')`" &&"
        "$(if ( $VerbosePreference -eq 'Continue' ) { 'VERBOSE=1' })"
        "make PREFIX=`"$($script:ConfigData.OutputPath -replace '([A-Fa-f]):','/$1' -replace '\\','/')`""
    )

    Invoke-External bash --login -c $($BuildCommand -join ' ')
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    $env:MSYS2_PATH_TYPE = 'inherit'
    $InstallCommand = @(
        "cd `"$("$(Get-Location | Convert-Path)" -replace '([A-Fa-f]):','/$1' -replace '\\','/')`" &&"
        "$(if ( $VerbosePreference -eq 'Continue' ) { 'VERBOSE=1' })"
        "make PREFIX=`"$($script:ConfigData.OutputPath -replace '([A-Fa-f]):','/$1' -replace '\\','/')`" install"
    )

    Invoke-External bash --login -c $($InstallCommand -join ' ')
}
