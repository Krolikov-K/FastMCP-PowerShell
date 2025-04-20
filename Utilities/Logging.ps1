<#
.SYNOPSIS
Logging utilities for FastMCP
#>

# Enum for log levels
if (-not ("LogLevel" -as [Type])) {
    Add-Type -TypeDefinition @"
public enum LogLevel {
    DEBUG,
    INFO,
    WARNING,
    ERROR,
    CRITICAL
}
"@
}

# Global log level setting
$script:LogLevel = [LogLevel]::INFO

# Function to set log level
function Set-Logging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [LogLevel]$Level
    )
    
    $script:LogLevel = $Level
}

# Function to get a logger
function Get-Logger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    $logger = [PSCustomObject]@{
        Name = $Name
        PSTypeName = 'FastMCPLogger'
    }
    
    # Add methods to the logger object
    $logger | Add-Member -MemberType ScriptMethod -Name 'Debug' -Value {
        param([string]$Message)
        if ($script:LogLevel -le [LogLevel]::DEBUG) {
            Write-Host "[DEBUG] [$($this.Name)] $Message" -ForegroundColor Gray
        }
    }
    
    $logger | Add-Member -MemberType ScriptMethod -Name 'Info' -Value {
        param([string]$Message)
        if ($script:LogLevel -le [LogLevel]::INFO) {
            Write-Host "[INFO] [$($this.Name)] $Message" -ForegroundColor White
        }
    }
    
    $logger | Add-Member -MemberType ScriptMethod -Name 'Warning' -Value {
        param([string]$Message)
        if ($script:LogLevel -le [LogLevel]::WARNING) {
            Write-Host "[WARNING] [$($this.Name)] $Message" -ForegroundColor Yellow
        }
    }
    
    $logger | Add-Member -MemberType ScriptMethod -Name 'Error' -Value {
        param([string]$Message)
        if ($script:LogLevel -le [LogLevel]::ERROR) {
            Write-Host "[ERROR] [$($this.Name)] $Message" -ForegroundColor Red
        }
    }
    
    $logger | Add-Member -MemberType ScriptMethod -Name 'Critical' -Value {
        param([string]$Message)
        if ($script:LogLevel -le [LogLevel]::CRITICAL) {
            Write-Host "[CRITICAL] [$($this.Name)] $Message" -ForegroundColor Red -BackgroundColor Black
        }
    }
    
    return $logger
}

# Export functions only if running inside a module
if ($MyInvocation.MyCommand.ModuleName)
{
    Export-ModuleMember -Function 'Set-Logging', 'Get-Logger'
}
