# Getting Started with FastMCP

This guide will help you get up and running with FastMCP for PowerShell.

## Installation

### From PowerShell Gallery

The easiest way to install FastMCP is from the PowerShell Gallery:

```powershell
Install-Module -Name FastMCP -Scope CurrentUser
```

To update an existing installation:

```powershell
Update-Module -Name FastMCP
```

### Manual Installation

You can also install FastMCP manually:

1. Clone or download the repository
2. Navigate to the FastMCP-PowerShell directory
3. Import the module:

```powershell
Import-Module .\FastMCP.psd1
```

## Basic Usage

FastMCP is designed to be intuitive and follows a consistent workflow:

1. Create a server connection
2. Get a context from the server
3. Add tools, resources, and prompts to the context
4. Send requests to the model

### Creating a Server Connection

First, create a connection to an AI model provider:

```powershell
# Create a server connection
$server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey $env:OPENAI_API_KEY
```

### Getting a Context

Next, get a context object that will manage your interaction with the model:

```powershell
# Get a context from the server
$context = Get-FastMCPContext -Server $server
```

### Adding Tools

Tools provide functionality that the AI can use:

```powershell
# Create a simple tool
$dateTool = New-Tool -Name "GetCurrentDate" -Description "Returns the current date and time" -Function {
    Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

# Add the tool to the context
$context.AddTool($dateTool)
```

### Adding Resources

Resources provide data that the AI can reference:

```powershell
# Create a simple resource
$companyPolicy = New-Resource -Name "VacationPolicy" -Description "Company vacation policy" -Content @"
# Vacation Policy

Employees are entitled to 20 days of paid vacation per year.
Vacation requests must be submitted at least 2 weeks in advance.
Unused vacation days can be carried over to the next year up to a maximum of 5 days.
"@

# Add the resource to the context
$context.AddResource($companyPolicy)
```

### Adding Prompts

Prompts define templates for structuring requests to the AI:

```powershell
# Create a simple prompt
$qaPrompt = New-Prompt -Name "QAPrompt" -Description "Question and answer format" -RenderScript {
    param($question)
    
    return @"
Please answer the following question clearly and concisely:

$question
"@
}

# Add the prompt to the context
$context.AddPrompt($qaPrompt)
```

### Sending Requests

Finally, send a request to the AI model:

```powershell
# Send a basic request
$response = $context.SendRequest("What is the capital of France?")
Write-Output $response.Content

# Send a request using a specific prompt
$response = $context.SendRequest("What is the company vacation policy?", @{
    promptName = "QAPrompt"
    promptArgs = @{ question = "What is the company vacation policy?" }
})
Write-Output $response.Content
```

## Complete Example

Let's put everything together in a complete example:

```powershell
# Import the module
Import-Module FastMCP

# Create a server connection
$server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey $env:OPENAI_API_KEY -Model "gpt-4"

# Get a context
$context = Get-FastMCPContext -Server $server

# Create and add a tool
$weatherTool = New-Tool -Name "GetWeather" -Description "Get weather for a location" -Function {
    param($location)
    
    # In a real scenario, you would call a weather API here
    $weather = @{
        location = $location
        temperature = "72°F"
        conditions = "Sunny"
        forecast = @("Sunny", "Partly Cloudy", "Rain", "Sunny", "Sunny")
    }
    
    return $weather
}
$context.AddTool($weatherTool)

# Create and add a resource
$travelTips = New-Resource -Name "TravelTips" -Description "Travel tips for various destinations" -Content @"
# Travel Tips

## Paris
- Visit the Eiffel Tower early to avoid crowds
- The Louvre is closed on Tuesdays
- Metro tickets can be purchased in bundles of 10 for savings

## Tokyo
- Use a Suica card for public transportation
- Most restaurants are closed between lunch and dinner
- Tipping is not customary
"@
$context.AddResource($travelTips)

# Create and add a prompt
$travelPrompt = New-Prompt -Name "TravelPlanner" -Description "Travel planning assistant" -RenderScript {
    param($destination, $duration, $interests)
    
    return @"
I'm planning a trip to $destination for $duration days.
I'm interested in: $($interests -join ', ').

Based on this information and the travel tips resource, please help me create an itinerary.
Include recommendations for:
1. Must-see attractions
2. Food and dining experiences
3. Day-by-day schedule
4. Practical tips specific to my interests
"@
}
$context.AddPrompt($travelPrompt)

# Send a request using the prompt
$response = $context.SendRequest("", @{
    promptName = "TravelPlanner"
    promptArgs = @{
        destination = "Paris"
        duration = 4
        interests = @("art", "history", "food")
    }
})

# Display the response
Write-Output $response.Content
```

## Next Steps

Now that you're familiar with the basics of FastMCP, you can:

1. Explore the [Cmdlet Reference](./cmdlet-reference.md) for detailed information about all available cmdlets
2. Check out the [Advanced Scenarios](./advanced-scenarios.md) guide for more complex use cases
3. Review the [Best Practices](./best-practices.md) for tips on getting the most out of FastMCP

For any issues or questions, please file them on our [GitHub repository](https://github.com/example/FastMCP-PowerShell/issues).
