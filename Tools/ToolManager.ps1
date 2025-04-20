<#
.SYNOPSIS
Tool manager functionality
#>

# ToolManager class
class ToolManager
{
    [hashtable]$Tools = @{}
    [string]$DuplicateBehavior = 'warn'
    hidden [object]$Logger

    ToolManager()
    {
        try
        {
            $this.Logger = Get-Logger -Name 'ToolManager'
            $this.Logger.Debug('Initializing ToolManager')
        }
        catch
        {
            # Fallback if logger is not available
            $this.Logger = [PSCustomObject]@{
                Name     = 'ToolManager'
                Debug    = { param($msg) Write-Debug "[$($this.Name)] $msg" }.GetNewClosure()
                Info     = { param($msg) Write-Information "[$($this.Name)] $msg" }.GetNewClosure()
                Warning  = { param($msg) Write-Warning "[$($this.Name)] $msg" }.GetNewClosure()
                Error    = { param($msg) Write-Error "[$($this.Name)] $msg" }.GetNewClosure()
                Critical = { param($msg) Write-Error "[$($this.Name)] $msg" }.GetNewClosure()
            }
        }
    }

    [bool] HasTool([string]$name)
    {
        return $this.Tools.ContainsKey($name)
    }

    [object] AddTool([object]$tool, [string]$name)
    {
        $toolName = $name -or $tool.Name
        
        if (-not $toolName)
        {
            $this.Logger.Error('Tool name is required')
            throw [FastMCPException]::new('Tool name is required')
        }
        
        if ($this.HasTool($toolName))
        {
            switch ($this.DuplicateBehavior)
            {
                'warn'
                {
                    $this.Logger.Warning("Tool already exists: $toolName - replacing")
                    $this.Tools[$toolName] = $tool
                }
                'replace'
                {
                    $this.Logger.Info("Replacing existing tool: $toolName")
                    $this.Tools[$toolName] = $tool
                }
                'error'
                {
                    $this.Logger.Error("Tool already exists: $toolName")
                    throw [FastMCPException]::new("Tool already exists: $toolName")
                }
                'ignore'
                {
                    $this.Logger.Debug("Ignoring duplicate tool: $toolName")
                    return $this.Tools[$toolName]
                }
            }
        }
        else
        {
            $this.Logger.Debug("Adding new tool: $toolName")
            $this.Tools[$toolName] = $tool
        }
        
        return $tool
    }

    [object] GetTool([string]$name)
    {
        if ($this.HasTool($name))
        {
            return $this.Tools[$name]
        }
        
        $this.Logger.Error("Tool not found: $name")
        throw [FastMCPException]::new("Tool not found: $name")
    }
}

# Export functions only if running inside a module
if ($MyInvocation.MyCommand.ScriptName -and $MyInvocation.MyCommand.ModuleName)
{
    Export-ModuleMember -Function 'Register-Tool', 'Get-Tools', 'Invoke-Tool' # Adjust function names if needed
}
