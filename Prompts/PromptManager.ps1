<#
.SYNOPSIS
Prompt management functionality
#>

# Simple Prompt class and PromptManager
class Prompt
{
    [string]$Name
    [string]$Description
    [scriptblock]$RenderScript
    [System.Collections.Generic.HashSet[string]]$Tags

    Prompt([string]$name, [string]$description, [scriptblock]$renderScript, [string[]]$tags)
    {
        $this.Name = $name
        $this.Description = $description
        $this.RenderScript = $renderScript
        $this.Tags = $tags | ConvertTo-Set
    }

    [array] Render([hashtable]$arguments)
    {
        try
        {
            return & $this.RenderScript @arguments
        }
        catch
        {
            throw [FastMCPException]::new("Error rendering prompt $($this.Name): $_")
        }
    }
}

class PromptManager
{
    [hashtable]$Prompts = @{}
    [string]$DuplicateBehavior = 'warn'
    hidden [object]$Logger

    PromptManager()
    {
        $this.Logger = Get-Logger 'PromptManager'
    }

    [bool] HasPrompt([string]$name)
    {
        return $this.Prompts.ContainsKey($name)
    }

    [Prompt] AddPrompt([Prompt]$prompt, [string]$name)
    {
        $promptName = $name -or $prompt.Name
        
        if ($this.HasPrompt($promptName))
        {
            switch ($this.DuplicateBehavior)
            {
                'warn'
                {
                    $this.Logger.Warning.Invoke("Prompt already exists: $promptName")
                    $this.Prompts[$promptName] = $prompt
                }
                'replace'
                {
                    $this.Prompts[$promptName] = $prompt
                }
                'error'
                {
                    throw [System.InvalidOperationException]::new("Prompt already exists: $promptName")
                }
                'ignore'
                {
                    return $this.Prompts[$promptName]
                }
            }
        }
        else
        {
            $this.Prompts[$promptName] = $prompt
        }
        
        return $prompt
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
        [string[]]$Tags
    )
    
    return [Prompt]::new($Name, $Description, $RenderScript, $Tags)
}
