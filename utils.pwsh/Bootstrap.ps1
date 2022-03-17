function Bootstrap {
    <#
        .SYNOPSIS
            Bootstraps an obs-deps build environment.
        .DESCRIPTION
            Prepares a build environment for obs-deps including build dependencies as well as
            configuration and target settings for requested dependencies. Enables multi-core
            builds with MSBuild if more than one (1) logical processor detected.
        .EXAMPLE
            Bootstrap
    #>

    $script:CurrentDate = Get-Date -Format 'yyyy-MM-dd'

    if ( $script:Target -eq '' ) { $script:Target = $script:HostArchitecture }

    Write-Host '---------------------------------------------------------------------------------------------------'
    Write-Host -NoNewLine '[OBS-DEPS] - configuration '
    Write-Host -NoNewLine -ForegroundColor Green $script:Configuration
    Write-Host -NoNewLine ', target '
    Write-Host -NoNewLine -ForegroundColor Green $script:Target
    Write-Host -NoNewLine ', shared libraries '
    if ( $script:Shared ) {
        Write-Host -ForegroundColor Green 'Yes'
    } else {
        Write-Host -ForegroundColor Red 'No'
    }
    Write-Host "Dependencies: $(if ( $script:Dependencies -eq $null ) { 'All' } else { $script:Dependencies })"
    Write-Host '---------------------------------------------------------------------------------------------------'

    Setup-Host
    Setup-Target
    Setup-BuildParameters
}

$Self = $MyInvocation.MyCommand.Name
