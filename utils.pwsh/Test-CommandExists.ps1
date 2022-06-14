function Test-CommandExists {
    <#
        .SYNOPSIS
            Tests if the specified command is available on host system.
        .DESCRIPTION
            Checks whether the specified command is available on the host system. Returns a boolean result.
        .EXAMPLE
            Test-CommandExists git
    #>

    Param(
        [Parameter(Mandatory=$true)]
        [String] $Command
    )

    try {
        Get-Command $Command -ErrorAction "Stop"
    } catch {
        return $false
    }

    return $true
}
