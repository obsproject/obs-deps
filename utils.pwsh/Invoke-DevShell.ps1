function Invoke-DevShell {
    <#
        .SYNOPSIS
            Invokes a VSDevShell as a subshell and runs build commands in it.
        .DESCRIPTION
            To avoid polluting the host PowerShell environment, this function allows the dynamic
            creation of a scriptblock that runs inside a PowerShell subshell, which will find
            and setup a Visual Studio Dev Shell for the selected target architecture and start
            the supplied build command.
        .EXAMPLE
            Invoke-DevShell -BasePath . -BuildPath src -BuildCommand nmake -Target x86
            Invoke-DevShell -BasePath . -BuildPath src -BuildCommand "cmd /c msvcbuild.bat" -Target x64
    #>

    param(
        [Parameter(Mandatory)]
        [string] $BasePath,
        [Parameter(Mandatory)]
        [string] $BuildPath,
        [Parameter(Mandatory)]
        [string] $BuildCommand,
        [Parameter(Mandatory)]
        [ValidateSet('x86', 'x64')]
        [string] $Target,
        [string] $HostArchitecture = ( 'x86', 'x64' )[ [System.Environment]::Is64BitOperatingSystem ]
    )

    if ( ! ( Test-Path function:Log-Information ) ) {
        . $PSScriptRoot/Utils-Logger.ps1
    }

    if ( ! ( Test-Path variable:VisualStudioData ) ) {
        $VisualStudioData = Get-CimInstance MSFT_VSInstance
    }

    $DevShellCommand =
@"
`$ErrorActionPreference = 'Stop'

Import-Module '$($VisualStudioData.InstallLocation)/Common7/Tools/Microsoft.VisualStudio.DevShell.dll'

`$_Params = @{
    StartInPath = '${BasePath}'
    DevCmdArguments = '-arch=${Target} -host_arch=${HostArchitecture}'
    VsInstanceId = '$(($VisualStudioData.InstanceId -split ':')[2])'
}

Enter-VsDevShell @_Params

Set-Location ${BuildPath}
& ${BuildCommand}
if ( `$LASTEXITCODE -ne 0 ) {
    throw "${BuildCommand} failed with exit code `${LASTEXITCODE}
}
"@

    Log-Debug "Invoke-DevShell: `n${DevShellCommand}"

    $_EAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    if ($PSVersionTable.PSEdition -eq "Core") {
        $PowerShellCommand = "pwsh"
    } else {
        $PowerShellCommand = "powershell"
    }

    & $PowerShellCommand -Command $DevShellCommand

    $Result = $LASTEXITCODE

    $ErrorActionPreference = $_EAP

    if ( $Result -ne 0 ) {
        throw "${PowerShellCommand} exited with non-zero code ${Result}."
    }
}
