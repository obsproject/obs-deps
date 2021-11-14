##############################################################################
# Windows native-compile support functions
##############################################################################
#
# This script file can be included in PowerShell build scripts for Windows.
#
##############################################################################

$CIWorkflow = "${CheckoutDir}/.github/workflows/windows_deps.yml"

$CIWorkflowJobString = Get-Content ${CIWorkflow} -Raw | Select-String "(?s)(  windows-deps-build-native.+?)\n    steps:" | ForEach-Object{$_.Matches.Groups[1].Value}

$CIDepsVersion = Get-Content ${CIWorkflow} | Select-String "[ ]+DEPS_VERSION_WIN: '([0-9\-]+)'" | ForEach-Object{$_.Matches.Groups[1].Value}

$BuildDirectory = "$(if (Test-Path Env:BuildDirectory) { $env:BuildDirectory } else { $BuildDirectory })"
$BuildArch = "$(if (Test-Path Env:BuildArch) { $env:BuildArch } else { $BuildArch })"
$BuildConfiguration = "$(if (Test-Path Env:BuildConfiguration) { $env:BuildConfiguration } else { $BuildConfiguration })"

$WindowsDepsVersion = "$(if (Test-Path Env:WindowsDepsVersion ) { $env:WindowsDepsVersion } else { $CIDepsVersion })"
$CmakeSystemVersion = "$(if (Test-Path Env:CMAKE_SYSTEM_VERSION) { $Env:CMAKE_SYSTEM_VERSION } else { "10.0.18363.657" })"

function Write-Status {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $output
    )

    if (!$Quiet) {
        if (Test-Path Env:CI) {
            Write-Host "[${ProductName}] ${output}"
        } else {
            Write-Host -ForegroundColor blue "[${ProductName}] ${output}"
        }
    }
}

function Write-Info {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $output
    )

    if (!$Quiet) {
        if (Test-Path Env:CI) {
            Write-Host " + ${output}"
        } else {
            Write-Host -ForegroundColor DarkYellow " + ${output}"
        }
    }
}

function Write-Step {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $output
    )

    if (!$Quiet) {
        if (Test-Path Env:CI) {
            Write-Host " + ${output}"
        } else {
            Write-Host -ForegroundColor green " + ${output}"
        }
    }
}

function Write-Error {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $output
    )

    if (Test-Path Env:CI) {
        Write-Host " + ${output}"
    } else {
        Write-Host -ForegroundColor red " + ${output}"
    }
}

function Test-CommandExists {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $Command
    )

    $CommandExists = $false
    $OldActionPref = $ErrorActionPreference
    $ErrorActionPreference = "Stop"

    try {
        if (Get-Command $Command) {
            $CommandExists = $true
        }
    } Catch {
        $CommandExists = $false
    } Finally {
        $ErrorActionPreference = $OldActionPref
    }

    return $CommandExists
}

function Remove-ItemIfExists {
    Param(
        [Parameter(Mandatory)]
        [String[]] $Path
    )

    Foreach ($Item in $Path) {
        $RecurseValue = $false
        if (Test-Path "${Item}" -PathType "Container") {
            $RecurseValue = $true
        }
        if (Test-Path "${Item}") {
            Remove-Item -Path "${Item}" -Force -Recurse:$RecurseValue
        }
    }
}

function Ensure-Directory {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $Directory
    )

    if (!(Test-Path $Directory)) {
        $null = New-Item -ItemType Directory -Force -Path $Directory
    }

    Set-Location -Path $Directory
}

function Cleanup {
}

function Caught-Error {
    Write-Error "ERROR during build step: $($args[0])"
    Cleanup
    exit 1
}

function Install-Windows-Build-Tools {
    Write-Status "Check Windows build tools"

    $ObsBuildDependencies = @(
        @("7z", "7zip"),
        @("cmake", "cmake --install-arguments 'ADD_CMAKE_TO_PATH=System'"),
        @("pyenv", "pyenv-win")
    )

    if (!(Test-CommandExists "choco")) {
        Write-Step "Install Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }

    Foreach($Dependency in $ObsBuildDependencies) {
        if ($Dependency -is [system.array]) {
            $Command = $Dependency[0]
            $ChocoName = $Dependency[1]
        } else {
            $Command = $Dependency
            $ChocoName = $Dependency
        }

        if ((Test-CommandExists "${Command}")) {
            Write-Status "Has ${Command}"
        } else {
            Write-Step "Install dependency ${ChocoName}..."
            Invoke-Expression "choco install -y ${ChocoName}"
        }
    }

    $Env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    refreshenv
    pyenv rehash
}

function Install-Dependencies {
    if (!$NoChoco) {
        Install-Windows-Build-Tools
    }
}

function Get-Basename {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $Path
    )

    $Separators = "\/"
    $SepArray = $Separators.ToCharArray()
    return ${Path}.Substring(${Path}.LastIndexOfAny($SepArray) + 1)
}

