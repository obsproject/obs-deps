param(
    [string] $Name = 'aom',
    [string] $Version = '3.9.1',
    [string] $Uri = 'https://aomedia.googlesource.com/aom.git',
    [string] $Hash = '8ad484f8a18ed1853c094e7d3a4e023b2a92df28',
    [array] $Targets = @('x64', 'arm64'),
    [array] $FixupPatches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/aom/0001-windows-pkg-config-fix.patch"
            HashSum = "22f38b49d6307c2ee860b08df7495b5f8894658b451c020f8a13162fd7dd29f4"
        }
    )
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path

    if ( ! ( $SkipAll -or $SkipDeps ) ) {
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar nasm
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

    $OnOff = @('OFF', 'ON')
    $TargetCPUs = @{
        x64 = 'x86_64'
        arm64 = 'arm64'
    }

    $Options = @(
        $CmakeOptions
        "-DBUILD_SHARED_LIBS:BOOL=$($OnOff[$script:Shared.isPresent])"
        '-DENABLE_DOCS:BOOL=OFF'
        '-DENABLE_EXAMPLES:BOOL=OFF'
        '-DENABLE_TESTDATA:BOOL=OFF'
        '-DENABLE_TESTS:BOOL=OFF'
        '-DENABLE_TOOLS:BOOL=OFF'
        '-DENABLE_NASM:BOOL=ON'
        "-DAOM_TARGET_CPU=$($TargetCPUs[$Target])"
        $(if ( $Target -eq 'arm64' ) { '-DCONFIG_RUNTIME_CPU_DETECT=0' })
    )

    Invoke-External cmake -S . -B "build_${Target}" -T clangcl @Options
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

    $Options += @($CmakePostfix)

    Invoke-External cmake @Options
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

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
    Set-Location "$($script:ConfigData.OutputPath)"

    $FixupPatches | ForEach-Object {
        $Params = $_
        Safe-Patch @Params
    }
}
