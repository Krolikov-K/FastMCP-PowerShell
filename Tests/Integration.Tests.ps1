# Integration tests for FastMCP module

# Import the module outside BeforeAll
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\FastMCP.psd1'
Import-Module $modulePath -Force

# Create a test image file
$testImagePath = Join-Path -Path $env:TEMP -ChildPath 'integrationTestImage.png'
[byte[]]$pngHeader = 137, 80, 78, 71, 13, 10, 26, 10
[System.IO.File]::WriteAllBytes($testImagePath, $pngHeader)

Describe 'FastMCP Integration' {
    # Create a server and context for all tests
    $server = New-FastMCPServer -Endpoint 'https://api.example.com' -ApiKey 'test-api-key'
    $context = Get-FastMCPContext -Server $server
    
    It 'Should build a complete workflow with all components' {
        # Create components using positional parameters
        $calculatorTool = & {
            param($name, $desc, $fn)
            New-Tool $name $desc $fn
        } 'Calculator' 'Performs basic math operations' {
            param($operation, $a, $b)
            
            switch ($operation) {
                'add' { return $a + $b }
                'subtract' { return $a - $b }
                'multiply' { return $a * $b }
                'divide' { return $a / $b }
                default { throw "Unknown operation: $operation" }
            }
        }
        
        # Create a resource
        $dataResource = & {
            param($name, $desc, $content)
            New-Resource $name $desc $content -Type 'json'
        } 'TestData' 'Sample data' @{
            users = @(
                @{ name = 'Alice'; age = 30 },
                @{ name = 'Bob'; age = 25 },
                @{ name = 'Charlie'; age = 35 }
            )
        }
        
        # Create a prompt
        $queryPrompt = & {
            param($name, $desc, $script)
            New-Prompt $name $desc $script
        } 'Query' 'A query prompt' {
            param($question, $context)
            
            return @"
Context information:
$context

User question: $question

Please provide a helpful response.
"@
        }
        
        # Add components to context and verify
        $context.AddTool($calculatorTool)
        $context.AddResource($dataResource)
        $context.AddPrompt($queryPrompt)
        
        $context.Tools['Calculator'] | Should Be $calculatorTool
        $context.Resources['TestData'] | Should Be $dataResource
        $context.Prompts['Query'] | Should Be $queryPrompt
    }
    
    # Add cleanup test at the end
    It 'Should clean up test files' {
        if (Test-Path $testImagePath) {
            Remove-Item $testImagePath -Force
        }
        (Test-Path $testImagePath) | Should Be $false
    }
}
