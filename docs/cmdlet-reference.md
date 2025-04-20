# FastMCP Cmdlet Reference

This document provides detailed information about all cmdlets available in the FastMCP PowerShell module.

## New-FastMCPServer

### SYNOPSIS
Creates a new FastMCP server instance for interacting with AI models.

### SYNTAX

```
New-FastMCPServer [-Endpoint] <string> [[-ApiKey] <string>] [[-Provider] <string>] [[-Model] <string>] [[-Options] <hashtable>]
```

### DESCRIPTION
The `New-FastMCPServer` cmdlet creates a new server instance that connects to an AI model provider's API. This is typically the first step in using FastMCP, as the server manages the connection to the underlying model.

### PARAMETERS

#### -Endpoint
The URL endpoint for the API.

```yaml
Type: String
Required: True
Position: 0
Default value: None
```

#### -ApiKey
The API key used for authentication.

```yaml
Type: String
Required: False
Position: 1
Default value: New GUID
```

#### -Provider
The AI model provider (e.g., "OpenAI", "Anthropic", "Azure").

```yaml
Type: String
Required: False
Position: 2
Default value: "OpenAI"
```

#### -Model
The specific model to use from the provider.

```yaml
Type: String
Required: False
Position: 3
Default value: None
```

#### -Options
Additional options for the server as a hashtable.

```yaml
Type: Hashtable
Required: False
Position: 4
Default value: @{}
```

### EXAMPLES

#### Example 1: Create a basic server with OpenAI
```powershell
$server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey "your-api-key"
```

#### Example 2: Create a server with a specific model and options
```powershell
$options = @{
    MaxTokens = 4096
    Temperature = 0.7
    Name = "MyCustomServer"
}
$server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey "your-api-key" -Model "gpt-4" -Options $options
```

## New-Image

### SYNOPSIS
Creates an image resource for use with AI models.

### SYNTAX

```
New-Image [-Path] <string> [[-Description] <string>] [[-Tags] <string[]>]
```

or

```
New-Image [-Name] <string> [[-Description] <string>] [[-Tags] <string[]>]
```

### DESCRIPTION
The `New-Image` cmdlet creates an image resource that can be shared with AI models that support image inputs. The image can be loaded from a specified path or created with just a name (for testing purposes).

### PARAMETERS

#### -Path
The file path to the image.

```yaml
Type: String
Required: True (in Path parameter set)
Position: 0
Default value: None
```

#### -Name
A unique name for the image resource (used in the NamedImage parameter set).

```yaml
Type: String
Required: True (in NamedImage parameter set)
Position: 0
Default value: None
```

#### -Description
A description of the image content.

```yaml
Type: String
Required: False
Position: 1
Default value: ""
```

#### -Tags
Optional array of tags for categorization.

```yaml
Type: String[]
Required: False
Position: 2
Default value: @()
```

### EXAMPLES

#### Example 1: Create an image resource from a file
```powershell
$image = New-Image -Path "./images/diagram.png" -Description "Technical diagram of the product"
```

#### Example 2: Create an image with tags
```powershell
$image = New-Image -Path "./images/team.jpg" -Description "Company team photo from annual retreat" -Tags "company", "team", "2023"
```

#### Example 3: Create a named image (for testing)
```powershell
$image = New-Image -Name "TestImage" -Description "A test image resource"
```

## New-Tool

### SYNOPSIS
Creates a tool that can be used by AI models.

### SYNTAX

```
New-Tool [-Name] <string> [-Description] <string> [-Function] <scriptblock> [[-Parameters] <hashtable>] [[-Tags] <string[]>]
```

### DESCRIPTION
The `New-Tool` cmdlet creates a tool that can be invoked by AI models. Tools are functions that perform specific operations when called by the model, allowing the AI to interact with your environment, access data, or perform actions.

### PARAMETERS

#### -Name
A unique name for the tool.

```yaml
Type: String
Required: True
Position: 0
Default value: None
```

#### -Description
Description of what the tool does.

```yaml
Type: String
Required: True
Position: 1
Default value: None
```

