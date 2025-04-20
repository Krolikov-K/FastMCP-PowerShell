<#
.SYNOPSIS
Common types and utilities for FastMCP
#>

# Convert an array to a HashSet for faster lookups
function ConvertTo-Set
{
    param([string[]]$InputArray)
    
    $set = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($item in $InputArray)
    {
        $set.Add($item) | Out-Null
    }
    
    return $set
}

# Define a custom exception class
class FastMCPException : System.Exception
{
    FastMCPException([string]$message) : base($message)
    {
    }
    FastMCPException([string]$message, [System.Exception]$inner) : base($message, $inner)
    {
    }
}

# Export types only if running inside a module
if ($MyInvocation.MyCommand.ScriptName -and $MyInvocation.MyCommand.ModuleName)
{
    # No need to export custom classes - they're available once defined
}
