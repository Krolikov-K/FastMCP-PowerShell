<#
.SYNOPSIS
Context functionality for FastMCP with added progress reporting.
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
        param($resourceOrName, $Description = '', $ContentProvider = '')
        if ($resourceOrName -is [PSCustomObject] -and $resourceOrName.PSTypeName -eq 'FastMCPResource')
        {
             $this.Resources[$resourceOrName.Name] = $resourceOrName
             return $resourceOrName
        }
        else {
            $name = $resourceOrName
            if ($ContentProvider -is [string])
            {
                $scriptContent = $ContentProvider
                $ContentProvider = [scriptblock]::Create("return @'`n$scriptContent`n'@")
            }
            elseif ($ContentProvider -is [PSCustomObject] -and $ContentProvider.PSTypeName -eq 'FastMCPResource')
            {
                $this.Resources[$name] = $ContentProvider
                return $ContentProvider
            }
            $resource = New-Resource -Name $name -Description $Description -Content $ContentProvider
            $this.Resources[$name] = $resource
            return $resource
        }
    } -Force
    
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
    
    # New method: ReportProgress for long-running tasks
    $context | Add-Member -MemberType ScriptMethod -Name 'ReportProgress' -Value {
        param([hashtable]$progressInfo)
        $logger = Get-Logger -Name 'FastMCPContext'
        $jsonProgress = $progressInfo | ConvertTo-Json -Compress
        $logger.Info("Progress update: $jsonProgress")
        Write-Verbose "Progress: $jsonProgress"
    }
    
    return $context
}

# Ensure Export-ModuleMember is only called when in a module
if ($MyInvocation.MyCommand.ScriptName -and $MyInvocation.MyCommand.ModuleName)
{
    Export-ModuleMember -Function 'Get-FastMCPContext'
}
