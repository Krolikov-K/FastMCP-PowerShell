<#
.SYNOPSIS
Resource manager functionality for FastMCP
#>

# ResourceManager class
class ResourceManager
{
    [hashtable]$Resources = @{}
    [string]$DuplicateBehavior = 'warn'
    hidden [object]$Logger

    ResourceManager()
    {
        try
        {
            $this.Logger = Get-Logger -Name 'ResourceManager'
            $this.Logger.Debug('Initializing ResourceManager')
        }
        catch
        {
            # Fallback if logger is not available
            $this.Logger = [PSCustomObject]@{
                Name     = 'ResourceManager'
                Debug    = { param($msg) Write-Debug "[$($this.Name)] $msg" }.GetNewClosure()
                Info     = { param($msg) Write-Information "[$($this.Name)] $msg" }.GetNewClosure()
                Warning  = { param($msg) Write-Warning "[$($this.Name)] $msg" }.GetNewClosure()
                Error    = { param($msg) Write-Error "[$($this.Name)] $msg" }.GetNewClosure()
                Critical = { param($msg) Write-Error "[$($this.Name)] $msg" }.GetNewClosure()
            }
        }
    }

    [bool] HasResource([string]$name)
    {
        return $this.Resources.ContainsKey($name)
    }

    [object] AddResource([object]$resource, [string]$name)
    {
        $resourceName = $name -or $resource.Name
        
        if (-not $resourceName)
        {
            $this.Logger.Error('Resource name is required')
            throw [System.Exception]::new('Resource name is required')
        }
        
        if ($this.HasResource($resourceName))
        {
            switch ($this.DuplicateBehavior)
            {
                'warn'
                {
                    $this.Logger.Warning("Resource already exists: $resourceName - replacing")
                }
                'error'
                {
                    $this.Logger.Error("Resource already exists: $resourceName")
                    throw [System.Exception]::new("Resource already exists: $resourceName")
                }
                'ignore'
                {
                    $this.Logger.Debug("Ignoring duplicate resource: $resourceName")
                    return $this.Resources[$resourceName]
                }
                default
                {
                    $this.Logger.Info("Replacing existing resource: $resourceName")
                }
            }
        }
        
        $this.Logger.Debug("Adding/updating resource: $resourceName")
        $this.Resources[$resourceName] = $resource
        
        return $resource
    }

    [object] GetResource([string]$name)
    {
        if ($this.HasResource($name))
        {
            return $this.Resources[$name]
        }
        
        $this.Logger.Error("Resource not found: $name")
        throw [System.Exception]::new("Resource not found: $name")
    }
}

function New-ResourceManager
{
    [CmdletBinding()]
    param()
    
    return [ResourceManager]::new()
}

# Export functions only if running inside a module
if ($MyInvocation.MyCommand.ScriptName -and $MyInvocation.MyCommand.ModuleName)
{
    Export-ModuleMember -Function 'New-ResourceManager', 'Add-Resource', 'Get-Resource'
}
