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
        . $PSScriptRoot/Logger.ps1
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

        $SupportedAlgorithms = @("SHA1", "SHA256", "SHA384", "SHA512", "MD5")
        if ( $HashData.Algorithm -and $SupportedAlgorithms.Contains($HashData.Algorithm) ) {
            $Algorithm = $HashData.Algorithm
        } else {
            $Algorithm = "SHA256"
        }

        if ( ( $CheckExisting ) -and ( Test-Path $OutFile ) ) {
            $NewHash = Get-FileHash -Path $OutFile -Algorithm $Algorithm
        } else {
            if ( $Headers.count -gt 0 ) {
                $HeaderStrings = @()

                $Headers.GetEnumerator() | ForEach-Object {
                    $Header = $_
                    $HeaderStrings += "-H `"$($Header.key): $($Header.Value)`""
                }
            }

            curl.exe -Lf $Uri -o $OutFile $($HeaderStrings -join " ")

            $NewHash = Get-FileHash -Path $OutFile -Algorithm $Algorithm
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
