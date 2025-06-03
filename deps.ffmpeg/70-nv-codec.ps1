param(
    [string] $Name = 'nv-codec-headers',
    [string] $Version = '12.1.14.0',
    [string] $Uri = 'https://github.com/FFmpeg/nv-codec-headers.git',
    [string] $Hash = '1889e62e2d35ff7aa9baca2bceb14f053785e6f1'
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
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
