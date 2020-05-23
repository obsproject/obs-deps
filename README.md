# obs-deps

Scripts to build and package dependencies for OBS on CI

# macOS (10.13+)

## Prerequisites

* Homebrew (https://brew.sh)
* Python 3 - either installed via homebrew (`brew install python`) or system-provided (macOS 10.15 Catalina)
* PyYAML - installed via `pip3 install pyyaml`

## Build steps

* Checkout `obs-deps` from Github:

```
git clone https://github.com/obsproject/obs-deps.git
```

* Enter the `obs-deps` directory
* Enter the `macos` directory
* Unpack pre-built dependencies to `/tmp` by running `tar -xf ./macos-deps-VERSION.tar.gz -C /tmp` (replace `VERSION` with the downloaded/desired version)
* Unpack pre-built Qt dependency to `/tmp` by running `tar -xf ./macos-qt-QT_VERSION-VERSION.tar.gz -C /tmp` (replace `QT_VERSION` and `VERSION` with the downloaded/desired versions)
* **IMPORTANT:** Remove the quarantine attribute from the downloaded Qt dependencies by running `xattr -r -d com.apple.quarantine /tmp/obsdeps`
* (*Optional*) Create the build scripts by running `./build_script_generator.py .github/workflows/build_deps.yml`
* Run `bash ./build-script-macos-01.sh` to build main dependencies
* Run `bash ./build-script-macos-02.sh` to build Qt dependency
