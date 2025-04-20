<#
.SYNOPSIS
FastMCP - An ergonomic MCP interface for PowerShell
#>

# Define required directories
$requiredDirs = @(
    'Types',
    'Utilities',
    'Server',
    'Tools',
    'Resources',
    'Prompts'
)

# Create directories if they don't exist
foreach ($dir in $requiredDirs)
{
    $path = Join-Path -Path $PSScriptRoot -ChildPath $dir
    if (-not (Test-Path -Path $path))
    {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Define the module import order to handle dependencies
$moduleFiles = @(
    'Types\Common.ps1',
    'Utilities\Logging.ps1',
    'Types\Image.ps1',
    'Server\Server.ps1',
    'Server\Context.ps1',
    'Tools\Tool.ps1',
    'Tools\ToolManager.ps1',
    'Resources\Resource.ps1',
    'Resources\ResourceManager.ps1',
    'Prompts\PromptManager.ps1'
)

# Import all module files
foreach ($file in $moduleFiles)
{
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
    if (Test-Path -Path $filePath)
    {
        . $filePath
    }
    else
    {
        Write-Warning "Module file not found: $filePath"
    }
}

# Export module members - these will be defined in the individual files
Export-ModuleMember -Function @(
    'New-FastMCPServer', 
    'New-Image', 
    'New-Tool',
    'New-Resource',
    'New-Prompt',
    'Get-FastMCPContext',
    'Set-Logging',
    'Get-Logger'
)
