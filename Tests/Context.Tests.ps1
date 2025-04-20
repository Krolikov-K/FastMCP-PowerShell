# Tests for Context functionality and Get-FastMCPContext function

# Import the module outside BeforeAll
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\FastMCP.psd1'
Import-Module $modulePath -Force

Describe 'Get-FastMCPContext' {
    # Setup a server for all tests in this context
    $server = New-FastMCPServer -Endpoint 'https://api.example.com' -ApiKey 'test-api-key'
    
    It 'Should create a context object from a server' {
        $context = Get-FastMCPContext -Server $server
        
        $context | Should Not BeNullOrEmpty
        $context.Server | Should Be $server
        # Check if properties exist rather than checking if they're not empty
        $context.Tools.GetType().Name | Should Be 'Hashtable'
        $context.Resources.GetType().Name | Should Be 'Hashtable'
        $context.Prompts.GetType().Name | Should Be 'Hashtable'
    }
    
    Context 'Context methods' {
        # Setup for each test in this context
        $context = Get-FastMCPContext -Server $server
        $tool = New-Tool -Name 'TestTool' -Description 'Test tool' -Function { "Tool result" }
        $resource = New-Resource -Name 'TestResource' -Description 'Test resource' -Content 'Resource content'
        $prompt = New-Prompt -Name 'TestPrompt' -Description 'Test prompt' -RenderScript { "Prompt result" }
        
        It 'Should add a tool' {
            $context.AddTool($tool)
            
            $context.Tools.Count | Should Be 1
            $context.Tools['TestTool'] | Should Be $tool
        }
        
        It 'Should add a resource' {
            $context.AddResource($resource)
            
            $context.Resources.Count | Should Be 1
            $context.Resources['TestResource'] | Should Be $resource
        }
        
        It 'Should add a prompt' {
            $context.AddPrompt($prompt)
            
            $context.Prompts.Count | Should Be 1
            $context.Prompts['TestPrompt'] | Should Be $prompt
        }
        
        It 'Should send a request' {
            $response = $context.SendRequest('Test request')
            
            $response | Should Not BeNullOrEmpty
            $response.Request | Should Be 'Test request'
            $response.Content | Should Not BeNullOrEmpty
        }
        
        It 'Should use a prompt when sending a request' {
            $response = $context.SendRequest('Test request', @{
                promptName = 'TestPrompt'
                promptArgs = @{}
            })
            
            $response | Should Not BeNullOrEmpty
            $response.Request | Should Be 'Prompt result'
        }
    }
}
