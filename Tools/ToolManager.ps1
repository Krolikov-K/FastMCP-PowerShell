<#
.SYNOPSIS
Tool manager functionality
#>

# ToolManager class
class ToolManager
{
    [hashtable]$Tools
    [string]$DuplicateBehavior
    hidden [object]$Logger

    # Constructor
    ToolManager()
    {
        $this.Tools = @{}
        $this.DuplicateBehavior = 'warn'  # Options: warn, error, replace, ignore
        $this.Logger = Get-Logger 'ToolManager'
    }

    # Add a tool to the manager
    [Tool] AddTool([Tool]$tool, [string]$key)
    {
        $toolKey = $key -or $tool.Name
        
        if ($this.Tools.ContainsKey($toolKey))
        {
            switch ($this.DuplicateBehavior)
            {
                'warn'
                {
                    $this.Logger.Warning.Invoke("Tool already exists: $toolKey")
                    $this.Tools[$toolKey] = $tool
                }
                'replace'
                {
                    $this.Tools[$toolKey] = $tool
                }
                'error'
                {
                    throw [System.InvalidOperationException]::new("Tool already exists: $toolKey")
                }
                'ignore'
                {
                    return $this.Tools[$toolKey]
                }
            }
        }
        else
        {
            $this.Tools[$toolKey] = $tool
        }
        
        return $tool
    }

    # Check if a tool exists
    [bool] HasTool([string]$key)
    {
        return $this.Tools.ContainsKey($key)
    }

    # Get a tool by key
    [Tool] GetTool([string]$key)
    {
        if (-not $this.HasTool($key))
        {
            throw [NotFoundError]::new("Unknown tool: $key")
        }
        return $this.Tools[$key]
    }

    # Get all tools
    [hashtable] GetTools()
    {
        return $this.Tools
    }

    # List all tools in MCP format
    [array] ListTools()
    {
        $result = @()
        foreach ($tool in $this.Tools.Values)
        {
            $result += $tool.ToMCPTool()
        }
        return $result
    }

    # Call a tool by key
    [array] CallTool([string]$key, [hashtable]$arguments, [Context]$context)
    {
        $tool = $this.GetTool($key)
        return $tool.Run($arguments, $context)
    }
}
