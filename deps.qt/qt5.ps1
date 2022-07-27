param(
    [string] $Name = 'qt5',
    [string] $Version = '5.15.5',
    [string] $Uri = 'https://github.com/qt/qt5.git',
    [string] $Hash = '9039ca53a3dac14415cea435083bb96f0acdb3d8',
    [array] $Patches = @(
        @{
            PatchFile = "${PSScriptRoot}/patches/Qt5/win/0001-QTBUG-74606.patch"
            HashSum = "BAE8765FC74FB398BC3967AD82760856EE308E643A8460C324D36A4D07063001"
        }
    )
)

# References:
# 1: https://wiki.qt.io/Building_Qt_5_from_Git
# 2: https://doc.qt.io/qt-5/windows-building.html
# 3: https://doc.qt.io/qt-5/configure-options.html#source-build-and-install-directories
# 4: https://doc.qt.io/qt-6.2/windows-building.html

# Per [2]:
# Note: The install path must not contain any spaces or Windows specific file system characters.

# Per [4]:
# Note: The path to the source directory must not contain any spaces or Windows specific file system characters. The
# path should also be kept short. This avoids issues with too long file paths in the compilation phase.

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path

    # Download jom if not present and check its hash.
    Invoke-SafeWebRequest -Uri "https://download.qt.io/official_releases/jom/jom_1_1_3.zip" -HashFile "${PSScriptRoot}/checksums/jom-1.1.3.zip.sha256" -CheckExisting
    Expand-ArchiveExt -Path "jom_1_1_3.zip" -DestinationPath "jom" -Force

    New-Item -ItemType "directory" -Path "qt5_build\${Version}\${Target}" -Force
    New-Item -ItemType "directory" -Path "$($ConfigData.OutputPath)" -Force

    # Run init-repository perl script.
    # This will fail if any of the repos are dirty (uncommitted patches).
    Set-Location qt5

    # Perform git clean here to ensure that init-repository does not fail.
    Invoke-External git submodule foreach --recursive "git clean -dfx"
    Invoke-External git clean -dfx

    Check-GitUser
    $Options = @(
        '--module-subset', 'qtbase,qtimageformats,qtmultimedia,qtsvg,qtwinextras'
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
    Remove-Item "qt5_build\${Version}\${Target}\*" -Recurse -Force
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
    git commit -m "Simple fix for QTBUG-74606"
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

    $BuildPath = "$($ConfigData.OutputPath)"
    Set-Location "..\qt5_build\${Version}\${Target}"

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

    $BuildCommand = "..\..\..\qt5\configure -opensource -confirm-license ${QtBuildConfiguration} -no-strip -nomake examples -nomake tests -no-compile-examples -schannel -no-dbus -no-freetype -no-harfbuzz -no-icu -no-feature-itemmodeltester -no-feature-printdialog -no-feature-printer -no-feature-printpreviewdialog -no-feature-printpreviewwidget -no-feature-sql -no-feature-sqlmodel -no-feature-testlib -no-sql-db2 -no-sql-ibase -no-sql-mysql -no-sql-oci -no-sql-odbc -no-sql-psql -no-sql-sqlite2 -no-sql-sqlite -no-sql-tds -DQT_NO_PDF -DQT_NO_PRINTER -mp -prefix ${BuildPath}"

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

    Set-Location ".."
    Copy-Item "jom\jom.exe" "qt5_build\${Version}\${Target}\jom.exe"

    Set-Location "qt5_build\${Version}\${Target}"

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "."
        BuildCommand = ".\jom.exe"
        Target = $Target
        HostArchitecture = $Target
    }

    Invoke-DevShell @Params
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    Set-Location "..\qt5_build\${Version}\${Target}"

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "."
        BuildCommand = ".\jom.exe install"
        Target = $Target
        HostArchitecture = $Target
    }

    Invoke-DevShell @Params
}