function Get-UniquePath {
    $OriginalPathString = $Env:Path
    $OriginalPath = $OriginalPathString -split ';'
    # Sort-Object -Unique is case-insensitive
    # Select-Object -Unique is case-sensitive
    # See https://github.com/PowerShell/PowerShell/issues/12059
    $UniquePath = $OriginalPath | Sort-Object -Unique
    $NewPathArray = @()
    $OriginalPath | ForEach-Object {
        if (($_ -in $UniquePath) -and ($_ -notin $NewPathArray)) {
            $NewPathArray += $_
        }
    }

    $NewPath = $NewPathArray -join ';'

    return $NewPath
}

function Safe-Fetch {
    Param(
        [Switch] $UseCurl,
        [Switch] $CurlNoContinue,
        [Parameter(Mandatory=$true)]
        [String] $DOWNLOAD_URL,
        [Parameter(Mandatory=$true)]
        [String] $DOWNLOAD_HASH
    )
    if ($PSBoundParameters.Count -lt 2) {
        Caught-Error "Usage: Safe-Fetch URL HASH"
    }

    $DOWNLOAD_FILE = Get-Basename "${DOWNLOAD_URL}"

    if ($UseCurl) {
        $CurlCmd = $script:CURLCMD

        if ($CurlNoContinue) {
            $CurlCmd = $CurlCmd.Replace(" --continue-at -", "") + " ${DOWNLOAD_URL}"
        } else {
            $CurlCmd = "${CurlCmd} ${DOWNLOAD_URL}"
        }

        Invoke-Expression "${CurlCmd}"
    } else {
        Invoke-WebRequest -Uri "${DOWNLOAD_URL}" -UseBasicParsing -OutFile "${DOWNLOAD_FILE}"
    }

    $CalculatedHash = $(Get-FileHash ${DOWNLOAD_FILE}).Hash
    if ("${DOWNLOAD_HASH}" -eq "${CalculatedHash}") {
        Write-Info "${DOWNLOAD_FILE} downloaded successfully and passed hash check"
        return 0
    } else {
        Write-Error "${DOWNLOAD_FILE} downloaded successfully and failed hash check"
        Write-Warning "Expected Hash:   ${DOWNLOAD_HASH}"
        Write-Warning "Calculated Hash: ${CalculatedHash}"
        return 1
    }
}

function Check-And-Fetch {
    Param(
        [Switch] $UseCurl,
        [Switch] $CurlNoContinue,
        [Parameter(Mandatory=$true)]
        [String] $DOWNLOAD_URL,
        [Parameter(Mandatory=$true)]
        [String] $DOWNLOAD_HASH
    )
    if ($PSBoundParameters.Count -lt 2) {
        Caught-Error "Usage: Check-And-Fetch URL HASH"
    }

    $DOWNLOAD_FILE = Get-Basename "${DOWNLOAD_URL}"

    if ($(Test-Path "${DOWNLOAD_FILE}") -and $("${DOWNLOAD_HASH}" -eq $(Get-FileHash ${DOWNLOAD_FILE}).Hash)) {
        Write-Info "${DOWNLOAD_FILE} exists and passed hash check"
        return 0
    } else {
        Safe-Fetch -UseCurl:$UseCurl -CurlNoContinue:$CurlNoContinue "${DOWNLOAD_URL}" "${DOWNLOAD_HASH}"
    }
}

function Git-Checkout-Pull-Request {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $PR_NUM
    )

    if (!(Test-Path "./.git")) {
        Write-Error "There is no git repository in this directory."
        exit 1
    }

    if (git show-ref --quiet --verify refs/heads/pr-$PR_NUM) {
        Write-Info "Local branch pr-$PR_NUM already exists"
    } else {
        git fetch origin pull/$PR_NUM/head:pr-$PR_NUM
    }
    git checkout pr-$PR_NUM
}

