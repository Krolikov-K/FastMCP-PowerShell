@{
    RootModule        = 'FastMCP.psm1'
    ModuleVersion     = '0.1.1'
    GUID              = '12345678-1234-1234-1234-123456789012'
    Author            = 'Konstantin Krolikov'
    Description       = 'PowerShell implementation of FastMCP - An ergonomic interface for the Model Context Protocol (MCP)'
    FunctionsToExport = @(
        'New-FastMCPServer', 
        'New-Image', 
        'New-Tool',
        'New-Resource',
        'New-Prompt',
        'Get-FastMCPContext',
        'Set-Logging',
        'Get-Logger'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('MCP', 'AI', 'Model', 'Context', 'Protocol')
            ProjectUri = 'https://github.com/example/FastMCP-PowerShell'
        }
    }
}
