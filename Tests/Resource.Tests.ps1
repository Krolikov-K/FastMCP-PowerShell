# Tests for Resource functionality and New-Resource function

# Import the module outside BeforeAll
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\FastMCP.psd1'
Import-Module $modulePath -Force

Describe 'New-Resource' {
    It 'Should create a resource object with required parameters' {
        $resource = New-Resource 'TestResource' 'A test resource' 'Resource content'
        
        $resource | Should Not BeNullOrEmpty
        $resource.Name | Should Be 'TestResource'
        $resource.Description | Should Be 'A test resource'
        $resource.Content | Should Be 'Resource content'
        $resource.Type | Should Be 'text'
        $resource.ResourceType | Should Be 'Resource'
    }
    
    It 'Should allow specifying a type' {
        $jsonContent = '{"key":"value"}'
        $resource = New-Resource 'JsonResource' 'A JSON resource' $jsonContent -Type 'json'
        
        $resource.Type | Should Be 'json'
    }
    
    It 'Should support structured content' {
        $content = @{
            key1 = 'value1'
            key2 = 'value2'
            nested = @{
                key3 = 'value3'
            }
        }
        $resource = New-Resource 'StructuredResource' 'A structured resource' $content
        
        $resource.Content | Should Not BeNullOrEmpty
        $resource.Content.key1 | Should Be 'value1'
        $resource.Content.nested.key3 | Should Be 'value3'
    }
    
    It 'Should support tags' {
        $resource = New-Resource 'TaggedResource' 'A resource with tags' 'Content' -Tags @('test', 'resource')
        
        $resource.Tags | Should Not BeNullOrEmpty
        $resource.Tags.Count | Should Be 2
        $resource.Tags[0] | Should Be 'test'
        $resource.Tags[1] | Should Be 'resource'
    }
}
