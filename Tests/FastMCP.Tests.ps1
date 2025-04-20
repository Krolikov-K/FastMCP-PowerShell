# Main test file for FastMCP module

# Import the module for testing - moved outside BeforeAll
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\FastMCP.psd1'
Import-Module $modulePath -Force

Describe 'FastMCP Module Tests' {
    Context 'Module Integrity' {
        It 'Should import the module without errors' {
            { Import-Module $modulePath -Force } | Should Not Throw
        }
        
        It 'Should export required functions' {
            $expectedFunctions = @(
                'New-FastMCPServer', 
                'New-Image', 
                'New-Tool',
                'New-Resource',
                'New-Prompt',
                'Get-FastMCPContext'
            )
            
            $exportedFunctions = Get-Command -Module FastMCP | Select-Object -ExpandProperty Name
            
            foreach ($function in $expectedFunctions) {
                # Check if the function exists in the exported functions using direct comparison
                $exists = $false
                foreach ($exportedFunction in $exportedFunctions) {
                    if ($exportedFunction -eq $function) {
                        $exists = $true
                        break
                    }
                }
                $exists | Should Be $true # Function should exist
            }
        }
    }
}

# Remove the dot-sourcing of the other test files to prevent errors
# Individual test files should be run separately
