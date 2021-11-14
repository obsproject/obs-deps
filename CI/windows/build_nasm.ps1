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
# Windows NASM native-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

function Build-Product {
    cd "${DepsBuildDir}"

    Write-Step "Extract (${ARCH})..."
    7z x ".\nasm-${ProductVersion}-win${CMAKE_BITNESS}.zip" -y -o"nasm\win${CMAKE_BITNESS}"
}

function Install-Product {
    cd "${DepsBuildDir}"

    Write-Step "Install (${ARCH})..."
    New-Item -Path "${CMAKE_INSTALL_DIR}\nasm" -ItemType Directory -Force
    Copy-Item -Path "nasm\win${CMAKE_BITNESS}\nasm-${ProductVersion}\*" -Destination "${CMAKE_INSTALL_DIR}\nasm" -Recurse -Force
}

function Build-Nasm-Main {
    $ProductName = "${ProductName}"
    if (!${ProductName}) {
        $ProductName = "nasm"
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
    if ("${BuildArch}" -eq "64-bit") {
        $ProductHash = "d054bf8595eb2b31bb673a3cd4a999e61bb39394fedd07a09f30f75b2524953b"
    } elseif ("${BuildArch}" -eq "32-bit") {
        $ProductHash = "7ee1bad8c5b3ba195af4b4f984702fedc9745473e7f74cda65a7320425bd9114"
    }

    $ProductUrl = "https://www.nasm.us/pub/nasm/releasebuilds/${ProductVersion}/win${CMAKE_BITNESS}/nasm-${ProductVersion}-win${CMAKE_BITNESS}.zip"

    if (!$Install) {
        Build-Setup -UseCurl
        Build
    } else {
        Install-Product
    }
}

Build-Nasm-Main
