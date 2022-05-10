# obs-deps

This repository is a collection of build scripts to build OBS dependencies for macOS and Windows.

## Windows

OBS dependencies for Windows can be built via the `Build-Dependencies.ps1` PowerShell script. For best compatibility, it is advised to use a recent version of PowerShell Core (pwsh). Older versions of PowerShell might work, but support for these is not provided.

## macOS

OBS dependencies for macOS can be built via the `build-deps.zsh` Zsh-script. Zsh is the default interactive shell on macOS starting with macOS 10.15, the minimum version supported for building OBS. Both Intel and Apple Silicon are supported.

## FFmpeg

FFmpeg can be built via the `build-ffmpeg.zsh` Zsh-script. FFmpeg can be compiled natively on macOS and Linux, and cross-compiled on Linux for Windows. In the latter case, specify a Windows-based target (e.g., `Windows-x64`) to enable cross-compilation. On macOS, both Intel and Apple Silicon are supported.

## Qt

Qt can be built via the `build-qt.zsh` Zsh-script. Qt can be compiled natively on macOS for Intel and Apple Silicon.

## More Information

Further details can be found in the [Wiki Pages](https://github.com/obsproject/obs-deps/wiki).

## Contributing

* Add/edit separate build scripts in the appropriate subdirectory (e.g., `deps.ffmpeg` for FFmpeg and associated build dependencies)
* Ensure that either a valid Git commit hash is specified or a checksum file for a downloaded artifact has been placed in the `checksums` subdirectory
* If patches are necessary, ensure those are placed in a directory with the same name of the dependency inside the `patches` directory
* Name patches numerically padded to 4 digits (e.g., `0001`) and with a descriptive name
