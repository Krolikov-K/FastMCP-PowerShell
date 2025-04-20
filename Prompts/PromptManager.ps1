<#
.SYNOPSIS
Prompt functionality for FastMCP
#>

function New-Prompt
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$RenderScript,
        
        [Parameter()]
        [string[]]$Tags = @()
    )
    
    $logger = Get-Logger -Name 'Prompt'
    $logger.Debug("Creating new prompt: $Name")
    
    $prompt = [PSCustomObject]@{
        Name         = $Name
        Description  = $Description
        RenderScript = $RenderScript
        Tags         = $Tags
        Type         = 'Prompt'
        PSTypeName   = 'FastMCPPrompt'
    }
    
    # Add Render method
    $prompt | Add-Member -MemberType ScriptMethod -Name 'Render' -Value {
        param([hashtable]$arguments)
        
        $logger = Get-Logger -Name "Prompt:$($this.Name)"
        $logger.Debug("Rendering prompt with arguments: $($arguments | ConvertTo-Json -Compress)")
        
        try
        {
            return & $this.RenderScript @arguments
        }
        catch
        {
            $logger.Error("Error rendering prompt: $_")
            throw [FastMCPException]::new("Error rendering prompt $($this.Name): $_")
        }
    }
    
    return $prompt
}

# Export functions only if running inside a module
if ($MyInvocation.MyCommand.ModuleName)
{
    Export-ModuleMember -Function 'New-Prompt'
}
