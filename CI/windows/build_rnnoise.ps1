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
# Windows RNNoise native-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

function Patch-Product {
    cd "${ProductFolder}"

    Write-Step "Checkout CMake PR..."
    Git-Checkout-Pull-Request 88
}

function Build-Product {
    cd "${DepsBuildDir}"

    if ($Quiet) {
        $CMAKE_OPTS = "-Wno-deprecated -Wno-dev --log-level=ERROR"
    } else {
        $CMAKE_OPTS = ""
    }

    Write-Step "Configure (${ARCH})..."
    cmake -G "Visual Studio 16 2019" `
        -A "${CMAKE_ARCH}" `
        -DRNNOISE_COMPILE_OPUS=ON `
        "${CMAKE_OPTS}" `
        -S "rnnoise" `
        -B "rnnoise_build\${CMAKE_BITNESS}"

    Write-Step "Build (${ARCH})..."
    cmake --build "rnnoise_build\${CMAKE_BITNESS}" --config "${BuildConfiguration}"
}

function Install-Product {
    cd "${DepsBuildDir}"

    Write-Step "Install (${ARCH})..."
    # need some manual copy action here because cmake support isn't there for `install`
    #cmake --install "rnnoise_build\${CMAKE_BITNESS}" --config "${BuildConfiguration}" --prefix "${DepsBuildDir}\${CMAKE_INSTALL_DIR}"

    Copy-Item -Path "${DepsBuildDir}\${ProductFolder}\include\rnnoise.h" -Destination "${CMAKE_INSTALL_DIR}\include\rnnoise.h"
    Copy-Item -Path "${DepsBuildDir}\rnnoise_build\${CMAKE_BITNESS}\${BuildConfiguration}\rnnoise.lib" -Destination "${CMAKE_INSTALL_DIR}\lib\rnnoise.lib"
}

function Build-Rnnoise-Main {
    $ProductName = "${ProductName}"
    if (!${ProductName}) {
        $ProductName = "rnnoise"
    }

    if (!${_RunObsDepsBuildScript}) {
        $CheckoutDir = "$(git rev-parse --show-toplevel)"
        . "${CheckoutDir}/CI/include/build_support_windows.ps1"

        Build-Checks
    }

    $ProductProject = "xiph"
    $ProductRepo = "rnnoise"
    $ProductFolder = "${ProductRepo}"

    if (!$Install) {
        Build-Setup-GitHub
        Build
    } else {
        Install-Product
    }
}

Build-Rnnoise-Main
