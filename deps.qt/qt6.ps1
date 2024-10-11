param(
    [string] $Name = 'qt6',
    [string] $Version = '6.6.3',
    [string] $Uri = 'https://download.qt.io/archive/qt/6.6/6.6.3',
    [string] $Hash = "${PSScriptRoot}/checksums",
    [array] $Targets = @('x64', 'arm64')
)

$QtComponents = @(
    'qtbase'
    'qtimageformats'
    'qtshadertools'
    'qtmultimedia'
    'qtsvg'
    'qttools'
)

$Directory = 'qt6'

function Setup {
    $SourceDirectory = Get-Location | Convert-Path

    New-Item -ItemType Directory -Name $Directory -ErrorAction SilentlyContinue > $null

    $QtComponents | ForEach-Object {
        $Component = $_

        Log-Information "Setup ${Component} (${Target})"

        $FileUrl = "${Uri}/submodules/${Component}-everywhere-src-${Version}.zip"
        $FileHash = "${Hash}/${Component}-everywhere-src-${Version}.zip.sha256"

        Log-Information "Download ${FileUrl}"
        Invoke-SafeWebRequest -Uri $FileUrl -HashFile $FileHash -Resume

        if ( ! $SkipUnpack ) {
            Log-Information "Extract $(Split-Path -Path $FileUrl -Leaf)"

            Push-Location -Stack QtBuildStack -Path "${Directory}"
            Expand-ArchiveExt -Path "${SourceDirectory}/${Component}-everywhere-src-${Version}.zip" -DestinationPath $(Get-Location | Convert-Path) -Force
            Get-ChildItem -Recurse -Directory -Include "${Component}" -Depth 1 | Remove-Item -Recurse -Force
            Rename-Item -Path "${Component}-everywhere-src-${Version}" -NewName "${Component}"
            Pop-Location -Stack QtBuildStack
        }
    }
}

function Clean {
    Set-Location ${Directory}

    if ( $script:Clean ) {
        $BuildDirectories = Get-ChildItem -Recurse -Directory -Include "build_${Target}" -Depth 1

        $BuildDirectories | ForEach-Object {
            $CleanDirectory = $_
            Log-Information "Clean build directory $($CleanDirectory.FullName) (${Target})"

            Remove-Item -Path $CleanDirectory -Force -Recurse
        }
    }
}

function Patch {
    Log-Information "Patch (${Target})"
    Push-Location "${Directory}"

    $Patches | ForEach-Object {
        $Params = $_
        Safe-Patch @Params
    }

    Pop-Location
}

function Configure {
    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
        "-DBUILD_SHARED_LIBS:BOOL=$($OnOff[$script:Shared.isPresent])"
    )

    if ( $Config -eq 'RelWithDebInfo' ) {
        $Options += @(
            '-DFEATURE_separate_debug_info:BOOL=ON'
        )
    }

    $Options += @(
        '-DFEATURE_androiddeployqt:BOOL=OFF'
        '-DFEATURE_brotli:BOOL=OFF'
        '-DFEATURE_dbus:BOOL=OFF'
        '-DFEATURE_doubleconversion:BOOL=ON'
        '-DFEATURE_freetype:BOOL=OFF'
        '-DFEATURE_glib:BOOL=OFF'
        '-DFEATURE_harfbuzz:BOOL=ON'
        '-DFEATURE_icu:BOOL=OFF'
        '-DFEATURE_jpeg:BOOL=ON'
        '-DFEATURE_macdeployqt:BOOL=OFF'
        '-DFEATURE_pcre2:BOOL=ON'
        '-DFEATURE_pdf:BOOL=OFF'
        '-DFEATURE_png:BOOL=ON'
        '-DFEATURE_printsupport:BOOL=OFF'
        '-DFEATURE_qmake:BOOL=OFF'
        '-DFEATURE_schannel:BOOL=ON'
        '-DFEATURE_sql:BOOL=OFF'
        '-DFEATURE_system_doubleconversion:BOOL=OFF'
        '-DFEATURE_system_jpeg:BOOL=OFF'
        '-DFEATURE_system_pcre2:BOOL=OFF'
        '-DFEATURE_system_png:BOOL=OFF'
        '-DFEATURE_system_zlib:BOOL=OFF'
        '-DFEATURE_testlib:BOOL=OFF'
        '-DFEATURE_windeployqt:BOOL=OFF'
        '-DINPUT_openssl:STRING=no'
        '-DQT_BUILD_BENCHMARKS:BOOL=OFF'
        '-DQT_BUILD_EXAMPLES:BOOL=OFF'
        '-DQT_BUILD_EXAMPLES_BY_DEFAULT:BOOL=OFF'
        '-DQT_BUILD_MANUAL_TESTS:BOOL=OFF'
        '-DQT_BUILD_TESTS:BOOL=OFF'
        '-DQT_BUILD_TESTS_BY_DEFAULT:BOOL=OFF'
        '-DQT_BUILD_TOOLS_BY_DEFAULT:BOOL=OFF'
        '-DQT_USE_VCPKG:BOOL=OFF'
        '-DCMAKE_IGNORE_PREFIX_PATH:PATH=C:/Strawberry/c'
    )

    if ( $env:QtHostPath -ne $null ) {
        $Options += @(
            "-DQT_HOST_PATH:PATH=${env:QtHostPath}"
            '-DQT_FORCE_BUILD_TOOLS:BOOL=ON'
            '-DCMAKE_CROSSCOMPILING:BOOL=ON'
            '-DCMAKE_SYSTEM_NAME:STRING=Windows'
        )
    }

    $CMakeTarget = @{
        x64 = 'x64'
        arm64 = 'arm64'
    }

    $Options = ($Options -join ' ') -replace '-G Visual Studio \d+ \d+','-G Ninja' -replace "-A $($CMakeTarget[$Target])",''

    Log-Information "Configure qtbase (${Target})"

    $Params = @{
        BasePath = ${Directory}
        BuildPath = 'qtbase'
        BuildCommand = "cmake -S . -B build_${Target} ${Options}"
        Target = $Target
    }

    $Backup = @{
        PATH = $env:PATH
        VCPKG_ROOT = $env:VCPKG_ROOT
    }
    $env:PATH = "$(Resolve-Path ((Get-Command git).Source + '/../../usr/bin') | Convert-Path);$env:PATH"
    $env:VCPKG_ROOT = ''
    Invoke-DevShell @Params
    $Backup.GetEnumerator() | ForEach-Object { Set-Item -Path "env:\$($_.Key)" -Value $_.Value }
}

