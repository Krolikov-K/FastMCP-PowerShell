<#
.SYNOPSIS
Tool functionality for FastMCP
#>

function New-Tool
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Function,
        
        [Parameter()]
        [hashtable]$Parameters = @{},
        
        [Parameter()]
        [string[]]$Tags = @()
    )
    
    $logger = Get-Logger -Name 'Tool'
    $logger.Debug("Creating new tool: $Name")
    
    return [PSCustomObject]@{
        Name        = $Name
        Description = $Description
        Function    = $Function
        Parameters  = $Parameters
        Tags        = $Tags
        Type        = 'Tool'
        PSTypeName  = 'FastMCPTool'
    }
}

Export-ModuleMember -Function 'New-Tool'
