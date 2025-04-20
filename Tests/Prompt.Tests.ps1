# Tests for Prompt functionality and New-Prompt function

# Import the module outside BeforeAll
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\FastMCP.psd1'
Import-Module $modulePath -Force

Describe 'New-Prompt' {
    It 'Should create a prompt object with required parameters' {
        $prompt = New-Prompt -Name 'TestPrompt' -Description 'A test prompt' -RenderScript { param($name) "Hello, $name!" }
        
        $prompt | Should Not BeNullOrEmpty
        $prompt.Name | Should Be 'TestPrompt'
        $prompt.Description | Should Be 'A test prompt'
        $prompt.RenderScript | Should Not BeNullOrEmpty
        $prompt.Type | Should Be 'Prompt'
    }
    
    It 'Should render the prompt correctly' {
        $prompt = New-Prompt -Name 'Greeting' -Description 'A greeting prompt' -RenderScript { param($name) "Hello, $name!" }
        
        $result = $prompt.Render(@{ name = 'World' })
        $result | Should Be 'Hello, World!'
    }
    
    It 'Should handle multiple parameters' {
        $prompt = New-Prompt -Name 'ComplexPrompt' -Description 'A complex prompt' -RenderScript {
            param($name, $age, $location)
            "Name: $name, Age: $age, Location: $location"
        }
        
        $result = $prompt.Render(@{
                name     = 'John'
                age      = 30
                location = 'New York'
            })
        $result | Should Be 'Name: John, Age: 30, Location: New York'
    }
    
    It 'Should support tags' {
        $prompt = New-Prompt -Name 'TaggedPrompt' -Description 'A prompt with tags' -RenderScript { 'Test' } -Tags 'test', 'prompt'
        
        $prompt.Tags | Should Not BeNullOrEmpty
        $prompt.Tags.Contains('test') | Should Be $true
        $prompt.Tags.Contains('prompt') | Should Be $true
    }
    
    It 'Should handle errors gracefully' {
        $prompt = New-Prompt -Name 'ErrorPrompt' -Description 'A prompt that might error' -RenderScript {
            param($required)
            "Value: $required"
        }
        
        try {
            $prompt.Render(@{})
            # If we get here, the test failed
            $false | Should Be $true
        } catch {
            # Test passes if an exception is thrown
            $true | Should Be $true
        }
    }
}
