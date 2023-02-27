function Get-HostArchitecture {
    <#
        .SYNOPSIS
            Get the host architecture where is this script currently being running on.
        .DESCRIPTION
            The function will return "ARM64" for ARM64 processors, "x86" and "x64" for 32 and 64 bit 
            Intel Processors.
    #>

    switch ((Get-CimInstance -ClassName CIM_OperatingSystem).OSArchitecture) {
        "ARM 64-bit Processor" { return "ARM64" }
        "64-bit" { return "x64" }
        "32-bit" { return "x86" }
    }

    return "Unknown"    
}
