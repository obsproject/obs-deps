param(
    [string] $Name = 'pcre',
    [string] $Version = '10.40',
    [string] $Uri = 'https://github.com/PhilipHazel/pcre2/releases/download/pcre2-10.40/pcre2-10.40.zip',
    [string] $Hash = "${PSScriptRoot}/checksums/pcre2-10.40.zip.sha256"
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

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location "${Path}/$([System.IO.Path]::GetFileNameWithoutExtension($Uri))"

    $Options = @(
        $CmakeOptions
        "-DBUILD_SHARED_LIBS:BOOL=OFF"
    )

    Invoke-External cmake -S . -B "build_${Target}" @Options
}

function Build {
    Log-Information "Install (${Target})"
    Set-Location "${Path}/$([System.IO.Path]::GetFileNameWithoutExtension($Uri))"

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
    Set-Location "${Path}/$([System.IO.Path]::GetFileNameWithoutExtension($Uri))"

    $Options = @(
        '--install', "build_${Target}"
        '--config', $Configuration
    )

    if ( $Configuration -match "(Release|MinSizeRel)" ) {
        $Options += '--strip'
    }

    Invoke-External cmake @Options
}