#### -Function
ScriptBlock containing the tool's implementation.

```yaml
Type: ScriptBlock
Required: True
Position: 2
Default value: None
```

#### -Parameters
Optional parameter definitions as a hashtable.

```yaml
Type: Hashtable
Required: False
Position: 3
Default value: @{}
```

#### -Tags
Optional array of tags for categorization.

```yaml
Type: String[]
Required: False
Position: 4
Default value: @()
```

### EXAMPLES

#### Example 1: Create a simple calculator tool
```powershell
$calculatorTool = New-Tool -Name "Calculator" -Description "Performs basic math operations" -Function {
    param($operation, $a, $b)
    
    switch ($operation) {
        "add" { return $a + $b }
        "subtract" { return $a - $b }
        "multiply" { return $a * $b }
        "divide" { return $a / $b }
        default { throw "Unknown operation: $operation" }
    }
}
```

#### Example 2: Create a tool with parameter definitions
```powershell
$parameters = @{
    "query" = @{
        "type" = "string"
        "description" = "Search query string"
        "required" = $true
    }
    "maxResults" = @{
        "type" = "integer"
        "description" = "Maximum number of results to return"
        "required" = $false
        "default" = 10
    }
}

$searchTool = New-Tool -Name "SearchFiles" -Description "Searches files for content" -Function {
    param($query, $maxResults = 10)
    
    # Implementation of file search
    # ...
    return $searchResults
} -Parameters $parameters -Tags "filesystem", "search"
```

## New-Resource

### SYNOPSIS
Creates a resource that can be referenced by AI models.

### SYNTAX

```
New-Resource [-Name] <string> [[-Description] <string>] [-Content] <object> [[-Type] <string>] [[-Tags] <string[]>]
```

### DESCRIPTION
The `New-Resource` cmdlet creates a resource that can be referenced by AI models. Resources can be text content, structured data, or references to external systems that the model may need to access.

### PARAMETERS

#### -Name
A unique name for the resource.

```yaml
Type: String
Required: True
Position: 0
Default value: None
```

#### -Description
Description of the resource.

```yaml
Type: String
Required: False
Position: 1
Default value: ""
```

#### -Content
The resource content or a script block that returns content.

```yaml
Type: Object
Required: True
Position: 2
Default value: None
```

#### -Type
The resource type (text, json, binary, etc.).

```yaml
Type: String
Required: False
Position: 3
Default value: "text"
```

#### -Tags
Optional array of tags for categorization.

```yaml
Type: String[]
Required: False
Position: 4
Default value: @()
```

### EXAMPLES

#### Example 1: Create a text resource
```powershell
$aboutResource = New-Resource -Name "AboutCompany" -Description "Company information" -Content "Founded in 2005, our company specializes in AI solutions."
```

#### Example 2: Create a JSON resource
```powershell
$data = @{
    products = @(
        @{ name = "Product A"; price = 29.99 },
        @{ name = "Product B"; price = 49.99 }
    )
}

$productsResource = New-Resource -Name "Products" -Description "Product catalog" -Content ($data | ConvertTo-Json) -Type "json" -Tags "catalog", "products"
```

#### Example 3: Create a resource with a script block
```powershell
$dynamicResource = New-Resource -Name "CurrentTime" -Description "Current system time" -Content {
    Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}
```

## New-Prompt

### SYNOPSIS
Creates a prompt template for structuring requests to AI models.

### SYNTAX

```
New-Prompt [-Name] <string> [[-Description] <string>] [-RenderScript] <scriptblock> [[-Tags] <string[]>]
```

### DESCRIPTION
The `New-Prompt` cmdlet creates a prompt template that can be used to structure requests to AI models in a consistent way. Prompt templates are script blocks that generate formatted text based on provided arguments.

### PARAMETERS

#### -Name
A unique name for the prompt.

```yaml
Type: String
Required: True
Position: 0
Default value: None
```

#### -Description
Description of the prompt's purpose.

```yaml
Type: String
Required: False
Position: 1
Default value: ""
```

#### -RenderScript
ScriptBlock that generates the formatted prompt.

