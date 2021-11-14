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
# Windows mbedtls native-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

function Patch-Product {
    cd "${ProductFolder}"

    Write-Step "Apply patches..."
    Apply-Patch "${CheckoutDir}\CI\windows\patches\mbedtls\mbedtls-enable-alt-threading-01.patch" "306b8aaee8f291cc0dbd4cbee12ea185e722469eb06b8b7113f0a60feca6bbe6"

    if (!(Test-Path "include\mbedtls\threading_alt.h")) {
        Apply-Patch "${CheckoutDir}\CI\windows\patches\mbedtls\mbedtls-enable-alt-threading-02.patch" "d0dde0836dc6b100edf218207feffbbf808d04b1d0065082cdc5c838f8a4a7c7"
    }
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
        -DUSE_SHARED_MBEDTLS_LIBRARY=OFF `
        -DUSE_STATIC_MBEDTLS_LIBRARY=ON `
        -DENABLE_PROGRAMS=OFF `
        "${CMAKE_OPTS}" `
        -S "mbedtls" `
        -B "mbedtls_build\${CMAKE_BITNESS}"

    Write-Step "Build (${ARCH})..."
    cmake --build "mbedtls_build\${CMAKE_BITNESS}" --config "${BuildConfiguration}"
}

function Install-Product {
    cd "${DepsBuildDir}"

    Write-Step "Install (${ARCH})..."
    cmake --install "mbedtls_build\${CMAKE_BITNESS}" --config "${BuildConfiguration}" --prefix "${DepsBuildDir}\${CMAKE_INSTALL_DIR}"
}

function Build-Mbedtls-Main {
    $ProductName = "${ProductName}"
    if (!${ProductName}) {
        $ProductName = "mbedtls"
    }

    if (!${_RunObsDepsBuildScript}) {
        $CheckoutDir = "$(git rev-parse --show-toplevel)"
        . "${CheckoutDir}/CI/include/build_support_windows.ps1"

        Build-Checks
    }

    $ProductProject = "ARMmbed"
    $ProductRepo = "mbedtls"
    $ProductFolder = "${ProductRepo}"

    if (!$Install) {
        Build-Setup-GitHub
        Build
    } else {
        Install-Product
    }
}

Build-Mbedtls-Main
