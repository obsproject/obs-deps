function Setup-Target {
    if ( ! ( Test-Path function:Log-Output ) ) {
        . $PSScriptRoot/Logger.ps1
    }

    $script:ConfigData = Get-ConfigData -Arch $script:Target
    $script:HostConfigData = Get-ConfigData -Arch $(Get-HostArchitecture)

    Log-Debug "
Architecture    : $($script:ConfigData.Arch)
CMake arch      : $($script:ConfigData.CmakeArch)
Unix arch       : $($script:ConfigData.UnixArch)
Target          : $($script:Target)
Output dir      : $($script:ConfigData.OutputPath)
Working dir     : $($script:WorkRoot)
Project dir     : $($script:ProjectRoot)
"
}

function Setup-BuildParameters {
    if ( ! ( Test-Path function:Log-Output ) ) {
        . $PSScriptRoot/Logger.ps1
    }

    $NumProcessors = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

    if ( $NumProcessors -gt 1 ) {
        $env:UseMultiToolTask = $true
        $env:EnforceProcessCountAcrossBuilds = $true
    }

    $VisualStudioData = Find-VisualStudio

    $VisualStudioId = "Visual Studio {0} {1}" -f @(
        ([System.Version] $VisualStudioData.Version).Major
        ( $VisualStudioData.Name -split ' ')[3]
    )

    $script:CmakeOptions = @(
        '-A', $script:ConfigData.CmakeArch
        '-G', $VisualStudioId
        "-DCMAKE_INSTALL_PREFIX=$($script:ConfigData.OutputPath)"
        "-DCMAKE_PREFIX_PATH=$($script:ConfigData.OutputPath)"
        "-DCMAKE_IGNORE_PREFIX_PATH=C:\Strawberry\c"
        "-DCMAKE_BUILD_TYPE=${script:Configuration}"
        '--no-warn-unused-cli'
    )

    $script:HostCmakeOptions = @(
        '-A', $script:HostConfigData.CmakeArch
        '-G', $VisualStudioId
        "-DCMAKE_INSTALL_PREFIX=$($script:ConfigData.OutputPath)"
        "-DCMAKE_PREFIX_PATH=$($script:ConfigData.OutputPath)"
        "-DCMAKE_IGNORE_PREFIX_PATH=C:\Strawberry\c"
        "-DCMAKE_BUILD_TYPE=${script:Configuration}"
        '--no-warn-unused-cli'
    )

    if ( $script:Quiet ) {
        $script:CmakeOptions += @(
            '-Wno-deprecated', '-Wno-dev', '--log-level=ERROR'
        )
        $script:HostCmakeOptions += @(
            '-Wno-deprecated', '-Wno-dev', '--log-level=ERROR'
        )
    }

    Log-Debug @"

CMake options   : $($script:CmakeOptions)
Multi-process   : ${NumProcessors}
"@
}

function Find-VisualStudio {
    <#
        .SYNOPSIS
            Finds available Visual Studio instance.
        .DESCRIPTION
            Uses WMI (Windows Management Instrumentation) to find an installed
            Visual Studio instance on the host system.
        .EXAMPLE
            Find-VisualStudio
    #>

    $VisualStudioData = Get-CimInstance MSFT_VSInstance

    # Prefer VS versions in this order:
    # 1. VS2022 Release (stable)
    # 2. VS2022 Preview
    # 3. VS2019 Release
    [string[]]$SupportedVSVersions =
        "VisualStudio.17.Release",
        "VisualStudio.17.Preview",
        "VisualStudio.16.Release"
    $NumSupportedVSVersions = $SupportedVSVersions.length

    if ( $VisualStudioData.GetType() -eq [object[]] ) {
        for ( $i = 0; $i -lt $NumSupportedVSVersions; $i++ ) {
            $VisualStudioDataTemp = ($VisualStudioData | Where-Object {$_.ChannelId -eq $SupportedVSVersions[$i]} | Sort-Object -Property Version)[0]
            if ( $VisualStudioDataTemp ) {
                break;
            }
        }
        $VisualStudioData = $VisualStudioDataTemp
    }

    if ( ! ( $VisualStudioData ) -or ( $VisualStudioData.Version -lt 16 ) ) {
        $ErrorMessage = @(
            "A Visual Studio installation (2019 or newer) is required for this build script.",
            "The Visual Studio Community edition is available for free at https://visualstudio.microsoft.com/vs/community/.",
            "",
            "If Visual Studio is indeed installed, locate the directory ",
            " 'C:\ProgramData\Microsoft\VisualStudio\Packages\Microsoft.VisualStudio.Setup.WMIProvider,Version=xxxx'",
            " right-click the file 'Microsoft.Visualstudio.Setup.WMIProvider.msi' and choose 'repair'."
        )

        throw $ErrorMessage
    }

    return $VisualStudioData
}

function Get-ConfigData {
    param (
        [string]
        $Arch
    )

    switch ($Arch) {
        'arm64' {
            return @{
                Arch              = 'arm64'
                UnixArch          = 'aarch64'
                CmakeArch         = 'ARM64'
                Bitness           = '64'
                OutputPath        = "${script:ProjectRoot}\windows\obs-${script:PackageName}-${script:Target}"
            } 
        }
        'x64' {
            return @{
                Arch              = 'x64'
                UnixArch          = 'x86_64'
                CmakeArch         = 'x64'
                Bitness           = '64'
                OutputPath        = "${script:ProjectRoot}\windows\obs-${script:PackageName}-${script:Target}"
            } 
        }
        'x86' {
            return @{
                Arch              = 'x86'
                UnixArch          = 'x86'
                CmakeArch         = 'Win32'
                Bitness           = '32'
                OutputPath        = "${script:ProjectRoot}\windows\obs-${script:PackageName}-${script:Target}"
            } 
        }
    }
}