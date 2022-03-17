function Invoke-SafeWebRequest {
    <#
        .SYNOPSIS
            Downloads a file using Invoke-WebRequest followed by a hash check.
        .DESCRIPTION
            After successfully downloading the file specified by the Uri,
            a corresponding FileHash object file is used to confirm the
            contents of the downloaded file.
        .EXAMPLE
            Invoke-SafeWebRequest -Uri "My-Uri" -HashFile "Path-To-HashFile"
            Invoke-SafeWebRequest -Uri "My-Uri" -HashFile "Path-To-HashFile" -Resume
            Invoke-SafeWebRequest -Uri "My-Uri" -HashFile "Path-To-HashFile" -OutFile "Name-Assumed-By-HashFile"
    #>

    param(
        [Parameter(Mandatory)]
        [string] $Uri,
        [Parameter(Mandatory)]
        [string] $HashFile,
        [System.Collections.Generic.Dictionary[string, string]] $Headers,
        [string] $OutFile = [System.IO.Path]::GetFileName($Uri),
        [switch] $Resume,
        [switch] $CheckExisting
    )

    if ( ! ( Test-Path function:Log-Information ) ) {
        . $PSScriptRoot/Utils-Logger.ps1
    }

    if ( $Resume -and $PSVersionTable.PSVersion -lt "6.1.0") {
        Log-Warning "-Resume only available on PowerShell 6.1.0 or later, disabling"
        $Resume = $false
    }

    if ( ! ( Test-Path $HashFile ) ) {
        throw "Provided hash file ${HashFile} not found."
    }

    try {
        $HashData = Import-Clixml $HashFile

        if ( ( $CheckExisting ) -and ( Test-Path $OutFile ) ) {
            $NewHash = Get-FileHash -Path $OutFile -Algorithm SHA256
        } else {
            $WebRequestParams = @{
                UserAgent = "NativeHost"
                Uri = $Uri
                OutFile = $OutFile
                UseBasicParsing = $true
                ErrorAction = "Stop"
            }

            if ( $Headers.Count -gt 0 ) {
                $WebRequestParams += @{Headers = $Headers}
            }

            Invoke-WebRequest @WebRequestParams

            $NewHash = Get-FileHash -Path $OutFile -Algorithm SHA256
        }
    } catch {
        throw "Error while downloading ${Uri}: ${PSItem}."
    }

    if ( $HashData.Hash -ne $NewHash.Hash ) {
        throw "Hash of downloaded file ${Uri} is '$($NewHash.Hash)' - expected '$($HashData.Hash)'."
    }

    if ( [System.IO.Path]::GetFileName($OutFile) -ne [System.IO.Path]::GetFileName($HashData.Path) ) {
        $Lines = @(
            "File name mismatch between downloaded file and name specified in checksum file:"
            '{0} vs {1}' -f $OutFile, $HashData.Path
        )

        Log-Warning @Lines
    }

    Log-Information "Hash of downloaded file ${Uri} confirmed as '$($HashData.Hash)'"
}