function Build {
    Log-Information "Build qtbase (${Target})"

    $Options = @(
        '--build', "build_${Target}"
        '--config', $Configuration
    )

    if ( $VerbosePreference -eq 'Continue' ) {
        $Options += '--verbose'
    }

    $Params = @{
        BasePath = ${Directory}
        BuildPath = 'qtbase'
        BuildCommand = "cmake $($Options -join ' ')"
        Target = $Target
    }

    Invoke-DevShell @Params
}

function Install {
    Log-Information "Install qtbase (${Target})"

    $Options = @(
        '--install', "build_${Target}"
        '--config', $Configuration
    )

    if ( $Configuration -match 'Release|MinSizeRel' ) {
        $Options += '--strip'
    }

    if ( $VerbosePreference -eq 'Continue' ) {
        $Options += '--verbose'
    }

    Push-Location "${Directory}/qtbase"
    cmake @Options
    Pop-Location

    Qt-Add-Submodules
}

function Qt-Add-Submodules {
    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
        "-DBUILD_SHARED_LIBS:BOOL=$($OnOff[$script:Shared.isPresent])"
    )

    if ( $Config -eq 'RelWithDebInfo' ) {
        $Options += @(
            '-DFEATURE_separate_debug_info:BOOL=ON'
        )
    }

    if ( $env:QtHostPath -ne $null ) {
        $Options += @(
            "-DQT_HOST_PATH:PATH=${env:QtHostPath}"
            '-DQT_FORCE_BUILD_TOOLS:BOOL=ON'
            '-DCMAKE_CROSSCOMPILING:BOOL=ON'
            '-DCMAKE_SYSTEM_NAME:STRING=Windows'
        )
    }

    $CMakeTarget = @{
        x64 = 'x64'
        arm64 = 'arm64'
    }

    $QtComponents | Where-Object { $_ -ne 'qtbase' } | ForEach-Object {
        $Component = $_

        $ComponentOptions = @(
            $Options
        )

        switch ( $Component ) {
            qtimageformats {
                $ComponentOptions += @(
                    '-DINPUT_tiff:STRING=qt'
                    '-DINPUT_webp:STRING=qt'
                )
            }
            qttools {
                $ComponentOptions += @(
                    '-DFEATURE_assistant:BOOL=OFF'
                    '-DFEATURE_designer:BOOL=ON'
                    '-DFEATURE_linguist:BOOL=OFF'
                    '-DFEATURE_pixeltool:BOOL=OFF'
                    '-DFEATURE_qtattributionsscanner:BOOL=OFF'
                    '-DFEATURE_qtdiag:BOOL=OFF'
                    '-DFEATURE_qtplugininfo:BOOL=OFF'
                    '-DQT_BUILD_TOOLS_BY_DEFAULT:BOOL=ON'
                )
            }
        }

        $ComponentOptions = ($ComponentOptions -join ' ') -replace '-G Visual Studio \d+ \d+','-G Ninja' -replace "-A $($CMakeTarget[$Target])",''

        Log-Information "Configure ${Component} (${Target})"

        $Params = @{
            BasePath = ${Directory}
            BuildPath = ${Component}
            BuildCommand = "cmake -S . -B build_${Target} ${ComponentOptions}"
            Target = $Target
        }

        $Backup = @{
            PATH = $env:PATH
            VCPKG_ROOT = $env:VCPKG_ROOT
        }
        $env:PATH = "$(Resolve-Path ((Get-Command git).Source + '/../../usr/bin') | Convert-Path);$env:PATH"
        $env:VCPKG_ROOT = ''
        Invoke-DevShell @Params
        $Backup.GetEnumerator() | ForEach-Object { Set-Item -Path "Env:\$($_.Key)" -Value $_.Value }

        Log-Information "Build ${Component} (${Target})"

        $BuildOptions = @(
            '--build', "build_${Target}"
            '--config', $Configuration
        )

        if ( $VerbosePreference -eq 'Continue' ) {
            $BuildOptions += '--verbose'
        }

        $Params = @{
            BasePath = ${Directory}
            BuildPath = ${Component}
            BuildCommand = "cmake $($BuildOptions -join ' ')"
            Target = $Target
        }

        Invoke-DevShell @Params

        Log-Information "Install ${Component} (${Target})"

        $InstallOptions = @(
            '--install', "build_${Target}"
            '--config', $Configuration
        )

        if ( $Configuration -match 'Release|MinSizeRel' ) {
            $InstallOptions += '--strip'
        }

        if ( $VerbosePreference -eq 'Continue' ) {
            $InstallOptions += '--verbose'
        }

        Push-Location "${Directory}/${Component}"
        cmake @InstallOptions
        Pop-Location
    }
}
