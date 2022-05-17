param(
    [string] $Name = 'pyenv',
    [string] $Version = '2.64.11',
    [string] $Uri = 'https://github.com/pyenv-win/pyenv-win.git',
    [string] $Hash = '404cd4bdd0dff3a8650c890fa59a3761f328f36b',
    [hashtable] $PythonVersion = @{
         x86 = '3.6.2-win32'
         x64 = '3.6.2'
    }
)

function Enable-PyEnv {
    $Env:PYENV = "$(Get-Location | Convert-Path)\pyenv-win"
    $Env:PYENV_ROOT = $Env:PYENV
    $Env:PYENV_HOME = $Env:PYENV

    $Env:OriginalPath = $Env:Path

    $PathElements = ([Collections.Generic.HashSet[string]]::new([string[]]($Env:Path -split [System.IO.Path]::PathSeparator), [StringComparer]::OrdinalIgnoreCase))

    $PyEnvPaths = @(
        "${Env:PYENV}\bin"
        "${Env:PYENV}\bin\shims"
    )
    $Env:Path = ($PyEnvPaths + $PathElements) -join [System.IO.Path]::PathSeparator

    $null = Invoke-External pyenv rehash
}

function Disable-PyEnv {
    $Env:Path = $Env:OriginalPath

    Remove-Item Env:OriginalPath
    Remove-Item Env:PYENV
    Remove-Item Env:PYENV_ROOT
    Remove-Item Env:PYENV_HOME
}

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    Enable-PyEnv

    $Params = @(
        "install"
        $PythonVersion[$Target]
        $(($null, '--quiet')[ $Quiet.isPresent ])
    )

    & pyenv @Params

    Disable-PyEnv
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    Enable-PyEnv

    & pyenv shell $PythonVersion[$Target]

    $PythonBinary = & pyenv which python
    $PythonPath = Split-Path -Path $PythonBinary

    Disable-PyEnv

    $Params = @{
        ErrorAction = "SilentlyContinue"
        Path = @(
            "$($ConfigData.OutputPath)/include/python"
            "$($ConfigData.OutputPath)/bin"
            "$($ConfigData.OutputPath)/lib"
        )
        ItemType = "Directory"
        Force = $true
    }

    New-Item @Params *> $null

    $Items = @(
        @{
            Path = "${PythonPath}/include/*"
            Destination = "$($ConfigData.OutputPath)/include/python/"
            Recurse = $true
        }
        @{
            Path = "${PythonPath}/libs/python3*.lib"
            Destination = "$($ConfigData.OutputPath)/lib/"
        }
    )

    if ( $script:Shared ) {
        $Items += @{
            Path = "${PythonPath}/python3*.dll"
            Destination = "$($ConfigData.OutputPath)/bin/"
        }
    }

    $Items | ForEach-Object {
        $Item = $_
        Log-Output ('{0} => {1}' -f ($Item.Path -join ", "), $Item.Destination)
        Copy-Item @Item
    }
}
