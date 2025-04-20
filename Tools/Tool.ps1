<#
.SYNOPSIS
Tool implementation for FastMCP
#>

# Tool class
class Tool
{
    [string]$Name
    [string]$Description
    [hashtable]$Parameters
    [scriptblock]$ScriptBlock
    [System.Collections.Generic.HashSet[string]]$Tags
    hidden [object]$Logger

    # Constructor
    Tool([scriptblock]$scriptBlock, [string]$name, [string]$description, [string[]]$tags)
    {
        $this.ScriptBlock = $scriptBlock
        $this.Name = $name -or 'unnamed_tool'
        $this.Description = $description -or ''
        $this.Tags = $tags | ConvertTo-Set
        $this.Parameters = $this.ExtractParameters()
        $this.Logger = Get-Logger 'Tool'
    }

    # Extract parameters from scriptblock
    hidden [hashtable] ExtractParameters()
    {
        $ast = $this.ScriptBlock.Ast
        $params = $ast.ParamBlock.Parameters
        
        $schema = @{
            type       = 'object'
            properties = @{}
            required   = @()
        }
        
        foreach ($param in $params)
        {
            $paramName = $param.Name.VariablePath.UserPath
            $paramType = 'string'  # Default type
            
            # Try to determine parameter type
            if ($param.StaticType)
            {
                switch ($param.StaticType.Name)
                {
                    'Int32'
                    {
                        $paramType = 'integer' 
                    }
                    'Double'
                    {
                        $paramType = 'number' 
                    }
                    'Boolean'
                    {
                        $paramType = 'boolean' 
                    }
                    'String'
                    {
                        $paramType = 'string' 
                    }
                    # Add more type mappings as needed
                }
            }
            
            $schema.properties[$paramName] = @{
                type = $paramType
            }
            
            # Check if parameter is required
            if (-not $param.DefaultValue)
            {
                $schema.required += $paramName
            }
        }
        
        return $schema
    }

    # Run the tool with the given arguments
    [object] Run([hashtable]$arguments, [Context]$context)
    {
        try
        {
            # Create parameter hashtable for splatting
            $params = @{}
            foreach ($key in $arguments.Keys)
            {
                $params[$key] = $arguments[$key]
            }
            
            # Add context if needed
            $params['Context'] = $context
            
            # Run the scriptblock with parameters
            $result = & $this.ScriptBlock @params
            return $this.ConvertToContent($result)
        }
        catch
        {
            throw [ToolError]::new("Error executing tool $($this.Name): $_")
        }
    }

    # Convert results to MCP content format
    hidden [array] ConvertToContent($result)
    {
        if ($null -eq $result)
        {
            return @()
        }
        
        if ($result -is [Image])
        {
            return @($result.ToImageContent())
        }
        
        # Convert other types to text
        $textContent = if ($result -is [hashtable] -or $result -is [array])
        {
            $result | ConvertTo-Json -Depth 10
        }
        else
        {
            "$result"
        }
        
        return @(
            @{
                type = 'text'
                text = $textContent
            }
        )
    }

    # Convert to MCP tool format
    [hashtable] ToMCPTool()
    {
        return @{
            name        = $this.Name
            description = $this.Description
            inputSchema = $this.Parameters
        }
    }
}

# Function to create a new tool
function New-Tool
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [string]$Description,
        
        [Parameter()]
        [string[]]$Tags
    )
    
    return [Tool]::new($ScriptBlock, $Name, $Description, $Tags)
}
