function Check-GitUser {
    <#
        .SYNOPSIS
            Ensures that a git user is configured.
        .DESCRIPTION
            Checks whether a git user has been configured in a local repository. If not, configure a generic one.
        .EXAMPLE
            Check-GitUser
    #>

    if ( ! ( Test-Path function:Log-Information ) ) {
        . $PSScriptRoot/Logger.ps1
    }
    if ( ! ( Test-Path function:Invoke-External ) ) {
        . $PSScriptRoot/Invoke-External.ps1
    }

    Log-Information "Check git config for user..."

    $GitUserEmail = git config --get user.email
    if ( [string]::IsNullOrEmpty($GitUserEmail) ) {
        Log-Information "Set git user.email..."
        Invoke-External git config user.email "commits@obsproject.com"
    } else {
        Log-Information "Git user.email already set: ${GitUserEmail}"
    }

    $GitUserName = git config --get user.name
    if ( [string]::IsNullOrEmpty($GitUserName) ) {
        Log-Information "Set git user.name..."
        Invoke-External git config user.name "OBS Project"
    } else {
        Log-Information "Git user.name already set: ${GitUserName}"
    }
}
