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
            # Fallback if logger is not available: create an object with real ScriptMethod members
            $this.Logger = New-Object PSObject
            Add-Member -InputObject $this.Logger -MemberType ScriptMethod -Name 'Debug' -Value { param($msg) Write-Debug "[$($this.Name)] $msg" } -Force
            Add-Member -InputObject $this.Logger -MemberType ScriptMethod -Name 'Info' -Value { param($msg) Write-Information "[$($this.Name)] $msg" } -Force
            Add-Member -InputObject $this.Logger -MemberType ScriptMethod -Name 'Warning' -Value { param($msg) Write-Warning "[$($this.Name)] $msg" } -Force
            Add-Member -InputObject $this.Logger -MemberType ScriptMethod -Name 'Error' -Value { param($msg) Write-Error "[$($this.Name)] $msg" } -Force
            Add-Member -InputObject $this.Logger -MemberType ScriptMethod -Name 'Critical' -Value { param($msg) Write-Error "[$($this.Name)] $msg" } -Force
        }
    }

    [bool] HasResource([string]$name)
    {
        return $this.Resources.ContainsKey($name)
    }

    [object] AddResource([object]$resource, [string]$name)
    {
        $resourceName = $name
        if ([string]::IsNullOrEmpty($resourceName) -and $resource.PSObject.Properties['Name']) {
            $resourceName = $resource.Name
        }
        
        if ([string]::IsNullOrEmpty($resourceName))
        {
            $this.Logger.Error('Resource name is required')
            throw [System.Exception]::new('Resource name is required')
        }

        # Ensure the resource object has the correct Name property
        if ($resource.PSObject.Properties['Name']) {
            $resource.Name = $resourceName
        } else {
            Add-Member -InputObject $resource -MemberType NoteProperty -Name 'Name' -Value $resourceName -Force
        }

        if ($this.HasResource($resourceName))
        {
            switch ($this.DuplicateBehavior)
            {
                'warn'
                {
                    $this.Logger.Warning("Resource already exists: $resourceName")
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
