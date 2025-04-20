<#
.SYNOPSIS
Server functionality for FastMCP
#>

function New-FastMCPServer
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        
        [Parameter(Mandatory = $true)]
        [string]$ApiKey,
        
        [Parameter()]
        [string]$Provider = 'OpenAI',
        
        [Parameter()]
        [string]$Model,
        
        [Parameter()]
        [hashtable]$Options = @{}
    )
    
    $logger = Get-Logger -Name 'FastMCPServer'
    $logger.Debug("Creating new server for $Provider at $Endpoint")
    
    $server = [PSCustomObject]@{
        Endpoint   = $Endpoint
        ApiKey     = $ApiKey
        Provider   = $Provider
        Model      = $Model
        Name       = $Options.Name -or "$Provider-Server"
        Options    = $Options
        PSTypeName = 'FastMCPServer'
    }
    
    # Add methods
    $server | Add-Member -MemberType ScriptMethod -Name 'GetContext' -Value {
        param($contextId = $null)
        
        try
        {
            $logger = Get-Logger -Name "Server:$($this.Name)"
            $logger.Debug("Creating context with ID: $contextId")
        }
        catch
        {
            # Silently continue if logger fails
        }
        
        # Return the context directly
        return Get-FastMCPContext -Server $this -ContextId $contextId
    }
    
    return $server
}

if ($MyInvocation.MyCommand.ScriptName -and $MyInvocation.MyCommand.ModuleName)
{
    Export-ModuleMember -Function 'New-FastMCPServer'
}
