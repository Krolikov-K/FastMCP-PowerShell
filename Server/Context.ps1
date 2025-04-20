<#
.SYNOPSIS
Context functionality for FastMCP
#>

function Get-FastMCPContext
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Server,
        
        [Parameter()]
        [string]$ContextId
    )
    
    $logger = Get-Logger -Name 'FastMCPContext'
    $logger.Debug("Creating new context for server $($Server.Provider)")
    
    $context = [PSCustomObject]@{
        Server     = $Server
        ContextId  = $ContextId -or [System.Guid]::NewGuid().ToString()
        Tools      = @{ }
        Resources  = @{ }
        Prompts    = @{ }
        PSTypeName = 'FastMCPContext'
    }
    
    # Add methods
    $context | Add-Member -MemberType ScriptMethod -Name 'AddTool' -Value {
        param($tool)
        $this.Tools[$tool.Name] = $tool
        return $tool
    }
    
    $context | Add-Member -MemberType ScriptMethod -Name 'AddResource' -Value {
        param(
            [string]$Name,
            [string]$Description = '',
            [object]$ContentProvider = ''
        )
        
        # If ContentProvider is a string, convert it to a scriptblock
        if ($ContentProvider -is [string])
        {
            $scriptContent = $ContentProvider
            $ContentProvider = [scriptblock]::Create("return @'`n$scriptContent`n'@")
        }
        elseif ($ContentProvider -is [PSCustomObject] -and $ContentProvider.PSTypeName -eq 'FastMCPResource')
        {
            # If it's already a resource object, just store it
            $this.Resources[$Name] = $ContentProvider
            return $ContentProvider
        }
        
        # Create and store the resource
        $resource = New-Resource -Name $Name -Description $Description -Content $ContentProvider
        $this.Resources[$Name] = $resource
        return $resource
    }
    
    $context | Add-Member -MemberType ScriptMethod -Name 'AddPrompt' -Value {
        param($prompt)
        $this.Prompts[$prompt.Name] = $prompt
        return $prompt
    }
    
    $context | Add-Member -MemberType ScriptMethod -Name 'SendRequest' -Value {
        param(
            [string]$request,
            [hashtable]$options = @{ }
        )
        
        $logger = Get-Logger -Name 'FastMCPContext'
        $logger.Debug("Sending request with options: $($options | ConvertTo-Json -Compress)")
        
        $promptName = $options.promptName
        $promptArgs = $options.promptArgs
        
        $finalRequest = $request
        
        if ($promptName -and $this.Prompts.ContainsKey($promptName))
        {
            $prompt = $this.Prompts[$promptName]
            $finalRequest = $prompt.Render.Invoke($promptArgs)
        }
        
        # In a real implementation, this would call the AI model API
        return [PSCustomObject]@{
            Request   = $finalRequest
            Content   = 'This is a mock response. In a real implementation, this would be the response from the AI model.'
            Timestamp = Get-Date
        }
    }
    
    return $context
}

# Ensure Export-ModuleMember is only called when in a module
if ($MyInvocation.MyCommand.ScriptName -and $MyInvocation.MyCommand.ModuleName)
{
    Export-ModuleMember -Function 'Get-FastMCPContext'
}
