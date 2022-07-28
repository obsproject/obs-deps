param(
    [string] $Name = 'qt6',
    [string] $Version = '6.3.1',
    [string] $Uri = 'https://github.com/qt/qt5.git',
    [string] $Hash = 'c3d2dfa229f87374fc5919b5c44606445cf94bd8',
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/Qt6/win/0001-QTBUG-86344.patch"
            HashSum = "688E7787CEA28047DF819AA00E16A81CA3BB7E331E7620268CCD38D1D533B4ED"
        }
    )
)

# References:
# 1: https://wiki.qt.io/Building_Qt_6_from_Git
# 2: https://doc.qt.io/qt-6/windows-building.html
# 3: https://doc.qt.io/qt-6/configure-options.html#source-build-and-install-directories
# 4: https://doc.qt.io/qt-6.2/windows-building.html

# Per [2]:
# Note: The install path must not contain any spaces or Windows specific file system characters.

# Per [4]:
# Note: The path to the source directory must not contain any spaces or Windows specific file system characters. The
# path should also be kept short. This avoids issues with too long file paths in the compilation phase.

function Setup {
    Check-Ninja
    $Path = "qt6"
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath "$Path"

    New-Item -ItemType "directory" -Path "qt6_build\${Version}\${Target}" -Force
    New-Item -ItemType "directory" -Path "$($ConfigData.OutputPath)" -Force

    # Run init-repository perl script.
    # This will fail if any of the repos are dirty (uncommitted patches).
    Set-Location qt6
    $Options = @(
        '--module-subset', 'qtbase,qtimageformats,qtmultimedia,qtshadertools,qtsvg'
        '--force'
    )
    Invoke-External perl init-repository @Options
}

function Clean {
    Set-Location $Path

    # Perform git clean here to ensure that the source tree is clean.
    # This should only be needed if building in-tree, but safe enough to do either way.
    Invoke-External git submodule foreach --recursive "git clean -dfx"
    Invoke-External git clean -dfx

    Set-Location ".."
    Remove-Item "qt6_build\${Version}\${Target}\*" -Recurse -Force
    Remove-Item "$($ConfigData.OutputPath)\*" -Recurse -Force
}

function Patch {
    Log-Information "Patch (${Target})"
    Set-Location $Path

    $Patches | ForEach-Object {
        $Params = $_
        Safe-Patch @Params
    }

    Set-Location qtbase
    Check-GitUser
    git add .
    git commit -m "Backport fix for QTBUG-86344"
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

    $BuildPath = "$($ConfigData.OutputPath)"
    Set-Location "..\qt6_build\${Version}\${Target}"

    $QtBuildConfiguration = '-release'
    if ( $Configuration -eq 'Release' ) {
        $QtBuildConfiguration = '-release'
    } elseif ( $Configuration -eq 'RelWithDebInfo' ) {
        $QtBuildConfiguration = '-release -force-debug-info'
    } elseif ( $Configuration -eq 'Debug' ) {
        $QtBuildConfiguration = '-debug'
    } elseif ( $Configuration -eq 'MinSizeRel' ) {
        $QtBuildConfiguration = '-release'
    }

    $BuildCommand = "..\..\..\qt6\configure -opensource -confirm-license ${QtBuildConfiguration} -nomake examples -nomake tests -schannel -no-dbus -no-freetype -no-icu -no-openssl -no-feature-androiddeployqt -no-feature-pdf -no-feature-printsupport -no-feature-qmake -no-feature-sql -no-feature-testlib -no-feature-windeployqt -DQT_NO_PDF -prefix ${BuildPath}"

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "."
        BuildCommand = "${BuildCommand}"
        Target = $Target
        HostArchitecture = $Target
    }

    Invoke-DevShell @Params
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    Set-Location "..\qt6_build\${Version}\${Target}"

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "."
        BuildCommand = "cmake --build . --parallel"
        Target = $Target
        HostArchitecture = $Target
    }

    Invoke-DevShell @Params
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    Set-Location "..\qt6_build\${Version}\${Target}"

    $BuildCommand = 'cmake --install .'

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "."
        BuildCommand = "${BuildCommand}"
        Target = $Target
        HostArchitecture = $Target
    }

    Invoke-DevShell @Params
}
