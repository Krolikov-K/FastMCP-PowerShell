<#
.SYNOPSIS
Prompt manager functionality
#>

# PromptManager class
class PromptManager
{
    [hashtable]$Prompts = @{}
    [string]$DuplicateBehavior = 'warn'
    hidden [object]$Logger

    PromptManager()
    {
        try
        {
            $this.Logger = Get-Logger -Name 'PromptManager'
            $this.Logger.Debug('Initializing PromptManager')
        }
        catch
        {
            # Fallback if logger is not available
            $this.Logger = [PSCustomObject]@{
                Name     = 'PromptManager'
                Debug    = { param($msg) Write-Debug "[$($this.Name)] $msg" }.GetNewClosure()
                Info     = { param($msg) Write-Information "[$($this.Name)] $msg" }.GetNewClosure()
                Warning  = { param($msg) Write-Warning "[$($this.Name)] $msg" }.GetNewClosure()
                Error    = { param($msg) Write-Error "[$($this.Name)] $msg" }.GetNewClosure()
                Critical = { param($msg) Write-Error "[$($this.Name)] $msg" }.GetNewClosure()
            }
        }
    }

    [bool] HasPrompt([string]$name)
    {
        return $this.Prompts.ContainsKey($name)
    }

    [object] AddPrompt([object]$prompt)
    {
        if (-not $prompt.Name)
        {
            $this.Logger.Error('Prompt name is required')
            throw [System.Exception]::new('Prompt name is required')
        }
        
        $name = $prompt.Name
        
        if ($this.HasPrompt($name))
        {
            $this.Logger.Warning("Prompt already exists: $name - replacing")
        }
        
        $this.Logger.Debug("Adding/updating prompt: $name")
        $this.Prompts[$name] = $prompt
        
        return $prompt
    }

    [object] GetPrompt([string]$name)
    {
        if ($this.HasPrompt($name))
        {
            return $this.Prompts[$name]
        }
        
        $this.Logger.Error("Prompt not found: $name")
        throw [System.Exception]::new("Prompt not found: $name")
    }
}

# Prompt class
class Prompt
{
    [string]$Name
    [string]$Description
    [scriptblock]$RenderScript
    [string[]]$Tags
    [string]$Type = 'Prompt'

    Prompt([string]$name, [string]$description, [scriptblock]$renderScript)
    {
        $this.Name = $name
        $this.Description = $description
        $this.RenderScript = $renderScript
        $this.Tags = @()
    }

    Prompt([string]$name, [string]$description, [scriptblock]$renderScript, [string[]]$tags)
    {
        $this.Name = $name
        $this.Description = $description
        $this.RenderScript = $renderScript
        $this.Tags = $tags
    }

    [string] Render([hashtable]$arguments)
    {
        try
        {
            return & $this.RenderScript @arguments
        }
        catch
        {
            $errorMessage = "Error rendering prompt $($this.Name): $_"
            throw [System.Exception]::new($errorMessage)
        }
    }
}

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
            $result = & $this.RenderScript @arguments
            if (-not $result) { throw "RenderScript returned no output." }
            return $result
        }
        catch
        {
            $logger.Error("Error rendering prompt: $_")
            throw [System.Exception]::new("Error rendering prompt $($this.Name): $_")
        }
    } -Force
    
    return $prompt
}

# Export functions only if running inside a module
if ($MyInvocation.MyCommand.ScriptName -and $MyInvocation.MyCommand.ModuleName)
{
    Export-ModuleMember -Function 'New-Prompt'
}
