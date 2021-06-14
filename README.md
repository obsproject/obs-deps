# obs-deps

Scripts to build and package dependencies for OBS on CI

## macOS (10.13+ for x86_64, 11.0 for arm64)

| lib | git commit | version |
| :--- | :---: | :---: |
|libpng|[Sourceforge](https://downloads.sourceforge.net/project/libpng/libpng16/1.6.37/libpng-1.6.37.tar.xz)|1.6.37|
|libopus|[GitHub](https://github.com/xiph/opus/tree/dfd6c88aaa54a03a61434c413e30c217eb98f1d5)|1.3.1-93-gdfd6c88a|
|libogg|[GitHub](https://github.com/xiph/ogg/releases/download/v1.3.5/libogg-1.3.5.tar.xz)|1.3.5|
|librnnoise|[90ec41e](https://github.com/xiph/rnnoise/commit/90ec41ef659fd82cfec2103e9bb7fc235e9ea66c)|Master branch|
|libvorbis|[xiph.org](https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz)|1.3.7|
|libvpx|[GitHub](https://github.com/webmproject/libvpx/archive/v1.10.0.tar.gz)|1.10.0|
|libjansson|[Petri Lehtinen](https://digip.org/jansson/releases/jansson-2.13.1.tar.gz)|2.13.1|
|libx264|[GitHub](https://github.com/mirror/x264/commit/b684ebe04a6f80f8207a57940a1fa00e25274f81)|r3059|
|libmbedtls|[GitHub](https://github.com/ARMmbed/mbedtls/archive/mbedtls-2.24.0.tar.gz)|2.24.0|
|libsrt|[GitHub](https://github.com/Haivision/srt/archive/v1.4.1.tar.gz)|1.4.1|
|libtheora|[xiph.org](https://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2)|1.1.1|
|ffmpeg|[ffmpeg.org](https://ffmpeg.org/releases/ffmpeg-4.2.3.tar.xz)|4.2.3|
|libluajit|[GitHub](https://github.com/LuaJIT/LuaJIT/commit/ec6edc5c39c25e4eb3fca51b753f9995e97215da)|2.1|
|libfreetype|[Sourceforge](https://downloads.sourceforge.net/project/freetype/freetype2/2.10.4/freetype-2.10.4.tar.xz)|2.10.4|
|Qt|[Qt.io](https://download.qt.io/official_releases/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz)|5.15.2|

### Notes

* FFmpeg is pinned to 4.2.3 as there was a bug introduced to HLS streaming functionality after that release, breaking important functionality for OBS
* libpng is patched for Apple M1 compatibility
* mbedtls is patched to enable `pthread` functionality
* SpeexDSP is patched to allow macOS 10.13 compatibility
* Qt is patched to cross-compile ARM64 on x86_64 hosts
* Qt is patched to fix https://bugreports.qt.io/browse/QTBUG-74606
* Qt is patched to fix https://bugreports.qt.io/browse/QTBUG-90370

### Prerequisites

* Homebrew (https://brew.sh)

### Build steps

* Checkout `obs-deps` from GitHub:

```
git clone https://github.com/obsproject/obs-deps.git
```

* Enter the `obs-deps` directory
* Run `bash ./CI/build-deps-macos.sh` to build main dependencies
* Run `bash ./CI/build-qt-macos.sh` to build Qt dependency

### Usage

* Create a destination directory for the dependencies (e.g. `obs-deps`)
* Unpack the dependencies into this directory (e.g. via `XZ_OPT=-T0 tar -xf macos-deps-VERSION-universal.tar.xz -C obs-deps` - replace `VERSION` with the downloaded/desired version)
* Repeat the same for the Qt dependencies
* **IMPORTANT:** Remove the quarantine attribute from the downloaded Qt dependencies by running `xattr -r -d com.apple.quarantine obs-deps`
* Use `obs-deps` as part of `CMAKE_PREFIX_PATH` when running `cmake` for OBS:

```
cmake -DCMAKE_PREFIX_PATH="some_other_path;obs-deps" [..]
```

## Contributing

* Add/edit seperate build scripts for every dependency in the `CI/[OPERATING SYSTEM/` directory
* For new dependencies:
    * Create the `sha256sum` of the downloaded dependency archive
    * Add the dependency version as `[DEPENDENCY_NAME]_VERSION` and the downloaded archive hash as `[DEPENDENCY_NAME]_HASH` to the GitHub actions workflow in `.github/workflows/main.yml` as well as the main build script in `CI/build-deps-macos.sh`.
* For existing dependencies:
    * Always update the `sha256sum` of the updated dependency archive as well as the version
* Patches need to be placed either in the patches directory (if applied for all OS) or inside the patches directory for a specific OS
    * Generate patches by running `diff -Naur [OLD_FILE] [NEW_FILE]`
    * Fixup paths in the patch file to a path relative from the dependency's source directory, e.g `./src/FILE.c` (the `./` is important)
