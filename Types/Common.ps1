<#
.SYNOPSIS
Common types and utilities used across FastMCP
#>

# Convert a set or list to a set, defaulting to an empty set if null
function ConvertTo-Set {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [object[]]$InputObject
    )
    
    begin {
        $set = [System.Collections.Generic.HashSet[object]]::new()
    }
    
    process {
        if ($InputObject) {
            foreach ($item in $InputObject) {
                [void]$set.Add($item)
            }
        }
    }
    
    end {
        return $set
    }
}

# Custom exception types
class FastMCPException : System.Exception {
    FastMCPException([string]$message) : base($message) {}
}

class NotFoundError : FastMCPException {
    NotFoundError([string]$message) : base($message) {}
}

class ResourceError : FastMCPException {
    ResourceError([string]$message) : base($message) {}
}

class ToolError : FastMCPException {
    ToolError([string]$message) : base($message) {}
}
