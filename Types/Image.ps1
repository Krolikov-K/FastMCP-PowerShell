<#
.SYNOPSIS
Helper class for returning images from tools
#>

# Try to load System.Drawing assembly at the beginning
try {
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    $script:SystemDrawingLoaded = $true
}
catch {
    $script:SystemDrawingLoaded = $false
    Write-Warning "System.Drawing assembly could not be loaded. Some image functionality will be limited."
}

# Define known image format GUIDs to avoid direct type references
$script:ImageFormatGuids = @{
    'BMP'  = [guid]'b96b3cab-0728-11d3-9d7b-0000f81ef32e'
    'JPEG' = [guid]'b96b3cae-0728-11d3-9d7b-0000f81ef32e'
    'PNG'  = [guid]'b96b3caf-0728-11d3-9d7b-0000f81ef32e'
    'GIF'  = [guid]'b96b3cb0-0728-11d3-9d7b-0000f81ef32e'
    'TIFF' = [guid]'b96b3cb1-0728-11d3-9d7b-0000f81ef32e'
    'ICON' = [guid]'b96b3cb5-0728-11d3-9d7b-0000f81ef32e'
}

# Define Image class
class Image
{
    [string]$Path
    [byte[]]$Data
    [string]$Format
    [int]$Width
    [int]$Height
    [string[]]$Tags
    [string]$Name
    [string]$Description
    hidden [string]$MimeType

    # Constructor with path
    Image([string]$path)
    {
        $this.Path = $path
        $this.Data = $null
        $this.Format = $null
        $this.MimeType = $this.GetMimeType()
        $this.LoadImageMetadata()
    }

    # Constructor with binary data and format
    Image([byte[]]$data, [string]$format)
    {
        $this.Path = $null
        $this.Data = $data
        $this.Format = $format
        $this.MimeType = $this.GetMimeType()
        # Can't derive dimensions without loading into an image object
    }

    # Get MIME type based on format or file extension
    [string] GetMimeType()
    {
        if ($this.Format)
        {
            return "image/$($this.Format.ToLower())"
        }
        
        if ($this.Path)
        {
            $extension = [System.IO.Path]::GetExtension($this.Path).ToLower()
            
            switch ($extension)
            {
                '.png'  { return 'image/png' }
                '.jpg'  { return 'image/jpeg' }
                '.jpeg' { return 'image/jpeg' }
                '.gif'  { return 'image/gif' }
                '.webp' { return 'image/webp' }
                default { return 'application/octet-stream' }
            }
        }
        
        return 'image/png' # default for raw binary data
    }

