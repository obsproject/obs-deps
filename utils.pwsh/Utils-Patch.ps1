function Run-PatchExe {
    <#
        .SYNOPSIS
            Runs patch.exe from installed Git toolchain.
        .DESCRIPTION
            Allows applying patch files to arbitray sets of files, enabling use of common POSIX
            switches.
        .EXAMPLE
            Run-PatchExe -g 0 -f p1 -i <Your-Patch-File>
    #>

    $Is64Bit = [System.Environment]::Is64BitOperatingSystem

    $GitBasePath = Resolve-Path -Path "$((Get-Command git).Source | Split-Path)\..\usr\bin"

    $PatchExe = "${GitBasePath}\patch.exe"

    if ( $PSVersionTable.PSVersion -ge '7.3.0' ) {
        Invoke-External $PatchExe --binary @args
    } else {
        Invoke-External cmd.exe /c ('"' + $PatchExe + '" --binary ' + $args -join ' ' -replace '/', '\')
    }
}

function Revert-Patch {
    <#
        .SYNOPSIS
            Reverts a patch.
        .DESCRIPTION
            Allows reverting the changes made by a patch file.
        .EXAMPLE
            Revert-Patch -PatchFile <Your-Patch-File>
            Revert-Patch -PatchFile <Your-Patch-File> -DryRun
    #>

    param(
        [Parameter(Mandatory)]
        [string] $PatchFile,
        [switch] $DryRun,
        [switch] $Silent
    )

    $Params = @(
        '-R', '-p1', '-N'
        $(if ( $DryRun ) { "--dry-run" })
        $(if ( $VerbosePreference -eq 'Continue' ) { "--verbose" })
        '-i', $PatchFile
    )

    if ( ( $PSVersionTable.PSVersion -lt '7.3.0' ) -and ( $Silent ) ) {
        $Params += @(" > NUL")
    }

    Log-Information "Reverting patch $([System.IO.Path]::GetFileName($PatchFile))"
    Run-PatchExe @Params
}

function Apply-Patch {
    <#
        .SYNOPSIS
            Applies a patch.
        .DESCRIPTION
            Allows applying the changes contained in a patch file.
        .EXAMPLE
            Apply-Patch -PatchFile <Your-Patch-File>
            Apply-Patch -PatchFile <Your-Patch-File> -DryRun
    #>

    param(
        [Parameter(Mandatory)]
        [string] $PatchFile,
        [switch] $DryRun,
        [switch] $Silent
    )

    $Params = @(
        '-g', '0', '-f', '-p1'
        $(if ( $DryRun ) { "--dry-run" })
        $(if ( $VerbosePreference -eq 'Continue' ) { "--verbose" })
        '-i', $PatchFile
    )

    if ( ( $PSVersionTable.PSVersion -lt '7.3.0' ) -and ( $Silent ) ) {
        $Params += @(" > NUL")
    }

    Log-Information "Applying patch $([System.IO.Path]::GetFileName($PatchFile))"
    Run-PatchExe @Params
}

function Safe-Patch {
    <#
        .SYNOPSIS
            Applies a patch with hash checking.
        .DESCRIPTION
            Allows applying a patch checked against a provided SHA256 checksum.
        .EXAMPLE
            Safe-Patch -PatchFile <You-Patch-File> -HashSum <HashSum>
            Safe-Patch -PatchFile <You-Patch-File> -HashSum <HashSum> -Path <Path-To-Apply-Patch-To>
    #>

    param(
        [Parameter(Mandatory)]
        [string] $PatchFile,
        [Parameter(Mandatory)]
        [string] $HashSum,
        [string] $Path
    )

    if ( ! ( Test-Path function:Log-Information ) ) {
        . $PSScriptRoot/Util-Logger.ps1
    }

    if ( $PatchFile.SubString(0, 5) -eq "https" ) {
        $WebRequestParams = @{
            UserAgent = "NativeHost"
            Uri = $PatchFile
            OutFile = [System.IO.Path]::GetFileName($PatchFile)
            UseBasicParsing = $true
            ErrorAction = "Stop"
        }

        Invoke-WebRequest @WebRequestParams
    } elseif  ( ! ( Test-Path $PatchFile ) ) {
        throw "Supplied patch file ${PatchFile} not found."
    }

    Push-Location -Stack SafePatchTemp

    $PatchHash = (Get-FileHash -Path $PatchFile -Algorithm SHA256).Hash

    if ( $HashSum -eq $PatchHash ) {
        Log-Information "Hash of patch file $([System.IO.Path]::GetFileName($PatchFile)) confirmed as '${HashSum}'"

        if ( $Path -ne "" ) {
            Set-Location -Path $Path
        }

        try {
            Revert-Patch -DryRun -Silent -PatchFile $PatchFile
        } catch {
            Apply-Patch -PatchFile $PatchFile
        }

        Pop-Location -Stack SafePatchTemp
    } else {
        Pop-Location -Stack SafePatchTemp

        throw "Hash of patch file ${PatchFile} is '${PatchHash}'. Expected '${HashSum}'."
    }
}
