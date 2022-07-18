function Check-Winget {
    <#
        .SYNOPSIS
            Ensures available winget installation on host system.
        .DESCRIPTION
            Checks whether winget is available on the system and install from Github releases.
        .EXAMPLE
            Check-Winget
    #>

    if ( ! ( Test-Path function:Log-Information ) ) {
        . $PSScriptRoot/Logger.ps1
    }

    if ( ! ( Test-Path function:Test-CommandExists ) ) {
        . $PSScriptRoot/Test-CommandExists.ps1
    }

    Log-Information 'Check for Winget'

    if ( ! ( Test-CommandExists winget ) ) {
        if ( ! ( Test-Path function:Invoke-SafeWebRequest ) ) {
            . $PSScriptRoot/Invoke-SafeWebRequest.ps1
        }

        Log-Warning 'Winget not found, attempting to install...'

        if ( ! ( Test-Path function:Ensure-Location ) ) {
            . $PSScriptRoot/Ensure-Location.ps1
        }

        Push-Location -Stack BuildTemp

        Ensure-Location -Path "${PSScriptRoot}/temp"

        $_RequiredPackages = @(
            'https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
            'https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/b0a0692da1034339b76dce1c298a1e42_License1.xml'
        )

        if ( $script:Target -eq 'x64' ) {
            $_RequiredPackages += @('https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx')
        } else {
            $_RequiredPackages += @('https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx')
        }

        $_RequiredPackages | Foreach-Object {
            $_Url = $_
            $_BaseName = [System.IO.Path]::GetFileName($_Url)
            $_HashFile = "${PSScriptRoot}/checksums/${_BaseName}.sha256"

            Invoke-SafeWebRequest -Uri $_Url -HashFile $_HashFile
        }

        $_Params = @{
            Online = $true
            PackagePath = './Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
            LicensePath = './b0a0692da1034339b76dce1c298a1e42_License1.xml'
            DependencyPackagePath = "$(if ( $script:Target -eq 'x64' ) { './Microsoft.VCLibs.x64.14.00.Desktop.appx' } else { './Microsoft.VCLibs.x86.14.00.Desktop.appx' })"
        }

        Add-AppxProvisionedPackage @_Params

        Pop-Location -Stack BuildTemp
    } else {
        Log-Debug "Winget found at $(Get-Command winget)"
        Log-Status 'Winget found'
    }
}