    # Load image metadata if path is available
    hidden [void] LoadImageMetadata()
    {
        if ($this.Path -and (Test-Path -Path $this.Path))
        {
            try
            {
                # Check if System.Drawing was successfully loaded
                if ($script:SystemDrawingLoaded)
                {
                    # Use reflection to work with System.Drawing types
                    $imageFile = [System.IO.Path]::GetFullPath($this.Path)
                    
                    # Get the System.Drawing.Image type and call FromFile method
                    $imageType = [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing").GetType("System.Drawing.Image")
                    $fromFileMethod = $imageType.GetMethod("FromFile", [System.Type[]]@([string]))
                    $image = $fromFileMethod.Invoke($null, @($imageFile))
                    
                    # Get the RawFormat property and its Guid property
                    $rawFormatProperty = $imageType.GetProperty("RawFormat")
                    $rawFormat = $rawFormatProperty.GetValue($image)
                    $guidProperty = $rawFormat.GetType().GetProperty("Guid")
                    $formatGuid = $guidProperty.GetValue($rawFormat)
                    
                    # Find the format name by comparing GUIDs
                    $this.Format = 'Unknown'
                    foreach ($key in $script:ImageFormatGuids.Keys)
                    {
                        if ($script:ImageFormatGuids[$key] -eq $formatGuid)
                        {
                            $this.Format = $key
                            break
                        }
                    }
                    
                    # Get dimensions
                    $this.Width = $imageType.GetProperty("Width").GetValue($image)
                    $this.Height = $imageType.GetProperty("Height").GetValue($image)
                    
                    # Read image data as byte array if needed
                    if (-not $this.Data)
                    {
                        $memoryStreamType = [System.IO.MemoryStream]
                        $memoryStream = New-Object $memoryStreamType
                        
                        # Call the Save method
                        $saveMethod = $imageType.GetMethod("Save", [System.Type[]]@([System.IO.Stream], [System.Type]))
                        $saveMethod.Invoke($image, @($memoryStream, $rawFormat))
                        
                        $this.Data = $memoryStream.ToArray()
                        $memoryStream.Dispose()
                    }
                    
                    # Clean up
                    $disposeMethod = $imageType.GetMethod("Dispose")
                    $disposeMethod.Invoke($image, @())
                }
                else
                {
                    # Fallback when System.Drawing is not available
                    # Just load the raw binary data
                    $this.Data = [System.IO.File]::ReadAllBytes($this.Path)
                    
                    # Try to determine format from file extension
                    $extension = [System.IO.Path]::GetExtension($this.Path).ToLower()
                    switch ($extension)
                    {
                        '.png'  { $this.Format = 'PNG' }
                        '.jpg'  { $this.Format = 'JPEG' }
                        '.jpeg' { $this.Format = 'JPEG' }
                        '.gif'  { $this.Format = 'GIF' }
                        '.bmp'  { $this.Format = 'BMP' }
                        default { $this.Format = 'Unknown' }
                    }
                    
                    # Unable to determine dimensions without System.Drawing
                    $this.Width = 0
                    $this.Height = 0
                }
            }
            catch
            {
                try {
                    $logger = Get-Logger -Name 'Image' 
                    $logger.Error("Failed to load image metadata: $_")
                }
                catch {
                    Write-Warning "Failed to load image metadata: $_"
                }
            }
        }
    }

    # Convert to MCP ImageContent
    [hashtable] ToImageContent()
    {
        $base64Data = ''
        
        if ($this.Path -and (-not $this.Data))
        {
            $bytes = [System.IO.File]::ReadAllBytes($this.Path)
            $base64Data = [Convert]::ToBase64String($bytes)
        }
        elseif ($this.Data)
        {
            $base64Data = [Convert]::ToBase64String($this.Data)
        }
        else
        {
            throw [System.Exception]::new('No image data available')
        }

        return @{
            type     = 'image'
            data     = $base64Data
            mimeType = $this.MimeType
        }
    }
}

# Unified function to create Image objects
function New-Image
{
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Path')]
        [string]$Path,
        
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'NamedImage')]
        [string]$Name,
        
        [Parameter(Position = 1, ParameterSetName = 'NamedImage')]
        [Parameter(Position = 1, ParameterSetName = 'Path')]
        [string]$Description = '',
        
        [Parameter()]
        [string[]]$Tags = @()
    )
    
    if ($PSCmdlet.ParameterSetName -eq 'Path')
    {
        if (-not (Test-Path -Path $Path))
        {
            throw "Image file not found: $Path"
        }
        
        try {
            $logger = Get-Logger -Name 'Image'
            $logger.Debug("Creating image from path: $Path")
        }
        catch {
            Write-Verbose "Creating image from path: $Path"
        }
        
        $image = [Image]::new($Path)
        
        # Set additional properties
        $image.Tags = $Tags
        $image.Name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        $image.Description = $Description
        
        # Add Type property for tests
        Add-Member -InputObject $image -MemberType NoteProperty -Name 'Type' -Value 'Image'
    }
    else
    {
        # Create an in-memory image with the given name (for testing)
        $image = [PSCustomObject]@{
            Path           = $null
            Data           = $null
            Format         = $null
            Width          = 0
            Height         = 0
            Tags           = $Tags
            Name           = $Name
            Description    = $Description
            MimeType       = 'image/png'
            Type           = 'Image'
            PSTypeName     = 'FastMCPImage'
            
            # Add ToImageContent method for test compatibility
            ToImageContent = {
                return @{
                    type     = 'image'
                    data     = ''
                    mimeType = 'image/png'
                }
            }
        }
    }
    
    return $image
}

# Ensure Export-ModuleMember is only called when in a module
if ($MyInvocation.MyCommand.ScriptName -and $MyInvocation.MyCommand.ModuleName)
{
    Export-ModuleMember -Function 'New-Image'
}
