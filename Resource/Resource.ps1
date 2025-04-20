<#
.SYNOPSIS
Resource implementation for FastMCP
#>

# Resource class
class Resource
{
    [string]$URI
    [string]$Name
    [string]$Description
    [string]$MimeType
    [System.Collections.Generic.HashSet[string]]$Tags
    [scriptblock]$ContentProvider
    hidden [object]$Logger

    # Constructor
    Resource([hashtable]$params)
    {
        $this.URI = $params.URI
        $this.Name = $params.Name -or [System.IO.Path]::GetFileName($this.URI)
        $this.Description = $params.Description -or ''
        $this.MimeType = $params.MimeType -or 'text/plain'
        $this.Tags = $params.Tags | ConvertTo-Set
        $this.ContentProvider = $params.ContentProvider
        $this.Logger = Get-Logger 'Resource'
    }

    # Read the resource content
    [object] Read()
    {
        try
        {
            if ($this.ContentProvider)
            {
                return & $this.ContentProvider
            }
            elseif ($this.URI -like 'file:*')
            {
                $path = $this.URI -replace '^file://', ''
                
                # Determine how to read the file based on MIME type
                if ($this.MimeType -like 'text/*')
                {
                    return Get-Content -Path $path -Raw
                }
                else
                {
                    return [System.IO.File]::ReadAllBytes($path)
                }
            }
            else
            {
                throw [ResourceError]::new('No content provider available')
            }
        }
        catch
        {
            throw [ResourceError]::new("Error reading resource $($this.URI): $_")
        }
    }

    # Convert to MCP resource format
    [hashtable] ToMCPResource()
    {
        return @{
            uri         = $this.URI
            name        = $this.Name
            description = $this.Description
            mimeType    = $this.MimeType
        }
    }
}

# Function to create a new resource
function New-Resource
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$URI,
        
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [string]$Description,
        
        [Parameter()]
        [string]$MimeType = 'text/plain',
        
        [Parameter()]
        [string[]]$Tags,
        
        [Parameter()]
        [scriptblock]$ContentProvider
    )
    
    $params = @{
        URI             = $URI
        Name            = $Name
        Description     = $Description
        MimeType        = $MimeType
        Tags            = $Tags
        ContentProvider = $ContentProvider
    }
    
    return [Resource]::new($params)
}
