param(
    [string] $Name = 'libvpx',
    [string] $Version = '1.14.1',
    [string] $Uri = 'https://github.com/webmproject/libvpx/archive/refs/tags/v1.14.1.zip',
    [string] $Hash = "${PSScriptRoot}/checksums/v1.14.1.zip.sha256",
    [array] $Targets = @('x64', 'arm64')
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath "."

    if ( ! ( $SkipAll -or $SkipDeps ) ) {
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar nasm
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar make
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar diffutils
    }
}

function Clean {
    Set-Location "${Name}-${Version}"
    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location "${Name}-${Version}"

    $BuildTargets = @{
        x64 = 'x86_64-win64-vs17'
        x86 = 'x86-win32-vs17'
        arm64 = 'arm64-win64-vs17-clangcl'
    }

    New-Item -ItemType Directory -Force "build_${Target}" > $null

    $ConfigureCommand = @(
        'bash'
        '../configure'
        ('--prefix="' + $($script:ConfigData.OutputPath -replace '([A-Fa-f]):','/$1' -replace '\\','/') + '"')
        ('--target=' + $($BuildTargets[$Target]))
        $(if ( $Target -eq 'arm64' ) { '--disable-neon_dotprod --disable-neon_i8mm' })
        '--enable-vp8'
        '--enable-vp9'
        '--enable-vp9-highbitdepth'
        '--enable-static'
        '--enable-multithread'
        '--enable-pic'
        '--enable-realtime-only'
        '--disable-tools'
        '--disable-docs'
        '--disable-examples'
        '--disable-install-bins'
        '--disable-install-docs'
        '--disable-unit-tests'
        $(if ( $script:Shared ) { '--enable-shared' } else { '--disable-shared' })
        $(if ( $Configuration -eq 'Debug' ) { '--enable-debug' })
    )

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "build_${Target}"
        BuildCommand = $($ConfigureCommand -join ' ')
        Target = $Target
    }

    $Backup = @{
        MSYS2_PATH_TYPE = $env:MSYS2_PATH_TYPE
    }
    $env:MSYS2_PATH_TYPE = 'inherit'
    Invoke-DevShell @Params
    $Backup.GetEnumerator() | ForEach-Object { Set-Item -Path "env:\$($_.Key)" -Value $_.Value }
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location "${Name}-${Version}"

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "build_${Target}"
        BuildCommand = "make -j${env:NUMBER_OF_PROCESSORS}"
        Target = $Target
    }

    $Backup = @{
        MSYS2_PATH_TYPE = $env:MSYS2_PATH_TYPE
        VERBOSE = $env:VERBOSE
    }
    $env:MSYS2_PATH_TYPE = 'inherit'
    $env:VERBOSE = $(if ( $VerbosePreference -eq 'Continue' ) { '1' })
    Invoke-DevShell @Params
    $Backup.GetEnumerator() | ForEach-Object { Set-Item -Path "env:\$($_.Key)" -Value $_.Value }
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location "${Name}-${Version}"

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "build_${Target}"
        BuildCommand = "make install"
        Target = $Target
    }

    $Backup = @{
        MSYS2_PATH_TYPE = $env:MSYS2_PATH_TYPE
        VERBOSE = $env:VERBOSE
    }
    $env:MSYS2_PATH_TYPE = 'inherit'
    $env:VERBOSE = $(if ( $VerbosePreference -eq 'Continue' ) { '1' })
    Invoke-DevShell @Params
    $Backup.GetEnumerator() | ForEach-Object { Set-Item -Path "env:\$($_.Key)" -Value $_.Value }
}

function Fixup {
    Log-Information "Fixup (${Target})"
    Set-Location "${Name}-${Version}"

    Get-ChildItem "$($script:ConfigData.OutputPath)/lib" -Recurse -Filter 'vpxmd.lib' | Move-Item -Destination "$($script:ConfigData.OutputPath)/lib/vpx.lib" -Force
    Remove-Item -Force -Recurse "$($script:ConfigData.OutputPath)/lib/${Target}" -ErrorAction SilentlyContinue
}
