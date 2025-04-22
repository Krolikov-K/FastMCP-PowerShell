# Advanced Scenarios with FastMCP

This guide covers advanced scenarios and techniques for using FastMCP effectively in complex workflows.

## Multi-Step Conversations

You can maintain context across multiple interactions with the AI model:

```powershell
# Initialize the conversation
$context = Get-FastMCPContext -Server $server

# First message
$response1 = $context.SendRequest("Tell me about quantum computing.")
Write-Output $response1.Content

# Follow-up without repeating context
$response2 = $context.SendRequest("What are its practical applications?")
Write-Output $response2.Content

# Another follow-up
$response3 = $context.SendRequest("Which companies are leading in this field?")
Write-Output $response3.Content
```

## Tool Chaining

Create complex workflows by combining multiple tools:

```powershell
# Create tools for a data processing pipeline
$dataLoader = New-Tool -Name "LoadData" -Description "Loads data from CSV" -Function {
    param($path)
    Import-Csv $path
}

$dataFilter = New-Tool -Name "FilterData" -Description "Filters data by criteria" -Function {
    param($data, $fieldName, $operator, $value)
    
    switch ($operator) {
        "eq" { $data | Where-Object { $_.$fieldName -eq $value } }
        "gt" { $data | Where-Object { $_.$fieldName -gt $value } }
        "lt" { $data | Where-Object { $_.$fieldName -lt $value } }
        "contains" { $data | Where-Object { $_.$fieldName -match $value } }
        default { throw "Unknown operator: $operator" }
    }
}

$dataAnalyzer = New-Tool -Name "AnalyzeData" -Description "Performs statistical analysis" -Function {
    param($data, $fields)
    
    $results = @{}
    foreach ($field in $fields) {
        $values = $data | ForEach-Object { $_.$field }
        $numericValues = $values | Where-Object { $_ -as [double] }
        
        if ($numericValues.Count -gt 0) {
            $results[$field] = @{
                Average = ($numericValues | Measure-Object -Average).Average
                Min = ($numericValues | Measure-Object -Minimum).Minimum
                Max = ($numericValues | Measure-Object -Maximum).Maximum
                Sum = ($numericValues | Measure-Object -Sum).Sum
            }
        } else {
            $valueCounts = @{}
            foreach ($value in $values) {
                if (-not $valueCounts.ContainsKey($value)) {
                    $valueCounts[$value] = 0
                }
                $valueCounts[$value]++
            }
            
            $results[$field] = @{
                UniqueValues = $valueCounts.Keys.Count
                MostCommon = $valueCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1 -ExpandProperty Key
                ValueCounts = $valueCounts
            }
        }
    }
    
    return $results
}

# Add tools to context
$context = Get-FastMCPContext -Server $server
$context.AddTool($dataLoader)
$context.AddTool($dataFilter)
$context.AddTool($dataAnalyzer)

# Use the tools together
$response = $context.SendRequest(@"
I need to analyze sales data. Please follow these steps:
1. Load data from 'sales_data.csv'
2. Filter to only include sales from 2023
3. Analyze the 'Revenue' and 'Units' fields
4. Provide insights about trends and patterns
"@)
```

## Dynamic Tool Creation

Create tools dynamically based on available functionality:

```powershell
# Get all available cmdlets for working with processes
$processCmdlets = Get-Command -Module Microsoft.PowerShell.Management -Name *process*

# Create tools for each relevant cmdlet
foreach ($cmdlet in $processCmdlets) {
    $toolName = $cmdlet.Name
    $toolDescription = "Executes the $($cmdlet.Name) cmdlet"
    
    $toolFunction = {
        param($parameters)
        
        $cmdletName = $args[0]
        $params = $parameters
        
        $result = & $cmdletName @params
        return $result
    }.GetNewClosure()
    
    # Create the tool with the cmdlet name as an argument
    $tool = New-Tool -Name $toolName -Description $toolDescription -Function $toolFunction -Arguments @($cmdlet.Name)
    
    # Add tool to context
    $context.AddTool($tool)
}

# Now the AI can work with processes using familiar PowerShell cmdlets
$response = $context.SendRequest("Get a list of the top 5 processes by memory usage and provide insights.")
```

## Custom Resource Handlers

Create more complex resources with custom handlers:

