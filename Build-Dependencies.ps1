[CmdletBinding()]
param(
    [ValidateSet('Debug', 'RelWithDebInfo', 'Release', 'MinSizeRel')]
    [string] $Configuration = 'Release',
    [ValidateSet('dependencies', 'ffmpeg', 'qt')]
    [string] $PackageName = 'dependencies',
    [string[]] $Dependencies,
    [ValidateSet('arm64', 'x64', 'x86')]
    [string] $Target,
    [switch] $Clean,
    [switch] $Quiet,
    [switch] $Shared,
    [switch] $SkipAll,
    [switch] $SkipBuild,
    [switch] $SkipDeps,
    [switch] $SkipUnpack,
    [switch] $VSPrerelease
)

$ErrorActionPreference = "Stop"

if ( $DebugPreference -eq "Continue" ) {
    $VerbosePreference = "Continue"
    $InformationPreference = "Continue"
}

if ( $PSVersionTable.PSVersion -lt '7.2.0' ) {
    Write-Warning 'The obs-deps PowerShell build script requires PowerShell Core 7.2+. Install or upgrade your PowerShell version: https://aka.ms/pscore6'
    exit 0
}

function Run-Stages {
    $Stages = @('Setup')

    if ( ( $SkipAll ) -or ( $SkipBuild ) ) {
        $Stages += @('Install', 'Fixup')
    } else {
        if ( $Clean ) {
            $Stages += 'Clean'
        }
        $Stages += @(
            'Patch'
            'Configure'
            'Build'
            'Install'
            'Fixup'
        )
    }

    Log-Debug $DependencyFiles

    $DependencyFiles | Sort | ForEach-Object {
        $Dependency = $_

        $Version = 0
        $Uri = ''
        $Hash = ''
        $Path = ''
        $Versions = @()
        $Hashes = @()
        $Uris = @()
        $Patches = @()
        $Options = @{}
        $Targets = @($script:Target)

        . $Dependency

        if ( ! ( $Targets.contains($Target) ) ) {
            $Stages | ForEach-Object {
                Log-Debug "Removing function $_"
                Remove-Item -ErrorAction 'SilentlyContinue' function:$_
                $script:StageName = ''
            }

            return
        }

        if ( $Version -eq '' ) { $Version = $Versions[$Target] }
        if ( $Uri -eq '' ) { $Uri = $Uris[$Target] }
        if ( $Hash -eq '' ) { $Hash = $Hashes[$Target] }

        if ( $Path -eq '' ) { $Path = [System.IO.Path]::GetFileNameWithoutExtension($Uri) }

        Log-Output 'Initializing build'

        $Stages | ForEach-Object {
            $Stage = $_
            $script:StageName = $Name
            try {
                Push-Location -Stack BuildTemp
                if ( Test-Path function:$Stage ) {
                    . $Stage
                }
            } catch {
                Pop-Location -Stack BuildTemp
                Log-Error "Error during build step ${Stage} - $_"
            } finally {
                $StageName = ''
                Pop-Location -Stack BuildTemp
            }
        }

        $Stages | ForEach-Object {
            Log-Debug "Removing function $_"
            Remove-Item -ErrorAction 'SilentlyContinue' function:$_
            $script:StageName = ''
        }

        if ( Test-Path "$PSScriptRoot/licenses/${Name}" ) {
            Log-Information "Install license files"

            $null = New-Item -ItemType Directory -Path "$($ConfigData.OutputPath)/licenses" -ErrorAction SilentlyContinue
            Copy-Item -Path "$PSScriptRoot/licenses/${Name}" -Recurse -Force -Destination "$($ConfigData.OutputPath)/licenses"
        }
    }
}

