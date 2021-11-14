Param(
    [Switch]$Help = $(if (Test-Path variable:Help) { $Help }),
    [Switch]$Quiet = $(if (Test-Path variable:Quiet) { $Quiet }),
    [Switch]$Verbose = $(if (Test-Path variable:Verbose) { $Verbose }),
    [String]$BuildDirectory = "build"
)

##############################################################################
# Windows OBS deps package script
##############################################################################
#
# This script contains all steps necessary to:
#
#   * Build OBS required dependencies
#   * Create 64-bit and 32-bit variants
#
# Parameters:
#   -Help                   : Print usage help
#   -Quiet                  : Suppress most build process output
#   -Verbose                : Enable more verbose build process output
#   -BuildDirectory         : Directory to use for builds
#                             Default: Win64 on 64-bit systems
#                                      Win32 on 32-bit systems
#
##############################################################################

$ErrorActionPreference = "Stop"

$_ScriptName = "$($MyInvocation.MyCommand.Name)"

function Package-OBS-Deps-Main {
    $CheckoutDir = git rev-parse --show-toplevel
    $ProductName = "windows-deps"
    $DepsBuildDir = "${CheckoutDir}\windows\obs-win-deps"

    . "${CheckoutDir}\CI\include\build_support_windows.ps1"

    Write-Status "Create Windows OBS deps package"

    Ensure-Directory "${CheckoutDir}"

    if (!$CurrentDate) {
        $CurrentDate = Get-Date -UFormat "%Y-%m-%d"
    }
    $FileName = "${ProductName}-${CurrentDate}.tar.gz"
    $CrossDirBase = "${CheckoutDir}\windows\obs-cross-deps"
    $NativeDirBase = ""

    if (Test-Path "${CheckoutDir}\windows\obs-native-deps" -PathType "Container") {
        $NativeDirBase = "${CheckoutDir}\windows\obs-native-deps"
    } elseif (Test-Path "${CheckoutDir}\windows_native_build_temp" -PathType "Container") {
        $NativeDirBase = "${CheckoutDir}\windows_native_build_temp"
    }

    if (!(Test-Path "${CrossDirBase}\x86" -PathType "Container")) {
        Caught-Error "Missing cross-compiled build in ${CrossDirBase}\x86"
    } elseif (!(Test-Path "${CrossDirBase}\x86_64" -PathType "Container")) {
        Caught-Error "Missing cross-compiled build in ${CrossDirBase}\x86_64"
    } elseif (!(Test-Path "${NativeDirBase}\win32" -PathType "Container")) {
        Caught-Error "Missing native build in ${NativeDirBase}\win32"
    } elseif (!(Test-Path "${NativeDirBase}\win64" -PathType "Container")) {
        Caught-Error "Missing native build in ${NativeDirBase}\win64"
    }

    Remove-ItemIfExists "${DepsBuildDir}"
    Ensure-Directory "${DepsBuildDir}\win32"
    Ensure-Directory "${DepsBuildDir}\win64"
    cd ..

    $Packages = @(
        [pscustomobject]@{Arch='x86'; WinArch='win32'}
        [pscustomobject]@{Arch='x86_64'; WinArch='win64'}
    )
    Foreach ($Package in $Packages) {
        if ($Package.Arch -eq "x86") {
            $CrossDir = "${CrossDirBase}\x86"
            $NativeDir = "${NativeDirBase}\win32"
            $FinalDir = "${DepsBuildDir}\win32"
        } elseif ($Package.Arch -eq "x86_64") {
            $CrossDir = "${CrossDirBase}\x86_64"
            $NativeDir = "${NativeDirBase}\win64"
            $FinalDir = "${DepsBuildDir}\win64"
        }

        Write-Step "Copy $($Package.WinArch)/$($Package.Arch) files..."

        # Copy cross-compiled deps first
        Write-Step "Copy cross-compiled $($Package.WinArch)/$($Package.Arch) files..."
        Copy-Item -Path "${CrossDir}\bin" -Destination "${FinalDir}" -Recurse
        Copy-Item -Path "${CrossDir}\include" -Destination "${FinalDir}" -Recurse
        Copy-Item -Path "${CrossDir}\licenses" -Destination "${FinalDir}" -Recurse

        Write-Step "Clean up cross-compiled $($Package.WinArch)/$($Package.Arch) files..."
        # Remove unneeded files before copying native-compiled deps
        # Make sure symlinks still exist before trying to remove them
        Remove-Item -Path "${FinalDir}\bin\libmbedtls.dll" -Force
        Remove-Item -Path "${FinalDir}\bin\libmbedx509.dll" -Force
        Remove-ItemIfExists "${FinalDir}\bin\libpng16-config"
        Remove-ItemIfExists "${FinalDir}\bin\libpng-config"
        Remove-Item -Path "${FinalDir}\bin\mbedcrypto.lib" -Force
        Remove-Item -Path "${FinalDir}\bin\mbedtls.lib" -Force
        Remove-Item -Path "${FinalDir}\bin\mbedx509.lib" -Force
        Remove-Item -Path "${FinalDir}\bin\pngfix.exe" -Force
        Remove-Item -Path "${FinalDir}\bin\png-fix-itxt.exe" -Force
        Remove-ItemIfExists "${FinalDir}\bin\srt-ffplay"
        Remove-Item -Path "${FinalDir}\bin\x264.def" -Force
        Remove-Item -Path "${FinalDir}\bin\x264.exe" -Force
        Remove-Item -Path "${FinalDir}\bin\zlib.def" -Force

        # Copy native-compiled deps
        Write-Step "Copy native-compiled $($Package.WinArch)/$($Package.Arch) files..."
        Copy-Item -Path "${NativeDir}\bin\*" "${FinalDir}\bin" -Recurse -Force
        Copy-Item -Path "${NativeDir}\include\*" "${FinalDir}\include" -Recurse -Force
        #Copy-Item -Path "${NativeDir}\licenses\*" "${FinalDir}\licenses" -Recurse -Force
        Copy-Item -Path "${NativeDir}\lib\*.lib" "${FinalDir}\bin"
        Copy-Item -Path "${NativeDir}\lib\cmake" "${FinalDir}\cmake" -Recurse
        Copy-Item -Path "${NativeDir}\nasm" "${FinalDir}\nasm" -Recurse
        Copy-Item -Path "${NativeDir}\swig" "${FinalDir}\swig" -Recurse

        # Move and rename items
        Write-Step "Clean up native-compiled $($Package.WinArch)/$($Package.Arch) files..."
        New-Item -Path "${FinalDir}\include\cmocka" -ItemType Directory
        Move-Item -Path "${FinalDir}\include\cmocka*.h" -Destination "${FinalDir}\include\cmocka"
        Rename-Item -Path "${FinalDir}\bin\libcurl_imp.lib" -NewName "libcurl.lib"
        Remove-Item -Path "${FinalDir}\bin\luajit.lib"
        Rename-Item -Path "${FinalDir}\bin\lua51.lib" -NewName "luajit.lib"

        # Remove unneeded items
        Remove-Item -Path "${FinalDir}\bin\curl-config"
        Remove-Item -Path "${FinalDir}\cmake\CURL" -Recurse -Force
        Remove-Item -Path "${FinalDir}\cmake\freetype" -Recurse -Force
    }

    # Create dependencies archive
    Write-Step "Create pre-built dependency archive ${FileName}..."
    cd "${DepsBuildDir}\.."
    tar -czf "${FileName}" -C "${DepsBuildDir}" *

    Write-Info "All done!"
}

## MAIN SCRIPT FUNCTIONS ##
function Print-Usage {
    Write-Host "package-deps-windows.ps1 - Package script for ${ProductName}"
    $Lines = @(
        "Usage: ${_ScriptName}",
        "-Help                    : Print this help",
        "-Quiet                   : Suppress most build process output",
        "-Verbose                 : Enable more verbose build process output",
        "-BuildDirectory          : Directory to use for builds - Default: build64 on 64-bit systems, build32 on 32-bit systems",
        "-BuildArch               : Build architecture to use (32-bit or 64-bit) - Default: local architecture"
    )
    $Lines | Write-Host
}

if ($Help) {
    Print-Usage
    exit 0
}

Package-OBS-Deps-Main