```powershell
# Create a database resource that connects on demand
$dbResource = New-Resource -Name "SalesDB" -Description "Sales database connection" -Content @{
    ConnectionString = "Server=myserver;Database=Sales;Integrated Security=True"
    Handler = {
        param($query)
        
        # In a real scenario, you would establish an actual DB connection
        # Here we simulate a database with sample data
        $data = @(
            [PSCustomObject]@{ OrderID = 1001; CustomerID = "C123"; Amount = 1250.00; Date = "2023-01-15" },
            [PSCustomObject]@{ OrderID = 1002; CustomerID = "C456"; Amount = 895.50; Date = "2023-01-16" },
            [PSCustomObject]@{ OrderID = 1003; CustomerID = "C789"; Amount = 2340.00; Date = "2023-01-18" }
        )
        
        # Simple query parsing for demonstration
        if ($query -match "WHERE\s+(\w+)\s*=\s*'([^']+)'") {
            $field = $Matches[1]
            $value = $Matches[2]
            $data = $data | Where-Object { $_.$field -eq $value }
        }
        
        return $data
    }
} -Type "database"

# Create a tool that uses the database resource
$queryTool = New-Tool -Name "QuerySalesDB" -Description "Queries the sales database" -Function {
    param($query)
    
    # Get the database resource
    $db = $context.GetResource("SalesDB")
    
    # Execute the query using the resource handler
    $result = & $db.Content.Handler $query
    return $result
}

# Add resource and tool to context
$context.AddResource($dbResource)
$context.AddTool($queryTool)

# Now the AI can query the database
$response = $context.SendRequest("Please get all sales orders for customer C456 and calculate the total amount.")
```

## Multi-Model Orchestration

Use different models for different tasks:

```powershell
# Create servers for different models
$gpt4Server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey $env:OPENAI_API_KEY -Model "gpt-4"
$gpt3Server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey $env:OPENAI_API_KEY -Model "gpt-3.5-turbo"

# Get contexts for both servers
$gpt4Context = Get-FastMCPContext -Server $gpt4Server
$gpt3Context = Get-FastMCPContext -Server $gpt3Server

# Create a tool that delegates to GPT-3.5 for certain tasks
$delegateTool = New-Tool -Name "SummarizeText" -Description "Summarizes text using GPT-3.5" -Function {
    param($text)
    
    # Use GPT-3.5 for summarization
    $response = $gpt3Context.SendRequest("Summarize the following text in 3-4 sentences: $text")
    return $response.Content
}

# Add the delegation tool to the main context
$gpt4Context.AddTool($delegateTool)

# Now GPT-4 can delegate summarization tasks to GPT-3.5
$response = $gpt4Context.SendRequest(@"
Please analyze this research paper and focus on the methodology and results.
For the introduction and background sections, provide just a brief summary.

[Research paper text...]
"@)
```

## Interactive Workflows

Create interactive workflows with user input:

```powershell
# Create a tool that prompts the user for input
$userInputTool = New-Tool -Name "GetUserInput" -Description "Asks the user a question and returns their answer" -Function {
    param($question)
    
    Write-Host -ForegroundColor Green "`nAI is asking: $question"
    $answer = Read-Host -Prompt "Your response"
    return $answer
}

# Create a tool that shows options to the user
$userChoiceTool = New-Tool -Name "GetUserChoice" -Description "Presents choices to the user and returns their selection" -Function {
    param($question, $options)
    
    Write-Host -ForegroundColor Green "`nAI is asking: $question"
    
    for ($i = 0; $i -lt $options.Count; $i++) {
        Write-Host "$($i+1). $($options[$i])"
    }
    
    do {
        $selection = Read-Host -Prompt "Enter your choice (1-$($options.Count))"
    } until ($selection -ge 1 -and $selection -le $options.Count)
    
    return @{
        SelectedOption = $options[$selection-1]
        SelectedIndex = $selection-1
    }
}

# Add the interactive tools to the context
$context.AddTool($userInputTool)
$context.AddTool($userChoiceTool)

