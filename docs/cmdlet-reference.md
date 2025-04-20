# FastMCP Cmdlet Reference

This document provides detailed information about all cmdlets available in the FastMCP PowerShell module.

## New-FastMCPServer

### SYNOPSIS
Creates a new FastMCP server instance for interacting with AI models.

### SYNTAX

```
New-FastMCPServer [-Endpoint] <string> [-ApiKey] <string> [[-Provider] <string>] [[-Model] <string>] [[-Options] <hashtable>]
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
Required: True
Position: 1
Default value: None
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
Default value: Depends on provider
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
    StreamingEnabled = $true
}
$server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey "your-api-key" -Model "gpt-4" -Options $options
```

## New-Image

### SYNOPSIS
Creates an image resource for use with AI models.

### SYNTAX

```
New-Image [-Name] <string> [-Description] <string> [-Path] <string> [[-Tags] <string[]>]
```

### DESCRIPTION
The `New-Image` cmdlet creates an image resource that can be shared with AI models that support image inputs. The image is loaded from the specified path and made available for use in the context.

### PARAMETERS

#### -Name
A unique name for the image resource.

```yaml
Type: String
Required: True
Position: 0
Default value: None
```

#### -Description
A description of the image content.

```yaml
Type: String
Required: True
Position: 1
Default value: None
```

#### -Path
The file path to the image.

```yaml
Type: String
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

#### Example 1: Create a basic image resource
```powershell
$image = New-Image -Name "ProductDiagram" -Description "Technical diagram of the product" -Path "./images/diagram.png"
```

#### Example 2: Create an image with tags
```powershell
$image = New-Image -Name "TeamPhoto" -Description "Company team photo from annual retreat" -Path "./images/team.jpg" -Tags "company", "team", "2023"
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
New-Resource [-Name] <string> [-Description] <string> [-Content] <object> [[-Type] <string>] [[-Tags] <string[]>]
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
Required: True
Position: 1
Default value: None
```

#### -Content
The resource content or a path to it.

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
Get-FastMCPContext [-Server] <FastMCPServer>
```

### DESCRIPTION
The `Get-FastMCPContext` cmdlet retrieves a context object for the specified FastMCP server. The context is the main interface for adding tools, resources, and prompts, as well as for sending requests to the AI model.

### PARAMETERS

#### -Server
The FastMCP server instance to use.

```yaml
Type: FastMCPServer
Required: True
Position: 0
Default value: None
```

### EXAMPLES

#### Example 1: Get a context for a server
```powershell
$server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey "your-api-key"
$context = Get-FastMCPContext -Server $server
```

#### Example 2: Get a context and configure it
```powershell
$server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey "your-api-key"
$context = Get-FastMCPContext -Server $server

# Add tools and resources
$context.AddTool($myTool)
$context.AddResource($myResource)
$context.AddPrompt($myPrompt)

# Configure context options
$context.SetOption("temperature", 0.8)
$context.SetOption("maxTokens", 2048)

# Send a request
$response = $context.SendRequest("What can you tell me about the data?")
```
