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
            # Fallback if logger is not available: create logger via New-Object
            $this.Logger = New-Object PSObject
            Add-Member -InputObject $this.Logger -MemberType ScriptMethod -Name 'Debug' -Value { param($msg) Write-Debug "[$($this.Name)] $msg" } -Force
            Add-Member -InputObject $this.Logger -MemberType ScriptMethod -Name 'Info' -Value { param($msg) Write-Information "[$($this.Name)] $msg" } -Force
            Add-Member -InputObject $this.Logger -MemberType ScriptMethod -Name 'Warning' -Value { param($msg) Write-Warning "[$($this.Name)] $msg" } -Force
            Add-Member -InputObject $this.Logger -MemberType ScriptMethod -Name 'Error' -Value { param($msg) Write-Error "[$($this.Name)] $msg" } -Force
            Add-Member -InputObject $this.Logger -MemberType ScriptMethod -Name 'Critical' -Value { param($msg) Write-Error "[$($this.Name)] $msg" } -Force
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
