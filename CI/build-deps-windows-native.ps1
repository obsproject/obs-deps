Param(
    [Switch]$Help = $(if (Test-Path variable:Help) { $Help }),
    [Switch]$Quiet = $(if (Test-Path variable:Quiet) { $Quiet }),
    [Switch]$Verbose = $(if (Test-Path variable:Verbose) { $Verbose }),
    [Switch]$NoChoco = $(if (Test-Path variable:NoChoco) { $NoChoco }),
    [Switch]$SkipDependencyChecks = $(if (Test-Path variable:SkipDependencyChecks) { $SkipDependencyChecks }),
    [String]$BuildDirectory = "build",
    [ValidateSet("32-bit", "64-bit")]
    [String]$BuildArch = (Get-CimInstance CIM_OperatingSystem).OSArchitecture,
    [ValidateSet("Release", "RelWithDebInfo", "MinSizeRel", "Debug")]
    [String]$BuildConfiguration = "RelWithDebInfo"
)

##############################################################################
# Windows OBS deps native build script
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
#   -SkipDependencyChecks   : Skip dependency checks
#   -NoChoco                : Skip automatic dependency installation
#                             via Chocolatey
#   -BuildDirectory         : Directory to use for builds
#                             Default: Win64 on 64-bit systems
#                                      Win32 on 32-bit systems
#   -BuildArch              : Build architecture to use (32-bit or 64-bit)
#   -BuildConfiguration     : Build configuration to use
#                             Default: RelWithDebInfo
#
##############################################################################

$ErrorActionPreference = "Stop"

$_ScriptName = "$($MyInvocation.MyCommand.Name)"
$_RunObsDepsBuildScript = $true
$ProductName = "obs-deps"

$CheckoutDir = git rev-parse --show-toplevel
$DepsBuildDir = "${CheckoutDir}\windows_native_build_temp"

. ${CheckoutDir}\CI\include\build_support_windows.ps1

$ObsBuildDependencies = @(
    @('mbedtls', '523f0554b6cdc7ace5d360885c3f5bbcc73ec0e8'),
    @('cmocka', '9c114ac31a33217cf003bbb674c1aff7bb048917'),
    @('freetype', '6a2b3e4007e794bfc6c91030d0ed987f925164a8'),
    @('curl', '315ee3fe75dade912b48a21ceec9ccda0230d937'),
    @('rnnoise', '90ec41ef659fd82cfec2103e9bb7fc235e9ea66c'),
    @('speexdsp', '20ed3452074664ad07e380e51321b148acebdf20'),
    @('detours', 'e4bfd6b03e50de46b47abfbd1e46b384f0c5f833'),
    @('luajit', '0bf80b07b0672ce874feedcc777afe1b791ccb5a'),
    @('python', '3.6.2'),
    @('vulkan', '1.2.131.2', '49d515f091d69c005a9e52e69829d28383fe157a764caebaa3dbc4b8d9bb383d'),
    @('nasm', '2.15.01'),
    @('swig', '3.0.12', '21ce6cbe297a56b697ef6e7e92a83e75ca41dedc87e48282ab444591986c35f5'),
    @('ntv2', 'abf17cc1e7aadd9f3e4972774a3aba2812c51b75')
)

function Build-OBS-Deps-Main {
    Ensure-Directory "${CheckoutDir}"
    Write-Step "Fetching version tags..."
    & git fetch origin --tags
    $GitBranch = git rev-parse --abbrev-ref HEAD
    $GitHash = git rev-parse --short HEAD
    $ErrorActionPreference = "SilentlyContinue"
    $GitTag = git describe --tags --abbrev=0
    $ErrorActionPreference = "Stop"

    Build-Checks

    if (!$CurrentDate) {
        $CurrentDate = Get-Date -UFormat "%Y-%m-%d"
    }
    $FileName = "${ProductName}-win-native-${CurrentDate}-${CMAKE_INSTALL_DIR}.tar.gz"

    if (!$SkipDependencyChecks) {
        Install-Dependencies -NoChoco:$NoChoco
    }

    Foreach ($Dependency in $ObsBuildDependencies) {
        if ($Dependency -is [system.array]) {
            $DepName = $Dependency[0]
            $DepVersion = $Dependency[1]
            if ($Dependency[2]) {
                $DepHash = $Dependency[2]
            } else {
                $DepHash = $DepVersion
            }
        } else {
            Write-Error "ObsBuildDependencies item Dependency is not array"
            exit 1
        }
        if (Test-CommandExists Build-Product) {
            Remove-Item -Path Function:Build-Product
        }
        if (Test-CommandExists Patch-Product) {
            Remove-Item -Path Function:Patch-Product
        }
        if (Test-CommandExists Install-Product) {
            Remove-Item -Path Function:Install-Product
        }

        Trap { Caught-Error "${DepName}" }

        Write-Step "Build dependency ${DepName}..."
        $ProductName = "${DepName}"
        $ProductVersion = "${DepVersion}"
        $ProductHash = "${DepHash}"
        . "${CheckoutDir}\CI\windows\build_${DepName}.ps1"
    }

    Write-Step "Create archive ${FileName}"
    cd "${DepsBuildDir}"
    tar -czf "${FileName}" -C "${CMAKE_INSTALL_DIR}" *

    Write-Info "All done!"
}

## MAIN SCRIPT FUNCTIONS ##
function Print-Usage {
    Write-Host "build-deps-windows-native.ps1 - Build script for ${ProductName}"
    $Lines = @(
        "Usage: ${_ScriptName}",
        "-Help                    : Print this help",
        "-Quiet                   : Suppress most build process output",
        "-Verbose                 : Enable more verbose build process output",
        "-SkipDependencyChecks    : Skip dependency checks - Default: off",
        "-NoChoco                 : Skip automatic dependency installation via Chocolatey - Default: off",
        "-BuildDirectory          : Directory to use for builds - Default: build64 on 64-bit systems, build32 on 32-bit systems",
        "-BuildArch               : Build architecture to use (32-bit or 64-bit) - Default: local architecture",
        "-BuildConfiguration      : Build configuration to use - Default: RelWithDebInfo"
    )
    $Lines | Write-Host
}

if ($Help) {
    Print-Usage
    exit 0
}

Build-OBS-Deps-Main