# Start an interactive session
$response = $context.SendRequest(@"
You are a travel planning assistant. Help me plan a vacation by asking me questions.
Ask about my preferred destinations, budget, travel dates, and interests.
Then provide a personalized travel plan based on my answers.
"@)
```

## Progress Tracking for Long Tasks

Create tools that support progress reporting for long-running tasks:

```powershell
# Create a tool that processes data with progress reporting
$dataProcessor = New-Tool -Name "ProcessLargeDataset" -Description "Processes a large dataset with progress reporting" -Function {
    param($dataPath, $operations)
    
    # Load data
    $data = Import-Csv $dataPath
    $total = $data.Count
    $processed = 0
    $results = @()
    
    foreach ($item in $data) {
        # Update progress
        $processed++
        $percentComplete = [math]::Round(($processed / $total) * 100, 1)
        
        # Report progress
        $context.ReportProgress(@{
            operation = "Processing data"
            percentComplete = $percentComplete
            itemsProcessed = $processed
            totalItems = $total
        })
        
        # Process the item (simulated)
        Start-Sleep -Milliseconds 100 # Simulate processing time
        
        # Apply operations
        foreach ($op in $operations) {
            switch ($op.type) {
                "transform" {
                    # Apply transformations
                    $item = $op.transform.Invoke($item)
                }
                "filter" {
                    # Check if item should be included
                    if (-not $op.condition.Invoke($item)) {
                        continue
                    }
                }
            }
        }
        
        $results += $item
    }
    
    return $results
}

# Add the tool to the context
$context.AddTool($dataProcessor)

# Use the tool with progress tracking
$response = $context.SendRequest(@"
Process the dataset at 'large_dataset.csv' with the following operations:
1. Transform each item by converting prices to EUR
2. Filter to only include items with stock > 10
3. Analyze the results and provide insights
"@, @{ trackProgress = $true })
```

## Advanced Server Usage Examples

### Testing Server Connection
```powershell
$server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey "your-api-key"
if ($server.TestConnection()) {
    Write-Output "Server connection is successful."
} else {
    Write-Output "Failed to connect to the server."
}
```

### Reporting Progress in Long-Running Tasks
```powershell
$context = Get-FastMCPContext -Server $server
# Simulate progress updates in a long-running process
for ($i = 1; $i -le 100; $i += 20) {
    $progressInfo = @{
        Operation       = "Data Processing"
        PercentComplete = $i
        Timestamp       = (Get-Date)
    }
    $context.ReportProgress($progressInfo)
    Start-Sleep -Seconds 1
}
```

## Filesystem Operations

Create tools that allow the AI model to interact with the filesystem safely:

```powershell
# Create a server connection
$server = New-FastMCPServer -Endpoint "https://api.openai.com/v1" -ApiKey $env:OPENAI_API_KEY -Model "gpt-4"

# Get a context
$context = Get-FastMCPContext -Server $server

# Define a safe root directory for file operations
$safeRootDir = "C:\AIWorkspace"
if (-not (Test-Path $safeRootDir)) {
    New-Item -Path $safeRootDir -ItemType Directory -Force | Out-Null
}

# Create tools for file operations
$fileReadTool = New-Tool -Name "ReadFile" -Description "Reads content from a file in the safe workspace" -Function {
    param($relativePath)
    
    # Validate and sanitize the path
    $safePath = Join-Path -Path $safeRootDir -ChildPath $relativePath
    if (-not (Test-Path $safePath -PathType Leaf)) {
        return "Error: File does not exist: $relativePath"
    }
    
    # Check if file is within the safe directory
    $fullPath = Resolve-Path $safePath
    if (-not $fullPath.Path.StartsWith($safeRootDir, [StringComparison]::OrdinalIgnoreCase)) {
        return "Error: Access denied. Cannot read files outside the safe workspace."
    }
    
    # Read the file content
    try {
        $content = Get-Content -Path $safePath -Raw
        return $content
    } catch {
        return "Error reading file: $_"
    }
}

$fileWriteTool = New-Tool -Name "WriteFile" -Description "Writes content to a file in the safe workspace" -Function {
    param($relativePath, $content)
    
    # Validate and sanitize the path
    $safePath = Join-Path -Path $safeRootDir -ChildPath $relativePath
    $parentDir = Split-Path -Path $safePath -Parent
    
    # Check if parent directory exists and create if needed
    if (-not (Test-Path $parentDir)) {
        New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
    }
    
    # Check if path is within the safe directory
    $fullParentPath = Resolve-Path $parentDir
    if (-not $fullParentPath.Path.StartsWith($safeRootDir, [StringComparison]::OrdinalIgnoreCase)) {
        return "Error: Access denied. Cannot write files outside the safe workspace."
    }
    
    # Write the content
    try {
        Set-Content -Path $safePath -Value $content -Force
        return "File written successfully: $relativePath"
    } catch {
        return "Error writing file: $_"
    }
}

$fileDeleteTool = New-Tool -Name "DeleteFile" -Description "Deletes a file from the safe workspace" -Function {
    param($relativePath)
    
    # Validate and sanitize the path
    $safePath = Join-Path -Path $safeRootDir -ChildPath $relativePath
    if (-not (Test-Path $safePath -PathType Leaf)) {
        return "Error: File does not exist: $relativePath"
    }
    
    # Check if file is within the safe directory
    $fullPath = Resolve-Path $safePath
    if (-not $fullPath.Path.StartsWith($safeRootDir, [StringComparison]::OrdinalIgnoreCase)) {
        return "Error: Access denied. Cannot delete files outside the safe workspace."
    }
    
    # Delete the file
    try {
        Remove-Item -Path $safePath -Force
        return "File deleted successfully: $relativePath"
    } catch {
        return "Error deleting file: $_"
    }
}

# Create tools for directory operations
$listDirectoryTool = New-Tool -Name "ListDirectory" -Description "Lists files and directories in the safe workspace" -Function {
    param($relativePath = "")
    
    # Validate and sanitize the path
    $safePath = Join-Path -Path $safeRootDir -ChildPath $relativePath
    if (-not (Test-Path $safePath -PathType Container)) {
        return "Error: Directory does not exist: $relativePath"
    }
    
    # Check if directory is within the safe directory
    $fullPath = Resolve-Path $safePath
    if (-not $fullPath.Path.StartsWith($safeRootDir, [StringComparison]::OrdinalIgnoreCase)) {
        return "Error: Access denied. Cannot list directories outside the safe workspace."
    }
    
    # List the directory contents
    try {
        $items = Get-ChildItem -Path $safePath | Select-Object Name, LastWriteTime, @{Name="Type";Expression={if($_.PSIsContainer){"Directory"}else{"File"}}}
        return $items
    } catch {
        return "Error listing directory: $_"
    }
}

$createDirectoryTool = New-Tool -Name "CreateDirectory" -Description "Creates a directory in the safe workspace" -Function {
    param($relativePath)
    
    # Validate and sanitize the path
    $safePath = Join-Path -Path $safeRootDir -ChildPath $relativePath
    
    # Check if path is within the safe directory
    $parentDir = Split-Path -Path $safePath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
    }
    $fullParentPath = Resolve-Path $parentDir
    if (-not $fullParentPath.Path.StartsWith($safeRootDir, [StringComparison]::OrdinalIgnoreCase)) {
        return "Error: Access denied. Cannot create directories outside the safe workspace."
    }
    
    # Create the directory
    try {
        New-Item -Path $safePath -ItemType Directory -Force | Out-Null
        return "Directory created successfully: $relativePath"
    } catch {
        return "Error creating directory: $_"
    }
}

$searchFilesTool = New-Tool -Name "SearchFiles" -Description "Searches for files matching a pattern in the safe workspace" -Function {
    param($pattern, $relativePath = "")
    
    # Validate and sanitize the path
    $safePath = Join-Path -Path $safeRootDir -ChildPath $relativePath
    if (-not (Test-Path $safePath -PathType Container)) {
        return "Error: Directory does not exist: $relativePath"
    }
    
    # Check if directory is within the safe directory
    $fullPath = Resolve-Path $safePath
    if (-not $fullPath.Path.StartsWith($safeRootDir, [StringComparison]::OrdinalIgnoreCase)) {
        return "Error: Access denied. Cannot search directories outside the safe workspace."
    }
    
    # Search for files
    try {
        $items = Get-ChildItem -Path $safePath -Recurse -Filter $pattern | Select-Object FullName, LastWriteTime, Length
        # Convert full paths to relative paths
        $items | ForEach-Object {
            $_.FullName = $_.FullName.Replace($safeRootDir, "").TrimStart('\')
        }
        return $items
    } catch {
        return "Error searching files: $_"
    }
}

# Add all tools to the context
$context.AddTool($fileReadTool)
$context.AddTool($fileWriteTool)
$context.AddTool($fileDeleteTool)
$context.AddTool($listDirectoryTool)
$context.AddTool($createDirectoryTool)
$context.AddTool($searchFilesTool)

# Send a request to use the filesystem tools
$response = $context.SendRequest(@"
I need your help to organize a project in the file system. Please follow these steps:

1. Create a directory structure for a simple web project with folders for HTML, CSS, and JavaScript files
2. Create an index.html file with a basic HTML5 template
3. Create a styles.css file with some basic styling
4. Create a script.js file with a simple "Hello, World!" alert
5. List all the files you created
"@)

# Display the response
Write-Output $response.Content
```

These advanced scenarios demonstrate the flexibility and power of FastMCP for building complex AI-powered workflows in PowerShell.
