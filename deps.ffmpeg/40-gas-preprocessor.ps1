param(
    [string] $Name = 'gas-preprocessor',
    [string] $Version = '0.0.0',
    [string] $Uri = 'https://github.com/FFmpeg/gas-preprocessor.git',
    [string] $Hash = '9309c67acb535ca6248f092e96131d8eb07eefc1',
    [array] $Targets = @('arm64')
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

