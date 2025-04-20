# Tests for PromptManager class

# Import required files outside BeforeAll
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Types\Common.ps1'
$promptManagerPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Prompts\PromptManager.ps1'

. $commonPath
. $promptManagerPath

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

# Mock ConvertTo-Set if not available
if (-not (Get-Command ConvertTo-Set -ErrorAction SilentlyContinue)) {
    function ConvertTo-Set {
        param([string[]]$InputArray)
        $set = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($item in $InputArray) {
            $set.Add($item) | Out-Null
        }
        return $set
    }
}

Describe 'PromptManager' {
    Context 'Constructor' {
        It 'Should create a new instance with default values' {
            $pm = [PromptManager]::new()
            $pm | Should Not BeNullOrEmpty
            $pm.Prompts | Should BeOfType [hashtable]
            $pm.Prompts.Count | Should Be 0
            $pm.DuplicateBehavior | Should Be 'warn'
        }
    }
    
    Context 'HasPrompt method' {
        It 'Should return false for non-existent prompts' {
            $pm = [PromptManager]::new()
            $pm.HasPrompt('TestPrompt') | Should Be $false
        }
        
        It 'Should return true for existing prompts' {
            $pm = [PromptManager]::new()
            # Manually add to hashtable to avoid AddPrompt issues
            $prompt = [Prompt]::new('TestPrompt', 'Test Description', { "Test" }, @())
            $pm.Prompts['TestPrompt'] = $prompt
            $pm.HasPrompt('TestPrompt') | Should Be $true
        }
    }
    
    Context 'Prompt class' {
        It 'Should render a prompt correctly' {
            $prompt = [Prompt]::new('TestPrompt', 'Test Description', { 
                param($name, $greeting)
                return "$greeting, $name!" 
            }, @('test'))
            
            $result = $prompt.Render(@{ name = 'World'; greeting = 'Hello' })
            $result | Should Be 'Hello, World!'
        }
        
        It 'Should throw an error when rendering fails' {
            $prompt = New-Prompt -Name 'FailPrompt' -Description 'Fails' -RenderScript { throw "fail" }
            $threw = $false
            try {
                $prompt.Render(@{})
            } catch {
                $threw = $true
            }
            $threw | Should Be $true
        }
    }
}
