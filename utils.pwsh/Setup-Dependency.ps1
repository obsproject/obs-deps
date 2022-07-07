function Setup-Dependency {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Uri,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $DestinationPath,
        [string] $Hash,
        [string] $Branch,
        [string] $PullRequest
    )

    if ( ! ( Test-Path function:Invoke-GitCheckout ) ) {
        . "${PSScriptRoot}/Invoke-GitCheckout.ps1"
    }

    if ( ! ( Test-Path function:Invoke-SafeWebRequest ) ) {
        . "${PSScriptRoot}/Invoke-SafeWebRequest.ps1"
    }

    if ( ! ( Test-Path function:Expand-ArchiveExt ) ) {
        . "${PSScriptRoot}/Expand-ArchiveExt.ps1"
    }

    if ( [System.IO.Path]::GetExtension($Uri) -eq '.git' ) {
        $Params = @{
            Uri = $Uri
            Commit = $Hash
            Path = $DestinationPath
        }

        if ( $Branch -ne "" ) {
            $Params += @{Branch = $Branch}
        }

        if ( $PullRequest -ne "" ) {
            $Params += @{PullRequest = $PullRequest}
        }

        if ( ! ( $script:SkipUnpack ) ) {
            Invoke-GitCheckout  @Params
        }
    } else {
        $File = [System.IO.Path]::GetFileName($Uri)

        if ( $Hash -eq "") {
            throw "No checksum file for ${File} supplied."
        } elseif ( ! ( Test-Path $Hash ) ) {
            throw "Checksum file for ${File} not found."
        }

        $Params = @{
            Uri = $Uri
            HashFile = $Hash
            Resume = $true
        }

        if ( Test-Path $File ) {
            $Params += @{ CheckExisting = $true }
        }

        Invoke-SafeWebRequest @Params

        if ( ! ( $script:SkipUnpack ) ) {
            Expand-ArchiveExt -Path $File -Force
        }
    }
}
