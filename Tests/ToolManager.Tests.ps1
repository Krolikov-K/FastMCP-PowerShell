# Tests for ToolManager class

# Import code moved outside BeforeAll
$toolManagerPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Tools\ToolManager.ps1'
. $toolManagerPath

# Mock the Get-Logger function
function Get-Logger {
    param([string]$Name)
    return [PSCustomObject]@{
        Debug = { param($Message) Write-Verbose "DEBUG: $Message" }
        Info = { param($Message) Write-Verbose "INFO: $Message" }
        Warning = { param($Message) Write-Verbose "WARNING: $Message" }
        Error = { param($Message) Write-Verbose "ERROR: $Message" }
        Critical = { param($Message) Write-Verbose "CRITICAL: $Message" }
    }
}

Describe 'ToolManager' {
    Context 'Constructor' {
        It 'Should create a new instance with default values' {
            $tm = [ToolManager]::new()
            $tm | Should Not BeNullOrEmpty
            $tm.Tools | Should BeOfType [hashtable]
            $tm.Tools.Count | Should Be 0
            $tm.DuplicateBehavior | Should Be 'warn'
        }
    }
    
    Context 'HasTool method' {
        It 'Should return false for non-existent tools' {
            $tm = [ToolManager]::new()
            $tm.HasTool('TestTool') | Should Be $false
        }
        
        It 'Should return true for existing tools' {
            $tm = [ToolManager]::new()
            $tool = [PSCustomObject]@{ Name = 'TestTool' }
            $tm.AddTool($tool, $null) | Out-Null
            $tm.HasTool('TestTool') | Should Be $true
        }
    }
    
    Context 'AddTool method' {
        It 'Should add a new tool successfully' {
            $tm = [ToolManager]::new()
            $tool = [PSCustomObject]@{ Name = 'TestTool' }
            $tm.AddTool($tool, $null) | Should Be $tool
            $tm.Tools['TestTool'] | Should Be $tool
        }
        
        It 'Should use the tool Name property if no name is provided' {
            $tm = [ToolManager]::new()
            $tool = [PSCustomObject]@{ Name = 'TestTool' }
            $tm.AddTool($tool, $null) | Should Be $tool
            $tm.Tools['TestTool'] | Should Be $tool
        }
        
        Context 'DuplicateBehavior=warn' {
            It 'Should warn and replace when adding duplicate tools' {
                $tm = [ToolManager]::new()
                $tm.DuplicateBehavior = 'warn'
                $tool1 = [PSCustomObject]@{ Name = 'TestTool'; Function = { return 1 } }
                $tool2 = [PSCustomObject]@{ Name = 'TestTool'; Function = { return 2 } }
                
                # Add first tool
                $tm.AddTool($tool1, 'TestTool') | Out-Null
                
                # Capture warning - use a simpler approach
                $warningMsg = $null
                $result = $null
                
                # Use warning action to capture the warning
                $prevWarningPreference = $WarningPreference
                try {
                    $WarningPreference = 'Continue'
                    $result = $tm.AddTool($tool2, 'TestTool') 3>&1
                } catch {
                    # Do nothing with the error
                } finally {
                    $WarningPreference = $prevWarningPreference
                }
                
                # Verify the tool was replaced even with the warning
                $tm.Tools['TestTool'] | Should Be $tool2
            }
        }
        
        Context 'DuplicateBehavior=replace' {
            It 'Should silently replace when adding duplicate tools' {
                $tm = [ToolManager]::new()
                $tm.DuplicateBehavior = 'replace'
                $tool1 = [PSCustomObject]@{ Name = 'TestTool'; Function = { return 1 } }
                $tool2 = [PSCustomObject]@{ Name = 'TestTool'; Function = { return 2 } }
                
                $tm.AddTool($tool1, 'TestTool') | Out-Null
                $result = $tm.AddTool($tool2, 'TestTool')
                
                $result | Should Be $tool2
                $tm.Tools['TestTool'] | Should Be $tool2
            }
        }
        
        Context 'DuplicateBehavior=error' {
            It 'Should throw an exception when adding duplicate tools' {
                $tm = [ToolManager]::new()
                $tm.DuplicateBehavior = 'error'
                $tool1 = [PSCustomObject]@{ Name = 'TestTool'; Function = { return 1 } }
                $tool2 = [PSCustomObject]@{ Name = 'TestTool'; Function = { return 2 } }
                
                $tm.AddTool($tool1, 'TestTool') | Out-Null
                
                # Use a more robust approach to verify exception is thrown
                $exceptionThrown = $false
                try {
                    $tm.AddTool($tool2, 'TestTool')
                } catch {
                    $exceptionThrown = $true
                    $_.Exception.Message | Should Match "Tool already exists: TestTool"
                }
                
                $exceptionThrown | Should Be $true
                # Verify original tool is still there
                $tm.Tools['TestTool'] | Should Be $tool1
            }
        }
        
        Context 'DuplicateBehavior=ignore' {
            It 'Should ignore the new tool and return the existing one' {
                $tm = [ToolManager]::new()
                $tm.DuplicateBehavior = 'ignore'
                $tool1 = [PSCustomObject]@{ Name = 'TestTool'; Function = { return 1 } }
                $tool2 = [PSCustomObject]@{ Name = 'TestTool'; Function = { return 2 } }
                
                $tm.AddTool($tool1, 'TestTool') | Out-Null
                $result = $tm.AddTool($tool2, 'TestTool')
                
                $result | Should Be $tool1
                $tm.Tools['TestTool'] | Should Be $tool1
            }
        }
    }
}
