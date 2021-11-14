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
# Windows SWIG native-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

function Build-Product {
    cd "${DepsBuildDir}"

    Write-Step "Extract (${ARCH})..."
    7z x ".\swigwin-${ProductVersion}.zip" -y
}

function Install-Product {
    cd "${DepsBuildDir}"

    Write-Step "Install (${ARCH})..."
    New-Item -Path "${CMAKE_INSTALL_DIR}\swig" -ItemType Directory -Force
    Copy-Item -Path "swigwin-${ProductVersion}\*" -Destination "${CMAKE_INSTALL_DIR}\swig" -Recurse -Force
    Remove-Item -Path @("${CMAKE_INSTALL_DIR}\swig\Doc", "${CMAKE_INSTALL_DIR}\swig\Examples") -Recurse -Force
}

function Build-Swig-Main {
    $ProductName = "${ProductName}"
    if (!${ProductName}) {
        $ProductName = "swig"
    }

    if (!${_RunObsDepsBuildScript}) {
        $CheckoutDir = "$(git rev-parse --show-toplevel)"
        . "${CheckoutDir}/CI/include/build_support_windows.ps1"

        Build-Checks
    }

    if (!${ProductVersion}) {
        $ProductVersion = $script:CI_PRODUCT_VERSION
    }
    if (!${ProductHash}) {
        $ProductHash = $script:CI_PRODUCT_HASH
    }

    $ProductUrl = "https://downloads.sourceforge.net/project/swig/swigwin/swigwin-${ProductVersion}/swigwin-${ProductVersion}.zip"

    if (!$Install) {
        Build-Setup -UseCurl
        Build
    } else {
        Install-Product
    }
}

Build-Swig-Main
