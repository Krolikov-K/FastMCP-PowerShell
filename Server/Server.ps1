<#
.SYNOPSIS
Server functionality for FastMCP with improved validation and additional methods.
#>

function New-FastMCPServer
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        
        [Parameter()]
        [string]$ApiKey = (New-Guid).Guid,
        
        [Parameter()]
        [string]$Provider = 'OpenAI',
        
        [Parameter()]
        [string]$Model,
        
        [Parameter()]
        [hashtable]$Options = @{},
        
        [Parameter()]
        [int]$Timeout = 30  # new parameter for HTTP timeout in seconds
    )
    
    # Validate Endpoint URL
    if (-not ($Endpoint -match '^https?://'))
    {
        throw "Invalid Endpoint URL: $Endpoint"
    }
    
    $logger = Get-Logger -Name 'FastMCPServer'
    $logger.Debug("Creating new server for $Provider at $Endpoint with timeout $Timeout seconds")
    
    $server = [PSCustomObject]@{
        Endpoint   = $Endpoint
        ApiKey     = $ApiKey
        Provider   = $Provider
        Model      = $Model
        Timeout    = $Timeout
        Name       = $Options.Name -or "$Provider-Server"
        Options    = $Options
        PSTypeName = 'FastMCPServer'
    }
    
    # Add TestConnection method to verify API reachability (simulated)
    $server | Add-Member -MemberType ScriptMethod -Name 'TestConnection' -Value {
        param()
        $logger = Get-Logger -Name "Server:$($this.Name)"
        $logger.Debug("Testing connection to $($this.Endpoint)")
        try {
            # A simple HEAD request; in real usage, call the actual API endpoint
            Invoke-WebRequest -Uri $this.Endpoint -Method Head -TimeoutSec $this.Timeout -ErrorAction Stop | Out-Null
            return $true
        }
        catch {
            $logger.Error("Connection test failed: $_")
            return $false
        }
    } -Force
    
    # Add GetContext method using improved Get-FastMCPContext
    $server | Add-Member -MemberType ScriptMethod -Name 'GetContext' -Value {
        param($ContextId = $null)
        try {
            $logger = Get-Logger -Name "Server:$($this.Name)"
            $logger.Debug("Creating context with ID: $ContextId")
        }
        catch { }
        return Get-FastMCPContext -Server $this -ContextId $ContextId
    } -Force
    
    return $server
}

if ($MyInvocation.MyCommand.ScriptName -and $MyInvocation.MyCommand.ModuleName)
{
    Export-ModuleMember -Function 'New-FastMCPServer'
}
