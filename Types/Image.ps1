<#
.SYNOPSIS
Helper class for returning images from tools
#>

# Define Image class
class Image {
    [string]$Path
    [byte[]]$Data
    [string]$Format
    hidden [string]$MimeType

    # Constructor with path
    Image([string]$path) {
        $this.Path = $path
        $this.Data = $null
        $this.Format = $null
        $this.MimeType = $this.GetMimeType()
    }

    # Constructor with binary data and format
    Image([byte[]]$data, [string]$format) {
        $this.Path = $null
        $this.Data = $data
        $this.Format = $format
        $this.MimeType = $this.GetMimeType()
    }

    # Get MIME type based on format or file extension
    [string] GetMimeType() {
        if ($this.Format) {
            return "image/$($this.Format.ToLower())"
        }
        
        if ($this.Path) {
            $extension = [System.IO.Path]::GetExtension($this.Path).ToLower()
            
            switch ($extension) {
                ".png"  { return "image/png" }
                ".jpg"  { return "image/jpeg" }
                ".jpeg" { return "image/jpeg" }
                ".gif"  { return "image/gif" }
                ".webp" { return "image/webp" }
                default { return "application/octet-stream" }
            }
        }
        
        return "image/png" # default for raw binary data
    }

    # Convert to MCP ImageContent
    [hashtable] ToImageContent() {
        $base64Data = ""
        
        if ($this.Path) {
            $bytes = [System.IO.File]::ReadAllBytes($this.Path)
            $base64Data = [Convert]::ToBase64String($bytes)
        }
        elseif ($this.Data) {
            $base64Data = [Convert]::ToBase64String($this.Data)
        }
        else {
            throw "No image data available"
        }

        return @{
            type = "image"
            data = $base64Data
            mimeType = $this.MimeType
        }
    }
}

# Helper function to create Image objects
function New-Image {
    [CmdletBinding(DefaultParameterSetName="Path")]
    param(
        [Parameter(ParameterSetName="Path", Mandatory=$true)]
        [string]$Path,
        
        [Parameter(ParameterSetName="Data", Mandatory=$true)]
        [byte[]]$Data,
        
        [Parameter(ParameterSetName="Data")]
        [string]$Format = "png"
    )

    if ($PSCmdlet.ParameterSetName -eq "Path") {
        return [Image]::new($Path)
    }
    else {
        return [Image]::new($Data, $Format)
    }
}