function Git-Fetch {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $GIT_HOST,
        [Parameter(Mandatory=$true)]
        [String] $GIT_USER,
        [Parameter(Mandatory=$true)]
        [String] $GIT_REPO,
        [Parameter(Mandatory=$true)]
        [String] $GIT_REF
    )
    if ($PSBoundParameters.Count -ne 4) {
        Write-Error "Usage: Git-Fetch GIT_HOST GIT_USER GIT_REPOSITORY GIT_REF"
        exit 1
    }

    $GIT_HOST = $GIT_HOST.TrimEnd("/")

    if (Test-Path "./.git") {
        Write-Info "Repository ${GIT_USER}/${GIT_REPO} already exists, updating..."
        git config advice.detachedHead false
        git config remote.origin.url "${GIT_HOST}/${GIT_USER}/${GIT_REPO}.git"
        git config remote.origin.fetch "+refs/heads/master:refs/remotes/origin/master"
        git config remote.origin.tapOpt --no-tags

        if (!(git rev-parse -q --verify "${GIT_REF}^{commit}")) {
            git fetch origin
        }

        Write-Info "Checking out commit ${GIT_REF}..."
        git checkout -f "${GIT_REF}" --
        git reset --hard "${GIT_REF}" --
        if (Test-Path "./.gitmodules") {
            git submodule foreach --recursive git submodule sync
            git submodule update --init --recursive
        }
    } else {
        git clone "${GIT_HOST}/${GIT_USER}/${GIT_REPO}.git" "$(pwd)"
        git config advice.detachedHead false
        Write-Info "Checking out commit ${GIT_REF}..."
        git checkout -f "${GIT_REF}" --

        if (Test-Path "./.gitmodules") {
            git submodule foreach --recursive git submodule sync
            git submodule update --init --recursive
        }
    }
}

function GitHub-Fetch {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $GH_USER,
        [Parameter(Mandatory=$true)]
        [String] $GH_REPO,
        [Parameter(Mandatory=$true)]
        [String] $GH_REF
    )
    if ($PSBoundParameters.Count -ne 3) {
        Write-Error "Usage: GitHub-Fetch GITHUB_USER GITHUB_REPOSITORY GITHUB_REF"
        return 1
    }

    Git-Fetch "https://github.com" "${GH_USER}" "${GH_REPO}" "${GH_REF}"
}

function GitLab-Fetch {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $GL_USER,
        [Parameter(Mandatory=$true)]
        [String] $GL_REPO,
        [Parameter(Mandatory=$true)]
        [String] $GL_REF
    )
    if ($PSBoundParameters.Count -ne 3) {
        Write-Error "Usage: GitLab-Fetch GITLAB_USER GITLAB_REPOSITORY GITLAB_REF"
        return 1
    }

    Git-Fetch "https://gitlab.com" "${GL_USER}" "${GL_REPO}" "${GL_REF}"
}

function Apply-Patch {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $COMMIT_URL,
        [Parameter(Mandatory=$true)]
        [String] $COMMIT_HASH
    )

    $PATCH_FILE = Get-Basename "${COMMIT_URL}"

    if ("${COMMIT_URL}".Substring(0, 5) -eq "https") {
        Invoke-WebRequest "${COMMIT_URL}" -UseBasicParsing -OutFile "${PATCH_FILE}"
        if ("${COMMIT_HASH}" -eq $(Get-FileHash ${PATCH_FILE}).Hash) {
            Write-Info "${PATCH_FILE} downloaded successfully and passed hash check"
        } else {
            Write-Error "${PATCH_FILE} downloaded successfully and failed hash check"
            return 1
        }
    } else {
        $PATCH_FILE = "${COMMIT_URL}"
    }

    Write-Info "Applying patch ${PATCH_FILE}"

    if (Test-Path "./.git") {
        git apply "${PATCH_FILE}"
    } else {
        # TODO: patch failed in my tests, hence using git apply above
        patch -g 0 -f -p1 -i "${PATCH_FILE}"
    }
}

function Check-Archs {
    Write-Step "Check Architecture..."

    if ("${BuildArch}" -eq "64-bit") {
        $script:ARCH = "x86_64"
        $script:CMAKE_ARCH = "x64"
        $script:CMAKE_BITNESS = "64"
        $script:CMAKE_INSTALL_DIR = "win64"
    } elseif ("${BuildArch}" -eq "32-bit") {
        $script:ARCH = "x86"
        $script:CMAKE_ARCH = "Win32"
        $script:CMAKE_BITNESS = "32"
        $script:CMAKE_INSTALL_DIR = "win32"
    } else {
        Caught-Error "Unsupported architecture '${BuildArch}' provided"
    }
}

function Check-Curl {
    if (!(Test-CommandExists "curl.exe") -and !$NoChoco) {
        Write-Step "Install curl from chocolatey..."
        Invoke-Expression "choco install -y curl"
    }

    # TODO: implement a way to force using/installing curl.exe from chocolatey
    #       "C:\ProgramData\chocolatey\bin\curl.exe"
    $CURLCMD = "C:\Windows\System32\curl.exe"

    if ($Env:CI -or $Quiet) {
        $script:CURLCMD = "${CURLCMD} --silent --show-error --location -O"
    } else {
        $script:CURLCMD = "${CURLCMD} --progress-bar --location --continue-at - -O"
    }
}

