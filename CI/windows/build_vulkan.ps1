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
# Windows Vulkan native-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

function Build-Product {
    cd "${DepsBuildDir}"

    Write-Step "Extract (${ARCH})..."
    if ("${BuildArch}" -eq "64-bit") {
        $VulkanArch = ""
    } elseif ("${BuildArch}" -eq "32-bit") {
        $VulkanArch = "32"
    }
    7z x ".\VulkanSDK-${ProductVersion}-Installer-Components.7z" -y -ovulkan "include\vulkan" -r "Lib${VulkanArch}\vulkan-1.lib"
}

function Install-Product {
    cd "${DepsBuildDir}"

    Write-Step "Install (${ARCH})..."
    if ("${BuildArch}" -eq "64-bit") {
        $VulkanArch = ""
    } elseif ("${BuildArch}" -eq "32-bit") {
        $VulkanArch = "32"
    }
    New-Item -Path "${CMAKE_INSTALL_DIR}\include\vulkan" -ItemType Directory -Force
    Copy-Item -Path "vulkan\Include\vulkan\*" -Destination "${CMAKE_INSTALL_DIR}\include\vulkan"
    Copy-Item -Path "vulkan\Lib${VulkanArch}\vulkan-1.lib" -Destination "${CMAKE_INSTALL_DIR}\lib"
}

function Build-Vulkan-Main {
    $ProductName = "${ProductName}"
    if (!${ProductName}) {
        $ProductName = "vulkan"
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

    #$ProductUrl = "https://sdk.lunarg.com/sdk/download/${ProductVersion}/windows/VulkanSDK-${ProductVersion}-Installer.exe"
    $ProductUrl = "https://cdn-fastly.obsproject.com/downloads/VulkanSDK-${ProductVersion}-Installer-Components.7z"

    if (!$Install) {
        Build-Setup -UseCurl
        Build
    } else {
        Install-Product
    }
}

Build-Vulkan-Main
