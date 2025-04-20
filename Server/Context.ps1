<#
.SYNOPSIS
Context for FastMCP server
#>

# Context class for tool execution
class Context
{
    [FastMCPServer]$Server
    hidden [object]$Logger

    # Constructor
    Context([FastMCPServer]$server)
    {
        $this.Server = $server
        $this.Logger = Get-Logger 'Context'
    }

    # Log methods
    [void] Info([string]$Message)
    {
        $this.Logger.Info.Invoke($Message)
    }

    [void] Warning([string]$Message)
    {
        $this.Logger.Warning.Invoke($Message)
    }

    [void] Error([string]$Message)
    {
        $this.Logger.Error.Invoke($Message)
    }

    [void] Debug([string]$Message)
    {
        $this.Logger.Debug.Invoke($Message)
    }

    # Report progress for a long-running tool
    [void] ReportProgress([int]$Current, [int]$Total, [string]$Message)
    {
        $percent = [Math]::Round(($Current / $Total) * 100)
        $this.Info("Progress: $percent% - $Message")
    }
}

# Function to get a context object
function Get-FastMCPContext
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [FastMCPServer]$Server
    )
    
    return [Context]::new($Server)
}
