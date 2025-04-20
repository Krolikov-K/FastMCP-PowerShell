<#
.SYNOPSIS
Logging utilities for FastMCP
#>

enum LogLevel {
    DEBUG
    INFO
    WARNING
    ERROR
    CRITICAL
}

# Configuration for logging
$script:LogLevel = [LogLevel]::INFO
$script:LogPrefix = "FastMCP"

# Get a logger for a specific component
function Get-Logger {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    $loggerName = "$script:LogPrefix.$Name"
    
    return @{
        Debug = {
            param([string]$Message)
            if ($script:LogLevel -le [LogLevel]::DEBUG) {
                Write-Debug "[$loggerName] $Message"
            }
        }
        Info = {
            param([string]$Message)
            if ($script:LogLevel -le [LogLevel]::INFO) {
                Write-Information "[$loggerName] $Message"
            }
        }
        Warning = {
            param([string]$Message)
            if ($script:LogLevel -le [LogLevel]::WARNING) {
                Write-Warning "[$loggerName] $Message"
            }
        }
        Error = {
            param([string]$Message)
            if ($script:LogLevel -le [LogLevel]::ERROR) {
                Write-Error "[$loggerName] $Message"
            }
        }
        Critical = {
            param([string]$Message)
            if ($script:LogLevel -le [LogLevel]::CRITICAL) {
                Write-Error "[$loggerName] CRITICAL: $Message"
            }
        }
    }
}

# Configure logging
function Set-Logging {
    param(
        [Parameter()]
        [LogLevel]$Level = [LogLevel]::INFO
    )
    
    $script:LogLevel = $Level
    
    # Configure PowerShell's information stream for our logging
    $InformationPreference = "Continue"
}