function Check-Visual-Studio {
    Param(
        [switch]$Force
    )
    Trap { Caught-Error "Check-Visual-Studio" }

    Write-Step "Check Visual Studio..."
    if ($script:VisualStudioFound -and !$Force) {
        Write-Info "Visual Studio already found"
        Write-Status "Visual Studio Installation Path: ${script:VisualStudioPath}"
        return
    }

    $script:VisualStudioFound = $false
    $VswhereDefaultLocation = "${ENV:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-CommandExists "Get-VSSetupInstance") {
        # for VS2019 and newer: -Version '16.0'
        $script:VisualStudioPath = (Get-VSSetupInstance | Select-VSSetupInstance -Version '[16.0,17.0)').InstallationPath
    } elseif (Test-CommandExists "${VswhereDefaultLocation}") {
        # for VS2019 and newer: -version 16
        $script:VisualStudioPath = & "${VswhereDefaultLocation}" -version '[16,17)' -property installationPath
    }

    if ($script:VisualStudioPath -and $(Test-Path "${script:VisualStudioPath}")) {
        $script:VisualStudioFound = $true
        $script:VcvarsFolder = "${VisualStudioPath}\VC\Auxiliary\Build"
    }

    if (!$script:VisualStudioFound) {
        $ErrorMessage = -join @("Visual Studio Installation Not Found`n`n"
            "A Visual Studio 2019 installation is required for this build script to run. "
            "Visual Studio 2019 Community is free. "
            "You can download it from here: https://visualstudio.microsoft.com/vs/community/")
        Write-Error "${ErrorMessage}"
        Caught-Error "Check-Visual-Studio: NoVisualStudio"
    }

    Write-Status "Visual Studio Installation Path: ${script:VisualStudioPath}"
}

function Build-Checks {
    if(!$NoChoco) {
        Install-Windows-Build-Tools
    }
    $PRODUCT_NAME_U = "${ProductName}".ToUpper()
    $script:CI_PRODUCT_VERSION = ${CIWorkflowJobString} | Select-String "[ ]+${PRODUCT_NAME_U}_VERSION: '(.+)'" | ForEach-Object{$_.Matches.Groups[1].Value}
    $script:CI_PRODUCT_HASH = ${CIWorkflowJobString} | Select-String "[ ]+${PRODUCT_NAME_U}_HASH: '(.+)'" | ForEach-Object{$_.Matches.Groups[1].Value}

    Check-Archs
    Check-Curl
    Check-Visual-Studio

    $script:DepsBuildDir = "${CheckoutDir}\windows_native_build_temp"

    Ensure-Directory "${script:DepsBuildDir}\${CMAKE_INSTALL_DIR}\bin"
    Ensure-Directory "${script:DepsBuildDir}\${CMAKE_INSTALL_DIR}\include"
    Ensure-Directory "${script:DepsBuildDir}\${CMAKE_INSTALL_DIR}\lib"
}

function Build-Setup {
    Param(
        [Switch] $UseCurl,
        [Switch] $CurlNoContinue
    )
    Trap { Caught-Error "build-${ProductName}" }

    Ensure-Directory "${CheckoutDir}/windows_native_build_temp"

    if (!$ProductHash) {
        $ProductHash = $CI_PRODUCT_HASH
    }

    Write-Step "Download..."
    Check-And-Fetch -UseCurl:$UseCurl -CurlNoContinue:$CurlNoContinue "${ProductUrl}" "${ProductHash}"

    if (!"${SKIP_UNPACK}") {
        Write-Step "Unpack..."
        tar -xf ${ProductFilename}
    }

    cd "${ProductFolder}"
}

function Build-Setup-GitHub {
    Trap { Caught-Error "build-${ProductName}" }

    Ensure-Directory "${CheckoutDir}/windows_native_build_temp"

    if (!$ProductHash) {
        $ProductHash = $CI_PRODUCT_HASH
    }

    Write-Step "Git checkout..."
    Ensure-Directory "${ProductRepo}"
    GitHub-Fetch ${ProductProject} ${ProductRepo} ${ProductHash}
}

function Build-Setup-GitLab {
    Trap { Caught-Error "build-${ProductName}" }

    Ensure-Directory "${CheckoutDir}/windows_native_build_temp"

    if (!$ProductHash) {
        $ProductHash = $CI_PRODUCT_HASH
    }

    Write-Step "Git checkout..."
    Ensure-Directory "${ProductRepo}"
    GitLab-Fetch ${ProductProject} ${ProductRepo} ${ProductHash}
}

function Build {
    if (!$ProductVersion) {
        $ProductVersion = $CI_PRODUCT_VERSION
    }

    Write-Status "Build ${ProductName} ${ProductVersion}"

    if (Test-CommandExists 'Patch-Product') {
        Ensure-Directory "${CheckoutDir}/windows_native_build_temp"
        Patch-Product
    }

    if (Test-CommandExists 'Build-Product') {
        Ensure-Directory "${CheckoutDir}/windows_native_build_temp"
        Build-Product
    }

    if (Test-CommandExists 'Install-Product') {
        Ensure-Directory "${CheckoutDir}/windows_native_build_temp"
        Install-Product
    }
}
