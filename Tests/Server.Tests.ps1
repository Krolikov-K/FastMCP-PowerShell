# Tests for Server functionality and New-FastMCPServer function

# Import the module outside BeforeAll
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\FastMCP.psd1'
Import-Module $modulePath -Force

Describe 'New-FastMCPServer' {
    It 'Should create a server object with required parameters' {
        $server = New-FastMCPServer -Endpoint 'https://api.example.com' -ApiKey 'test-api-key'
        
        $server | Should Not BeNullOrEmpty
        $server.Endpoint | Should Be 'https://api.example.com'
        $server.ApiKey | Should Be 'test-api-key'
        $server.Provider | Should Be 'OpenAI'
    }
    
    It 'Should allow specifying a provider' {
        $server = New-FastMCPServer -Endpoint 'https://api.example.com' -ApiKey 'test-api-key' -Provider 'Anthropic'
        
        $server.Provider | Should Be 'Anthropic'
    }
    
    It 'Should allow specifying a model' {
        $server = New-FastMCPServer -Endpoint 'https://api.example.com' -ApiKey 'test-api-key' -Model 'gpt-4'
        
        $server.Model | Should Be 'gpt-4'
    }
    
    It 'Should allow adding options' {
        $options = @{
            MaxTokens = 2000
            Temperature = 0.7
        }
        $server = New-FastMCPServer -Endpoint 'https://api.example.com' -ApiKey 'test-api-key' -Options $options
        
        $server.Options | Should Not BeNullOrEmpty
        $server.Options.MaxTokens | Should Be 2000
        $server.Options.Temperature | Should Be 0.7
    }
    
    It 'Should have a GetContext method' {
        $server = New-FastMCPServer -Endpoint 'https://api.example.com' -ApiKey 'test-api-key'
        
        # Check if method exists in a way compatible with Pester 3.4.0
        $hasMethod = $server | Get-Member -Name 'GetContext' -MemberType ScriptMethod
        $hasMethod | Should Not BeNullOrEmpty
        
        # Test method works
        $context = $server.GetContext()
        $context | Should Not BeNullOrEmpty
    }
}