function Package-Dependencies {
    Push-Location -Stack BuildTemp -Path $ConfigData.OutputPath

    Log-Information "Cleanup unnecessary files"

    switch ( $PackageName ) {
        ffmpeg {
            Get-ChildItem ./bin/* -Include '*.exe','srt-ffplay' -Exclude 'ffmpeg.exe','ffprobe.exe' | Remove-Item -Force -Recurse
            Get-ChildItem ./lib -Exclude 'librist.lib','zlibstatic.lib','srt.lib','libx264.lib','mbed*.lib','everest.lib','p256m.lib','zlib.lib','datachannel.lib','cmake' | Remove-Item -Force -Recurse
            Get-ChildItem ./lib/cmake -Exclude 'LibDataChannel','MbedTLS' | Remove-Item -Force -Recurse
            Get-ChildItem ./share/* | Remove-Item -Force -Recurse
            Get-ChildItem ./bin/*.lib | Move-Item -Destination ./lib
            Get-ChildItem -Attribute Directory -Recurse -Include 'pkgconfig' | Remove-Item -Force -Recurse
            $ArchiveFileName = "windows-ffmpeg-${CurrentDate}-${Target}.zip"
        }
        dependencies {
            Get-ChildItem ./bin/*.lib | Move-Item -Destination ./lib
            Get-ChildItem ./bin -Exclude 'lua51.dll','libcurl.dll','swig.exe','Lib' | Remove-Item

            if ( $script:Target -ne 'x86' ) {
                Get-ChildItem ./cmake/pcre2*,./lib/pcre2* | Remove-Item
                Remove-Item -Recurse ./lib/pkgconfig
                Remove-Item -Recurse ./man
                Get-ChildItem ./share -Exclude 'cmake' | Remove-Item -Recurse
                Get-ChildItem ./share/cmake -Exclude 'nlohmann_json*' | Remove-Item -Recurse
            }

            $ArchiveFileName = "windows-deps-${CurrentDate}-${Target}.zip"
        }
        qt {
            $ArchiveFileName = "windows-deps-qt6-${CurrentDate}-${Target}-${Configuration}.zip"
        }
    }

    $Params = @{
        ErrorAction = "SilentlyContinue"
        Path = @(
            "share/obs-deps"
        )
        ItemType = "Directory"
        Force = $true
    }

    New-Item @Params *> $null

    Get-Date -Format "yyyy-MM-dd" | Set-Content -Path share/obs-deps/VERSION

    Log-Information "Package dependencies"

    $Params = @{
        Path = (Get-ChildItem -Exclude $ArchiveFileName)
        DestinationPath = $ArchiveFileName
        CompressionLevel = "Optimal"
    }

    Log-Information "Create archive ${ArchiveFileName}"
    Compress-Archive @Params

    Move-Item -Force -Path $ArchiveFileName -Destination (Split-Path -Parent (Get-Location))

    Pop-Location -Stack BuildTemp
}

function Build-Main {
    trap {
        Write-Host '---------------------------------------------------------------------------------------------------'
        Write-Host -NoNewLine '[OBS-DEPS] '
        Write-Host -ForegroundColor Red 'Error(s) occurred:'
        Write-Host '---------------------------------------------------------------------------------------------------'
        Write-Error $_
        exit 2
    }

    $UtilityFunctions = Get-ChildItem -Path $PSScriptRoot/utils.pwsh/*.ps1 -Recurse

    foreach($Utility in $UtilityFunctions) {
        Write-Debug "Loading $($Utility.FullName)"
        . $Utility.FullName
    }

    Bootstrap

    $SubDir = if ( $PackageName -eq 'dependencies' ) {
        'deps.windows'
    } else {
        "deps.${PackageName}"
    }

    if ( $Dependencies.Count -eq 0 ) {
        $DependencyFiles = Get-ChildItem -Path $PSScriptRoot/${SubDir}/*.ps1 -File -Recurse
    } else {
        $DependencyFiles = $Dependencies | ForEach-Object {
            $Item = $_
            try {
                Get-ChildItem $PSScriptRoot/${SubDir}/*$Item.ps1
            } catch {
                throw "Script for requested dependency ${Item} not found"
            }
        }
    }

    Log-Debug "Using found dependency scripts:`n${DependencyFiles}"

    Push-Location -Stack BuildTemp

    Ensure-Location $WorkRoot

    Run-Stages

    Pop-Location -Stack BuildTemp

    if ( $Dependencies.Count -eq 0 -or $PackageName -eq 'qt' ) {
        if ( Test-Path -Path $ConfigData.OutputPath ) {
            Package-Dependencies
        }
    }

    Write-Host '---------------------------------------------------------------------------------------------------'
    Write-Host -NoNewLine '[OBS-DEPS] '
    Write-Host -ForegroundColor Green 'All done'
    Write-Host "Built Dependencies: $(if ( $Dependencies -eq $null ) { 'All' } else { $Dependencies })"
    Write-Host '---------------------------------------------------------------------------------------------------'
}

Build-Main
