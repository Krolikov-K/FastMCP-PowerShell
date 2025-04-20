<#
.SYNOPSIS
FastMCP - An ergonomic MCP interface for PowerShell
#>

# Import all module components
. $PSScriptRoot\Types\Image.ps1
. $PSScriptRoot\Types\Common.ps1
. $PSScriptRoot\Utilities\Logging.ps1
. $PSScriptRoot\Server\Context.ps1
. $PSScriptRoot\Server\Server.ps1
. $PSScriptRoot\Tools\ToolManager.ps1
. $PSScriptRoot\Tools\Tool.ps1
. $PSScriptRoot\Resources\ResourceManager.ps1
. $PSScriptRoot\Resources\Resource.ps1
. $PSScriptRoot\Prompts\PromptManager.ps1

# Export module members
Export-ModuleMember -Function @(
    'New-FastMCPServer', 
    'New-Image', 
    'New-Tool',
    'New-Resource',
    'New-Prompt',
    'Get-FastMCPContext'
)
