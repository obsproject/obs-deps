function Setup-Target {
    if ( ! ( Test-Path function:Log-Output ) ) {
        . $PSScriptRoot/Logger.ps1
    }

    $TargetData = @{
        x64 = @{
            Arch = 'x64'
            UnixArch = 'x86_64'
            CmakeArch = 'x64'
            Bitness = '64'
        }
        x86 = @{
            Arch = 'x86'
            UnixArch = 'x86'
            CmakeArch = 'Win32'
            Bitness = '32'
        }
        arm64 = @{
            Arch = 'arm64'
            UnixArch = 'aarch64'
            CmakeArch = 'ARM64'
            Bitness = '64'
        }
    }

    $script:ConfigData = $TargetData[$script:Target]

    $script:ConfigData += @{
        OutputPath = "${script:ProjectRoot}\windows\obs-${script:PackageName}-${script:Target}"
    }

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

    $VisualStudioData = Find-VisualStudio

    $VisualStudioId = "Visual Studio {0} {1}" -f @(
        $VisualStudioData.InstallationVersion.Major
        ($VisualStudioData.DisplayName -split ' ')[-1]
    )

    $script:CFlags = @()
    $script:CxxFlags = @()

    switch ( ${script:Configuration} ) {
        Debug {
            $script:CFlags += @(
                '-Ob0 -Od -RTC1'
            )
            $script:CxxFlags += @(
                '-Ob0 -Od -RTC1'
            )
        }
        RelWithDebInfo {
            $script:CFlags += @(
                '-O2 -Ob1 -DNDEBUG'
            )
            $script:CxxFlags += @(
                '-O2 -Ob1 -DNDEBUG'
            )
        }
        Release {
            $script:CFlags += @(
                '-O2 -Ob2 -DNDEBUG'
            )
            $script:CxxFlags += @(
                '-O2 -Ob2 -DNDEBUG'
            )
        }
        MinSizeRel {
            $script:CFlags += @(
                '-O1 -Ob1 -DNDEBUG'
            )
            $script:CxxFlags += @(
                '-O1 -Ob1 -DNDEBUG'
            )
        }
    }

    $script:CmakeOptions = @(
        '-A', $script:ConfigData.CmakeArch
        '-G', $VisualStudioId
        "-DCMAKE_INSTALL_PREFIX=$($script:ConfigData.OutputPath)"
        "-DCMAKE_PREFIX_PATH=$($script:ConfigData.OutputPath)"
        "-DCMAKE_IGNORE_PREFIX_PATH=C:\Strawberry\c"
        "-DCMAKE_BUILD_TYPE=${script:Configuration}"
        '--no-warn-unused-cli'
    )

    $script:CMakePostfix = @(
        '--'
        '/consoleLoggerParameters:Summary'
        '/noLogo'
        '/p:UseMultiToolTask=true'
        '/p:EnforceProcessCountAcrossBuilds=true'
    )

    if ( $script:Quiet ) {
        $script:CmakeOptions += @(
            '-Wno-deprecated', '-Wno-dev', '--log-level=ERROR'
        )
    }

    Log-Debug @"

C flags         : $($script:CFlags)
C++ flags       : $($script:CxxFlags)
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

    if ( $env:CI -eq $null ) {
        if ( ( Get-InstalledModule VSSetup ) -eq $null ) {
            Install-Module VSSetup -Scope CurrentUser
        }
    }

    $VisualStudioData = Get-VSSetupInstance -Prerelease:$($script:VSPrerelease) | Select-VSSetupInstance -Version '[16.0,18.0)' -Latest

    if ( $VisualStudioData -eq $null ) {
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
