Param(
    [Switch]$Help = $(if (Test-Path variable:Help) { $Help }),
    [Switch]$Quiet = $(if (Test-Path variable:Quiet) { $Quiet }),
    [Switch]$Verbose = $(if (Test-Path variable:Verbose) { $Verbose }),
    [Switch]$NoChoco = $(if (Test-Path variable:NoChoco) { $NoChoco }),
    [Switch]$SkipDependencyChecks = $(if (Test-Path variable:SkipDependencyChecks) { $SkipDependencyChecks }),
    [Switch]$Install = $(if (Test-Path variable:Install) { $Install }),
    [String]$BuildDirectory = "build",
    [ValidateSet("32-bit", "64-bit")]
    [String]$BuildArch = (Get-CimInstance CIM_OperatingSystem).OSArchitecture,
    [ValidateSet("Release", "RelWithDebInfo", "MinSizeRel", "Debug")]
    [String]$BuildConfiguration = "RelWithDebInfo"
)

################################################################################
# Windows Python native-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

function Build-Product {
    cd "${DepsBuildDir}"

    Write-Step "Download (${ARCH})..."
    if ("${BuildArch}" -eq "64-bit") {
        $PythonArch = ""
    } elseif ("${BuildArch}" -eq "32-bit") {
        $PythonArch = "-win32"
    }
    pyenv install --quiet "${ProductVersion}${PythonArch}"
    pyenv shell "${ProductVersion}${PythonArch}"
    $PythonPath = pyenv which python
    $PythonFolder = Split-Path -Path "${PythonPath}"
    New-Item -Path "${DepsBuildDir}\python\include" -ItemType Directory -Force
    New-Item -Path "${DepsBuildDir}\python\lib${CMAKE_BITNESS}" -ItemType Directory -Force
    Copy-Item -Path "${PythonFolder}\include\*" -Destination "${DepsBuildDir}\python\include"
    Copy-Item -Path "${PythonFolder}\libs\python3*.lib" -Destination "${DepsBuildDir}\python\lib${CMAKE_BITNESS}"
}

function Install-Product {
    cd "${DepsBuildDir}"

    Write-Step "Install (${ARCH})..."
    New-Item -Path "${CMAKE_INSTALL_DIR}\include\python" -ItemType Directory -Force
    Copy-Item -Path "${DepsBuildDir}\python\include\*" -Destination "${CMAKE_INSTALL_DIR}\include\python"
    Copy-Item -Path "${DepsBuildDir}\python\lib${CMAKE_BITNESS}\python3*.lib" -Destination "${CMAKE_INSTALL_DIR}\lib"
}

function Build-Python-Main {
    $ProductName = "${ProductName}"
    if (!${ProductName}) {
        $ProductName = "python"
    }

    if (!${_RunObsDepsBuildScript}) {
        $CheckoutDir = "$(git rev-parse --show-toplevel)"
        . "${CheckoutDir}/CI/include/build_support_windows.ps1"

        Build-Checks
    }

    $ProductFolder = "python"

    if (!$Install) {
        Build
    } else {
        Install-Product
    }
}

Build-Python-Main
