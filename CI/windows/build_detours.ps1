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
# Windows Detours native-compile build script
################################################################################
#
# This script file can be included in build scripts for Windows or run directly
#
################################################################################

function Build-Product {
    cd "${DepsBuildDir}"

    Write-Step "Build (${ARCH})..."
    $VcvarsFile = "${script:VcvarsFolder}\vcvars${CMAKE_BITNESS}.bat"
    $DetoursSource = "${DepsBuildDir}\${ProductFolder}\src"
    $OriginalPath = $Env:Path
    $CleanPath = Get-UniquePath
    $Env:Path = $CleanPath
    cmd.exe /c """${VcvarsFile}"" & cd ""${DetoursSource}"" & nmake"
    $Env:Path = $OriginalPath
}

function Install-Product {
    cd "${DepsBuildDir}"

    Write-Step "Install (${ARCH})..."
    if ("${BuildArch}" -eq "64-bit") {
        $DetoursArch = "X64"
    } elseif ("${BuildArch}" -eq "32-bit") {
        $DetoursArch = "X86"
    }
    Copy-Item -Path "${DepsBuildDir}\${ProductFolder}\include\detours.h" -Destination "${CMAKE_INSTALL_DIR}\include\detours.h"
    Copy-Item -Path "${DepsBuildDir}\${ProductFolder}\lib.${DetoursArch}\detours.lib" -Destination "${CMAKE_INSTALL_DIR}\lib\detours.lib"
}

function Build-Detours-Main {
    $ProductName = "${ProductName}"
    if (!${ProductName}) {
        $ProductName = "detours"
    }

    if (!${_RunObsDepsBuildScript}) {
        $CheckoutDir = "$(git rev-parse --show-toplevel)"
        . "${CheckoutDir}/CI/include/build_support_windows.ps1"

        Build-Checks
    }

    $ProductProject = "microsoft"
    $ProductRepo = "Detours"
    $ProductFolder = "${ProductRepo}"

    if (!$Install) {
        Build-Setup-GitHub
        Build
    } else {
        Install-Product
    }
}

Build-Detours-Main
