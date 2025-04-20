<#
.SYNOPSIS
Resource manager functionality
#>

# ResourceManager class
class ResourceManager
{
    [hashtable]$Resources
    [string]$DuplicateBehavior
    hidden [object]$Logger

    # Constructor
    ResourceManager()
    {
        $this.Resources = @{}
        $this.DuplicateBehavior = 'warn'  # Options: warn, error, replace, ignore
        $this.Logger = Get-Logger 'ResourceManager'
    }

    # Add a resource to the manager
    [Resource] AddResource([Resource]$resource, [string]$key)
    {
        $resourceKey = $key -or $resource.URI
        
        if ($this.Resources.ContainsKey($resourceKey))
        {
            switch ($this.DuplicateBehavior)
            {
                'warn'
                {
                    $this.Logger.Warning("Resource already exists: $resourceKey")
                    $this.Resources[$resourceKey] = $resource
                }
                'replace'
                {
                    $this.Resources[$resourceKey] = $resource
                }
                'error'
                {
                    throw [FastMCPException]::new("Resource already exists: $resourceKey")
                }
                'ignore'
                {
                    return $this.Resources[$resourceKey]
                }
            }
        }
        else
        {
            $this.Resources[$resourceKey] = $resource
        }
        
        return $resource
    }

    # Check if a resource exists
    [bool] HasResource([string]$uri)
    {
        return $this.Resources.ContainsKey($uri)
    }

    # Get a resource by URI
    [Resource] GetResource([string]$uri)
    {
        if (-not $this.HasResource($uri))
        {
            throw [FastMCPException]::new("Unknown resource: $uri")
        }
        return $this.Resources[$uri]
    }

    # Get all resources
    [hashtable] GetResources()
    {
        return $this.Resources
    }

    # List all resources in MCP format
    [array] ListResources()
    {
        $result = @()
        foreach ($resource in $this.Resources.Values)
        {
            $result += $resource.ToMCPResource()
        }
        return $result
    }

    # Read a resource by URI
    [array] ReadResource([string]$uri)
    {
        $resource = $this.GetResource($uri)
        $content = $resource.Read()
        
        return @(
            @{
                content  = $content
                mimeType = $resource.MimeType
            }
        )
    }
}

# Update the AddResource method to accept PSCustomObject with PSTypeName 'FastMCPResource'
function New-ResourceManager {
    $manager = [PSCustomObject]@{
        Resources = @{}
        DuplicateBehavior = 'warn'
        Logger = Get-Logger 'ResourceManager'
    }
    
    # Add methods
    $manager | Add-Member -MemberType ScriptMethod -Name 'AddResource' -Value {
        param(
            [Parameter(Mandatory = $true)]
            [PSCustomObject]$resource,
            
            [Parameter()]
            [string]$name = $null
        )
        
        # Use the resource name if no name is provided
        if (-not $name) {
            $name = $resource.Name
        }
        
        if ($this.Resources.ContainsKey($name)) {
            switch ($this.DuplicateBehavior) {
                'warn' {
                    $this.Logger.Warning("Resource already exists: $name")
                    $this.Resources[$name] = $resource
                }
                'replace' {
                    $this.Resources[$name] = $resource
                }
                'error' {
                    throw [FastMCPException]::new("Resource already exists: $name")
                }
                'ignore' {
                    return $this.Resources[$name]
                }
            }
        } else {
            $this.Resources[$name] = $resource
        }
        
        return $resource
    }
    
    # Add other methods as needed
    
    return $manager
}

# Export functions only if running inside a module
if ($MyInvocation.MyCommand.ModuleName)
{
    Export-ModuleMember -Function 'New-ResourceManager'
}
