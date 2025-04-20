<#
.SYNOPSIS
FastMCP server implementation
#>

# Main FastMCP server class
class FastMCPServer
{
    [string]$Name
    [string]$Instructions
    [hashtable]$Settings
    [ToolManager]$ToolManager
    [ResourceManager]$ResourceManager
    [PromptManager]$PromptManager
    [hashtable]$Tags
    hidden [object]$Logger

    # Constructor
    FastMCPServer([string]$name, [string]$instructions, [hashtable]$settings)
    {
        $this.Name = $name
        $this.Instructions = $instructions
        $this.Settings = $settings
        $this.ToolManager = [ToolManager]::new()
        $this.ResourceManager = [ResourceManager]::new()
        $this.PromptManager = [PromptManager]::new()
        $this.Tags = @{}
        $this.Logger = Get-Logger 'Server'
        
        # Configure logging
        Set-Logging -Level $settings.LogLevel
    }

    # Add a tool to the server
    [void] AddTool([scriptblock]$ScriptBlock, [string]$Name, [string]$Description, [string[]]$Tags)
    {
        $tool = [Tool]::new($ScriptBlock, $Name, $Description, $Tags)
        $this.ToolManager.AddTool($tool)
        $this.Logger.Info.Invoke("Added tool: $Name")
    }

    # Add a resource to the server
    [void] AddResource([hashtable]$ResourceParams)
    {
        $resource = [Resource]::new($ResourceParams)
        $this.ResourceManager.AddResource($resource)
        $this.Logger.Info.Invoke("Added resource: $($resource.URI)")
    }

    # Run the server using stdio transport
    [void] Run()
    {
        $this.Logger.Info.Invoke("Starting FastMCP server: $($this.Name)")
        
        # In a real implementation, this would set up the MCP protocol handlers
        # and start listening for requests via stdio or other transports
        $this.Logger.Info.Invoke('Server started with stdio transport')
        
        # Simple loop to process stdin in a basic way
        try
        {
            while ($true)
            {
                $line = [Console]::In.ReadLine()
                if (-not $line)
                {
                    continue 
                }
                
                try
                {
                    $request = $line | ConvertFrom-Json
                    $this.ProcessRequest($request)
                }
                catch
                {
                    $errorResponse = @{
                        jsonrpc = '2.0'
                        id      = $null
                        error   = @{
                            code    = -32700
                            message = 'Parse error'
                        }
                    }
                    [Console]::Out.WriteLine(($errorResponse | ConvertTo-Json -Compress))
                }
            }
        }
        catch
        {
            $this.Logger.Error.Invoke("Error in server: $_")
        }
    }

    # Process an MCP request
    hidden [void] ProcessRequest($request)
    {
        $response = @{
            jsonrpc = '2.0'
            id      = $request.id
        }

        try
        {
            switch ($request.method)
            {
                'listTools'
                {
                    $response.result = $this.ToolManager.ListTools()
                }
                'callTool'
                {
                    $response.result = $this.ToolManager.CallTool($request.params.name, $request.params.arguments)
                }
                'listResources'
                {
                    $response.result = $this.ResourceManager.ListResources()
                }
                'readResource'
                {
                    $response.result = $this.ResourceManager.ReadResource($request.params.uri)
                }
                default
                {
                    $response.error = @{
                        code    = -32601
                        message = "Method not found: $($request.method)"
                    }
                }
            }
        }
        catch
        {
            $response.error = @{
                code    = -32603
                message = "Internal error: $_"
            }
        }

        [Console]::Out.WriteLine(($response | ConvertTo-Json -Compress))
    }

    # Get context object for tool execution
    [Context] GetContext()
    {
        return [Context]::new($this)
    }
}

# Function to create a new FastMCP server
function New-FastMCPServer
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Name = 'FastMCP PowerShell',
        
        [Parameter()]
        [string]$Instructions,
        
        [Parameter()]
        [hashtable]$Settings = @{
            LogLevel = [LogLevel]::INFO
            Host     = '127.0.0.1'
            Port     = 8000
        }
    )
    
    return [FastMCPServer]::new($Name, $Instructions, $Settings)
}
