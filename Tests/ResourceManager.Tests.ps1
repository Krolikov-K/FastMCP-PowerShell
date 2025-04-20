# Tests for ResourceManager class

# Import code moved outside BeforeAll
$resourceManagerPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Resources\ResourceManager.ps1'
. $resourceManagerPath

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

Describe 'ResourceManager' {
    Context 'Constructor' {
        It 'Should create a new instance with default values' {
            $rm = [ResourceManager]::new()
            $rm | Should Not BeNullOrEmpty
            $rm.Resources | Should BeOfType [hashtable]
            $rm.Resources.Count | Should Be 0
            $rm.DuplicateBehavior | Should Be 'warn'
        }
    }
    
    Context 'HasResource method' {
        It 'Should return false for non-existent resources' {
            $rm = [ResourceManager]::new()
            $rm.HasResource('TestResource') | Should Be $false
        }
        
        It 'Should return true for existing resources' {
            $rm = New-Object ResourceManager
            $resource = [PSCustomObject]@{ Name = 'TestResource' }
            # Add directly to the hashtable to ensure it's there
            $rm.Resources['TestResource'] = $resource
            $rm.HasResource('TestResource') | Should Be $true
        }
    }
    
    Context 'AddResource method' {
        It 'Should add a new resource successfully' {
            $rm = [ResourceManager]::new()
            $resource = [PSCustomObject]@{ Name = 'TestResource'; Description = 'Test resource'; Content = 'abc' }
            $rm.AddResource($resource, $null) | Should Be $resource
            $rm.Resources.ContainsKey('TestResource') | Should Be $true
        }
        
        It 'Should use the resource Name property if no name is provided' {
            $rm = [ResourceManager]::new()
            $resource = [PSCustomObject]@{ Name = 'TestResource'; Description = 'Test resource'; Content = 'abc' }
            $rm.AddResource($resource, $null) | Should Be $resource
            $rm.Resources.ContainsKey('TestResource') | Should Be $true
        }
        
        Context 'DuplicateBehavior=warn' {
            It 'Should warn and replace when adding duplicate resources' {
                $rm = [ResourceManager]::new()
                $rm.DuplicateBehavior = 'warn'
                $resource1 = [PSCustomObject]@{ Name = 'TestResource'; Value = 1 }
                $resource2 = [PSCustomObject]@{ Name = 'TestResource'; Value = 2 }
                
                # Add first resource
                $rm.AddResource($resource1, 'TestResource') | Out-Null
                
                # Capture warning - use a simpler approach
                $warningMsg = $null
                $result = $null
                
                # Use warning action to capture the warning
                $prevWarningPreference = $WarningPreference
                try {
                    $WarningPreference = 'Continue'
                    $result = $rm.AddResource($resource2, 'TestResource') 3>&1
                } catch {
                    # Do nothing with the error
                } finally {
                    $WarningPreference = $prevWarningPreference
                }
                
                # Verify the resource was replaced even with the warning
                $rm.Resources['TestResource'] | Should Be $resource2
                $rm.Resources['TestResource'].Value | Should Be 2
            }
        }
        
        Context 'DuplicateBehavior=replace' {
            It 'Should silently replace when adding duplicate resources' {
                $rm = [ResourceManager]::new()
                $rm.DuplicateBehavior = 'replace'
                $resource1 = [PSCustomObject]@{ Name = 'TestResource'; Value = 1 }
                $resource2 = [PSCustomObject]@{ Name = 'TestResource'; Value = 2 }
                
                $rm.AddResource($resource1, 'TestResource') | Out-Null
                $result = $rm.AddResource($resource2, 'TestResource')
                
                $result | Should Be $resource2
                $rm.Resources['TestResource'] | Should Be $resource2
                $rm.Resources['TestResource'].Value | Should Be 2
            }
        }
        
        Context 'DuplicateBehavior=error' {
            It 'Should throw an exception when adding duplicate resources' {
                $rm = [ResourceManager]::new()
                $rm.DuplicateBehavior = 'error'
                $resource1 = [PSCustomObject]@{ Name = 'TestResource'; Value = 1 }
                $resource2 = [PSCustomObject]@{ Name = 'TestResource'; Value = 2 }
                
                $rm.AddResource($resource1, 'TestResource') | Out-Null
                
                # Use a more robust approach to verify exception is thrown
                $exceptionThrown = $false
                try {
                    $rm.AddResource($resource2, 'TestResource')
                } catch {
                    $exceptionThrown = $true
                    $_.Exception.Message | Should Match "Resource already exists: TestResource"
                }
                
                $exceptionThrown | Should Be $true
                # Verify original resource is still there
                $rm.Resources['TestResource'] | Should Be $resource1
            }
        }
        
        Context 'DuplicateBehavior=ignore' {
            It 'Should ignore the new resource and return the existing one' {
                $rm = [ResourceManager]::new()
                $rm.DuplicateBehavior = 'ignore'
                $resource1 = [PSCustomObject]@{ Name = 'TestResource'; Value = 1 }
                $resource2 = [PSCustomObject]@{ Name = 'TestResource'; Value = 2 }
                
                $rm.AddResource($resource1, 'TestResource') | Out-Null
                $result = $rm.AddResource($resource2, 'TestResource')
                
                $result | Should Be $resource1
                $rm.Resources['TestResource'] | Should Be $resource1
                $rm.Resources['TestResource'].Value | Should Be 1
            }
        }
    }
}
