# FastMCP for PowerShell

A PowerShell implementation of FastMCP - An ergonomic interface for the Model Context Protocol (MCP).

## Overview

FastMCP for PowerShell provides a streamlined way to work with the Model Context Protocol, enabling efficient interaction with AI models through a clean, PowerShell-native interface. This module helps you create, manage, and utilize model contexts with structured tools, resources, and prompts.

## Installation

### From PowerShell Gallery (Recommended)

```powershell
Install-Module -Name FastMCP
```

### Manual Installation

1. Clone this repository
2. Import the module directly:

```powershell
Import-Module "d:\path\to\FastMCP-PowerShell\FastMCP.psd1"
```

## Quick Start

```powershell
# Import the module
Import-Module FastMCP

# Create a new server instance
$server = New-FastMCPServer -Endpoint "https://api.example.com/v1" -ApiKey "your-api-key"

# Create an image
$image = New-Image -Name "My Image" -Description "A test image" -Path "C:\path\to\image.jpg"

# Create a tool
$tool = New-Tool -Name "Calculator" -Description "Performs calculations" -Function {
    param($operation, $a, $b)
    
    switch ($operation) {
        "add" { return $a + $b }
        "subtract" { return $a - $b }
        "multiply" { return $a * $b }
        "divide" { return $a / $b }
        default { throw "Unknown operation: $operation" }
    }
}

# Create a prompt
$prompt = New-Prompt -Name "Standard Query" -Description "A standard query format" -RenderScript {
    param($query, $context)
    
    return @"
Given the following context:
$context

Please respond to this query:
$query
"@
}

# Use the context
$context = Get-FastMCPContext -Server $server
$context.AddTool($tool)
$context.AddPrompt($prompt)

# Send a request
$response = $context.SendRequest("What is 2 + 2?")
```

## Core Concepts

FastMCP is built around these key concepts:

1. **Server** - The connection to the underlying AI model API
2. **Context** - The working environment for interacting with models
3. **Tools** - Functions that models can use to perform actions
4. **Resources** - Data assets like images, documents, or databases
5. **Prompts** - Templates for structuring requests to models

## Function Reference

### `New-FastMCPServer`

Creates a new FastMCP server instance that connects to a model provider.

```powershell
New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey $env:OPENAI_API_KEY -Provider "OpenAI"
```

Parameters:
- `Endpoint`: The API endpoint URL
- `ApiKey`: Your API authentication key
- `Provider`: The model provider (optional, defaults to "OpenAI")
- `Model`: The model to use (optional, defaults to provider's recommended model)
- `Options`: Additional options as hashtable (optional)

### `New-Image`

Creates an image resource for use with the model.

```powershell
New-Image -Name "Diagram" -Description "System architecture diagram" -Path "./diagram.png" -Tags "architecture", "documentation"
```

Parameters:
- `Name`: A unique name for the image
- `Description`: A description of the image content
- `Path`: File path to the image
- `Tags`: Optional array of tags for categorization

### `New-Tool`

Creates a tool that can be used by the model.

```powershell
New-Tool -Name "WeatherLookup" -Description "Gets current weather for a location" -Function {
    param($location)
    # Implementation would call a weather API
    return @{ temperature = 72; conditions = "Sunny"; location = $location }
}
```

Parameters:
- `Name`: A unique name for the tool
- `Description`: Description of what the tool does
- `Function`: ScriptBlock containing the tool's implementation
- `Parameters`: Optional parameter definitions
- `Tags`: Optional array of tags

### `New-Resource`

Creates a resource that can be referenced by the model.

```powershell
New-Resource -Name "UserManual" -Description "Product user manual" -Content $manualText -Type "text" -Tags "documentation"
```

Parameters:
- `Name`: A unique name for the resource
- `Description`: Description of the resource
- `Content`: The resource content or a path to it
- `Type`: The resource type (text, json, binary, etc.)
- `Tags`: Optional array of tags

### `New-Prompt`

Creates a prompt template for structuring requests.

```powershell
New-Prompt -Name "QueryWithContext" -Description "Basic query with context" -RenderScript {
    param($query, $additionalContext)
    
    return @"
Context information:
$additionalContext

User query: $query

Please provide a helpful response.
"@
}
```

Parameters:
- `Name`: A unique name for the prompt
- `Description`: Description of the prompt's purpose
- `RenderScript`: ScriptBlock that generates the formatted prompt
- `Tags`: Optional array of tags

### `Get-FastMCPContext`

Gets a context object for working with the model.

```powershell
$context = Get-FastMCPContext -Server $server
```

Parameters:
- `Server`: The FastMCP server instance to use

## Advanced Examples

### Creating a Multi-Tool Workflow

```powershell
# Set up tools for a data analysis workflow
$dataLoader = New-Tool -Name "LoadData" -Description "Loads data from CSV" -Function {
    param($path)
    Import-Csv $path
}

$dataTransformer = New-Tool -Name "TransformData" -Description "Performs data transformations" -Function {
    param($data, $operations)
    # Implementation of data transformations
    # ...
    return $transformedData
}

$dataVisualizer = New-Tool -Name "VisualizeData" -Description "Creates data visualizations" -Function {
    param($data, $type)
    # Implementation of visualization creation
    # ...
    return $visualizationPath
}

# Create the context and add all tools
$context = Get-FastMCPContext -Server $server
$context.AddTool($dataLoader)
$context.AddTool($dataTransformer)
$context.AddTool($dataVisualizer)

# Create an analysis workflow
$response = $context.SendRequest(@"
Please analyze the data in 'sales_data.csv':
1. Load the data
2. Transform it by aggregating by region and quarter
3. Create a bar chart visualization
4. Interpret the results
"@)
```

### Using Resources and Custom Prompts

```powershell
# Create a resource with company information
$companyInfo = New-Resource -Name "CompanyInfo" -Description "Company background information" -Content @"
Contoso Ltd. is a multinational corporation founded in 2005.
The company specializes in cloud computing solutions and has
over 10,000 employees across 30 countries.
"@ -Type "text"

# Create a prompt template for answering questions with company context
$companyPrompt = New-Prompt -Name "CompanyQuery" -Description "Query with company context" -RenderScript {
    param($query, $companyInfo)
    
    return @"
Company Information:
$companyInfo

Please answer the following question about the company:
$query
"@
}

# Use the context with the resource and prompt
$context = Get-FastMCPContext -Server $server
$context.AddResource($companyInfo)
$context.AddPrompt($companyPrompt)

# Send a request using the prompt
$response = $context.SendRequest("What industry is the company in?", @{
    promptName = "CompanyQuery"
    promptArgs = @{
        companyInfo = $companyInfo.Content
    }
})
```

## Logging Configuration

FastMCP includes a comprehensive logging system:

```powershell
# Import required type
Add-Type -TypeDefinition @"
public enum LogLevel {
    DEBUG,
    INFO,
    WARNING,
    ERROR,
    CRITICAL
}
"@

# Configure logging
Set-Logging -Level [LogLevel]::DEBUG

# Now all operations will log at DEBUG level
$server = New-FastMCPServer -Endpoint "https://api.example.com/v1" -ApiKey "your-api-key"
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.