```yaml
Type: ScriptBlock
Required: True
Position: 2
Default value: None
```

#### -Tags
Optional array of tags for categorization.

```yaml
Type: String[]
Required: False
Position: 3
Default value: @()
```

### EXAMPLES

#### Example 1: Create a simple query prompt
```powershell
$queryPrompt = New-Prompt -Name "SimpleQuery" -Description "Basic question format" -RenderScript {
    param($question)
    
    return "Please answer this question: $question"
}
```

#### Example 2: Create a complex prompt with multiple parameters
```powershell
$analysisPrompt = New-Prompt -Name "DataAnalysis" -Description "Prompt for data analysis" -RenderScript {
    param($data, $analysisType, $includedFields)
    
    return @"
Please analyze the following data using $analysisType analysis:

$data

Focus specifically on these fields: $($includedFields -join ', ')

Provide insights, trends, and recommendations based on your analysis.
"@
} -Tags "analysis", "data"
```

## Get-FastMCPContext

### SYNOPSIS
Gets a context object for working with AI models.

### SYNTAX

```
Get-FastMCPContext [-Server] <PSObject> [[-ContextId] <string>]
```

### DESCRIPTION
The `Get-FastMCPContext` cmdlet retrieves a context object for the specified FastMCP server. The context is the main interface for adding tools, resources, and prompts, as well as for sending requests to the AI model.

### PARAMETERS

#### -Server
The FastMCP server instance to use.

```yaml
Type: PSObject
Required: True
Position: 0
Default value: None
```

#### -ContextId
Optional context identifier.

```yaml
Type: String
Required: False
Position: 1
Default value: New GUID
```

### EXAMPLES

#### Example 1: Get a context for a server
```powershell
$server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey "your-api-key"
$context = Get-FastMCPContext -Server $server
```

#### Example 2: Get a context with a specific ID
```powershell
$server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey "your-api-key"
$context = Get-FastMCPContext -Server $server -ContextId "session-12345"
```

## Set-Logging

### SYNOPSIS
Configures the logging settings for the FastMCP module.

### SYNTAX

```
Set-Logging [-Level] <LogLevel> [[-LogPath] <string>]
```

### DESCRIPTION
The `Set-Logging` cmdlet configures the logging level and output location for the FastMCP module. This allows you to control the verbosity of diagnostic information.

### PARAMETERS

#### -Level
The logging level to set.

```yaml
Type: LogLevel
Required: True
Position: 0
Default value: INFO
Accepted values: DEBUG, INFO, WARNING, ERROR, CRITICAL
```

#### -LogPath
Optional path to a log file.

```yaml
Type: String
Required: False
Position: 1
Default value: None
```

### EXAMPLES

#### Example 1: Set logging level to DEBUG
```powershell
Set-Logging -Level DEBUG
```

#### Example 2: Configure logging to write to a file
```powershell
Set-Logging -Level INFO -LogPath "C:\Logs\fastmcp.log"
```

## Get-Logger

### SYNOPSIS
Gets a logger instance for the specified component.

### SYNTAX

```
Get-Logger [-Name] <string>
```

### DESCRIPTION
The `Get-Logger` cmdlet retrieves a logger instance that can be used to log messages from a specific component. This is primarily used internally by the module but can also be used by consumers for consistent logging.

### PARAMETERS

#### -Name
The name of the component requesting the logger.

```yaml
Type: String
Required: True
Position: 0
Default value: None
```

### EXAMPLES

#### Example 1: Get a logger for a component
```powershell
$logger = Get-Logger -Name "MyComponent"
$logger.Info("Processing started")
$logger.Debug("Detailed information")
```

#### Example 2: Use the logger in a custom tool
```powershell
$customTool = New-Tool -Name "CustomProcess" -Description "Processes data with logging" -Function {
    param($data)
    
    $logger = Get-Logger -Name "CustomProcess"
    $logger.Info("Processing started")
    
    # Process data
    $result = $data | ForEach-Object { $_ * 2 }
    
    $logger.Info("Processing completed")
    return $result
}
```
