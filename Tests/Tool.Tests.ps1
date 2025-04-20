# Tests for Tool functionality and New-Tool function

# Import the module outside BeforeAll
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\FastMCP.psd1'
Import-Module $modulePath -Force

Describe 'New-Tool' {
    It 'Should create a tool object with required parameters' {
        # Using positional parameters to avoid binding issues
        $tool = New-Tool 'TestTool' 'A test tool' { param($a, $b) $a + $b }
        
        $tool | Should Not BeNullOrEmpty
        $tool.Name | Should Be 'TestTool'
        $tool.Description | Should Be 'A test tool'
        $tool.Function | Should Not BeNullOrEmpty
        $tool.Type | Should Be 'Tool'
    }
    
    It 'Should execute the tool function' {
        $tool = New-Tool 'Add' 'Adds two numbers' { param($a, $b) $a + $b }
        
        $result = & $tool.Function 2 3
        $result | Should Be 5
    }
    
    It 'Should support parameters' {
        $parameters = @{
            a = @{
                type = 'number'
                description = 'First number'
                required = $true
            }
            b = @{
                type = 'number'
                description = 'Second number'
                required = $true
            }
        }
        $tool = New-Tool 'Add' 'Adds two numbers' { param($a, $b) $a + $b } -Parameters $parameters
        
        $tool.Parameters | Should Not BeNullOrEmpty
        $tool.Parameters.a | Should Not BeNullOrEmpty
        $tool.Parameters.a.type | Should Be 'number'
        $tool.Parameters.b | Should Not BeNullOrEmpty
    }
    
    It 'Should support tags' {
        $tool = New-Tool 'TestTool' 'A test tool' { "Test" } -Tags @('test', 'tool')
        
        $tool.Tags | Should Not BeNullOrEmpty
        $tool.Tags.Count | Should Be 2
        $tool.Tags[0] | Should Be 'test'
        $tool.Tags[1] | Should Be 'tool'
    }
}
