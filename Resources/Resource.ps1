<#
.SYNOPSIS
Resource functionality for FastMCP
#>

function New-Resource
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [string]$Description = '',
        
        [Parameter(Mandatory = $true)]
        [object]$Content,
        
        [Parameter()]
        [string]$Type = 'text',
        
        [Parameter()]
        [string[]]$Tags = @()
    )
    
    $logger = Get-Logger -Name 'Resource'
    $logger.Debug("Creating new resource: $Name")
    
    # Content can be a script block or direct value
    $contentValue = if ($Content -is [scriptblock])
    {
        & $Content
    }
    else
    {
        $Content
    }
    
    $resource = [PSCustomObject]@{
        Name         = $Name
        Description  = $Description
        Content      = $contentValue
        Type         = $Type.ToLower()
        Tags         = $Tags
        ResourceType = 'Resource'
        PSTypeName   = 'FastMCPResource'
    }
    
    return $resource
}

# Export functions only if running inside a module
if ($MyInvocation.MyCommand.ScriptName -and $MyInvocation.MyCommand.ModuleName)
{
    Export-ModuleMember -Function 'New-Resource'
}
