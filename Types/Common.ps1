<#
.SYNOPSIS
Common types and utilities used across FastMCP
#>

# Convert an array to a HashSet for faster lookups
function ConvertTo-Set {
    param([string[]]$InputArray)
    
    $set = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($item in $InputArray) {
        $set.Add($item) | Out-Null
    }
    
    return $set
}

# Custom exception type for FastMCP
class FastMCPException : System.Exception {
    FastMCPException([string]$message) : base($message) {}
    FastMCPException([string]$message, [System.Exception]$innerException) : base($message, $innerException) {}
}
