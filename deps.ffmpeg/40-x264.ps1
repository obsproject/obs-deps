param(
    [string] $Name = 'x264',
    [string] $Version = 'r3106',
    [string] $Uri = 'https://github.com/mirror/x264.git',
    [string] $Hash = 'eaa68fad9e5d201d42fde51665f2d137ae96baf0',
    [array] $Targets = @('x64', 'arm64'),
    [switch] $ForceShared = $true
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path

    if ( ! ( $SkipAll -or $SkipDeps ) ) {
        if ( $Target -ne 'arm64' ) {
            Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar nasm
        }
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar make
    }

    if ( $Target -eq 'arm64' ) {
        Remove-Item -Path "${Path}/tools/gas-preprocessor.pl" -ErrorAction SilentlyContinue
        Copy-Item -Path "$($script:WorkRoot)/gas-preprocessor/gas-preprocessor.pl" -Destination "${Path}/tools/"
    }
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
    Set-Location $Path

    $TargetCPUs = @{
        x64 = 'x86_64'
        x86 = 'x86'
        arm64 = 'aarch64'
    }

    if ( $ForceShared -and ( $script:Shared -eq $false ) ) {
        $Shared = $true
    } else {
        $Shared = $script:Shared.isPresent
    }

    New-Item -ItemType Directory -Force "build_${Target}" > $null

    $ConfigureCommand = @(
        'bash'
        '../configure'
        ('--host=' + $($TargetCPUs[$Target]) + '-mingw64')
        ('--prefix="' + $($script:ConfigData.OutputPath -replace '([A-Fa-f]):','/$1' -replace '\\','/') + '"')
        '--enable-static'
        '--enable-pic'
        '--disable-lsmash'
        '--disable-avs'
        '--disable-gpac'
        '--disable-interlaced'
        '--disable-cli'
        $(if ( $Shared ) { '--enable-shared' })
        $(if ( $Configuration -match '(Debug|RelWithDebInfo)' ) { '--enable-debug' })
    )

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "build_${Target}"
        BuildCommand = $($ConfigureCommand -join ' ')
        Target = $Target
    }

    $Backup = @{
        CC = $env:CC
        CFLAGS = $env:CFLAGS
        CXXFLAGS = $env:CXXFLAGS
        MSYS2_PATH_TYPE = $env:MSYS2_PATH_TYPE
    }
    $env:CC = 'cl'
    $env:CFLAGS = $($($script:CFlags) + ' -wd4003')
    $env:CXXFLAGS = $($($script:CxxFlags) + ' -wd4003')
    $env:MSYS2_PATH_TYPE = 'inherit'
    Invoke-DevShell @Params
    $Backup.GetEnumerator() | ForEach-Object { Set-Item -Path "env:\$($_.Key)" -Value $_.Value }
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

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
    Set-Location $Path

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
    Set-Location $Path

   if ( $ForceShared -and ( $script:Shared -eq $false ) ) {
        $Shared = $true
    } else {
        $Shared = $script:Shared.isPresent
    }

    if ( $Shared ) {
        Remove-Item -ErrorAction SilentlyContinue "$($script:ConfigData.OutputPath)/lib/libx264.lib"
        Rename-Item "$($script:ConfigData.OutputPath)/lib/libx264.dll.lib" -NewName "$($script:ConfigData.OutputPath)/lib/libx264.lib"
    }
}
