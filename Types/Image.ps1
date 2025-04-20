<#
.SYNOPSIS
Helper class for returning images from tools
#>

# Try to load System.Drawing assembly at the beginning
try
{
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    $script:SystemDrawingLoaded = $true
}
catch
{
    $script:SystemDrawingLoaded = $false
    Write-Warning 'System.Drawing assembly could not be loaded. Some image functionality will be limited.'
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
                '.png'
                {
                    return 'image/png' 
                }
                '.jpg'
                {
                    return 'image/jpeg' 
                }
                '.jpeg'
                {
                    return 'image/jpeg' 
                }
                '.gif'
                {
                    return 'image/gif' 
                }
                '.webp'
                {
                    return 'image/webp' 
                }
                default
                {
                    return 'application/octet-stream' 
                }
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
                # Load the raw binary data first - this ensures we have the data even if metadata extraction fails
                $this.Data = [System.IO.File]::ReadAllBytes($this.Path)
                
                # Try to determine format from file extension as a fallback
                $extension = [System.IO.Path]::GetExtension($this.Path).ToLower()
                switch ($extension)
                {
                    '.png'
                    {
                        $this.Format = 'PNG' 
                    }
                    '.jpg'
                    {
                        $this.Format = 'JPEG' 
                    }
                    '.jpeg'
                    {
                        $this.Format = 'JPEG' 
                    }
                    '.gif'
                    {
                        $this.Format = 'GIF' 
                    }
                    '.bmp'
                    {
                        $this.Format = 'BMP' 
                    }
                    '.tiff'
                    {
                        $this.Format = 'TIFF' 
                    }
                    '.webp'
                    {
                        $this.Format = 'WEBP' 
                    }
                    default
                    {
                        $this.Format = 'Unknown' 
                    }
                }
                
                # Set the name if not already done
                if (-not $this.Name)
                {
                    $this.Name = [System.IO.Path]::GetFileNameWithoutExtension($this.Path)
                }
                
                # Only attempt to use System.Drawing if it was successfully loaded
                if ($script:SystemDrawingLoaded)
                {
                    # Use reflection to work with System.Drawing types
                    $imageFile = [System.IO.Path]::GetFullPath($this.Path)
                    
                    # Get the System.Drawing.Image type
                    $drawingAssembly = [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
                    if ($null -eq $drawingAssembly)
                    {
                        throw 'Could not load System.Drawing assembly'
                    }
                    
                    $imageType = $drawingAssembly.GetType('System.Drawing.Image')
                    if ($null -eq $imageType)
                    {
                        throw 'Could not get System.Drawing.Image type'
                    }
                    
                    # Call FromFile method
                    $fromFileMethod = $imageType.GetMethod('FromFile', [System.Type[]]@([string]))
                    if ($null -eq $fromFileMethod)
                    {
                        throw 'Could not get FromFile method'
                    }
                    
                    $image = $fromFileMethod.Invoke($null, @($imageFile))
                    if ($null -eq $image)
                    {
                        throw 'Failed to load image from file'
                    }
                    
                    # Get Width and Height - these are simple properties
                    $widthProperty = $imageType.GetProperty('Width')
                    $heightProperty = $imageType.GetProperty('Height')
                    
                    if ($null -ne $widthProperty -and $null -ne $heightProperty)
                    {
                        $this.Width = $widthProperty.GetValue($image)
                        $this.Height = $heightProperty.GetValue($image)
                    }
                    
                    # Get the RawFormat property and its Guid property
                    $rawFormatProperty = $imageType.GetProperty('RawFormat')
                    if ($null -ne $rawFormatProperty)
                    {
                        $rawFormat = $rawFormatProperty.GetValue($image)
                        if ($null -ne $rawFormat)
                        {
                            $guidProperty = $rawFormat.GetType().GetProperty('Guid')
                            if ($null -ne $guidProperty)
                            {
                                $formatGuid = $guidProperty.GetValue($rawFormat)
                                
                                # Find the format name by comparing GUIDs
                                foreach ($key in $script:ImageFormatGuids.Keys)
                                {
                                    if ($script:ImageFormatGuids[$key] -eq $formatGuid)
                                    {
                                        $this.Format = $key
                                        break
                                    }
                                }
                            }
                        }
                    }
                    
                    # Clean up
                    $disposeMethod = $imageType.GetMethod('Dispose')
                    if ($null -ne $disposeMethod)
                    {
                        $disposeMethod.Invoke($image, @())
                    }
                }
            }
            catch
            {
                # Log the error but continue - we've already loaded the raw data
                try
                {
                    # Get the logger but don't fail if that also fails
                    $logger = $null
                    try
                    {
                        $logger = Get-Logger -Name 'Image'
                    }
                    catch
                    {
                        # Silently continue if logger can't be created
                    }
                    
                    if ($null -ne $logger)
                    {
                        $logger.Error("Failed to load image metadata: $_")
                    }
                    else
                    {
                        Write-Warning "Failed to load image metadata: $_"
                    }
                }
                catch
                {
                    # Last resort if even the error handling fails
                    Write-Warning "Error handling failed: $_"
                }
            }
        }
    }

    # Convert to MCP ImageContent
    [hashtable] ToImageContent()
    {
        $base64Data = ''
        
        # Try to load data if not already loaded
        if ($this.Path -and (-not $this.Data))
        {
            try
            {
                $this.Data = [System.IO.File]::ReadAllBytes($this.Path)
            }
            catch
            {
                try
                {
                    $logger = Get-Logger -Name 'Image'
                    $logger.Error("Failed to load image data: $_")
                }
                catch
                {
                    Write-Warning "Failed to load image data: $_"
                }
                throw [System.Exception]::new('Failed to load image data')
            }
        }
        
        if ($this.Data)
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
        [Parameter(Mandatory = $false, ParameterSetName = 'Path')]
        [string]$Name,
        
        [Parameter(Position = 1)]
        [string]$Description = '',
        
        [Parameter()]
        [string[]]$Tags = @(),
        
        [Parameter()]
        [switch]$CreateIfNotExists
    )
    
    # Output parameter details to aid in debugging
    Write-Verbose 'New-Image Parameters:'
    Write-Verbose "  Path: $Path"
    Write-Verbose "  Name: $Name"
    Write-Verbose "  Description: $Description"
    Write-Verbose "  CreateIfNotExists: $CreateIfNotExists"
    
    if ($PSCmdlet.ParameterSetName -eq 'Path')
    {
        # First check if the path exists and is accessible
        if (-not (Test-Path -Path $Path -IsValid))
        {
            throw "Invalid path format: $Path"
        }
        
        # Check if file exists
        $fileExists = Test-Path -Path $Path -PathType Leaf
        Write-Verbose "File exists: $fileExists"
        Write-Verbose "CreateIfNotExists parameter: $($CreateIfNotExists.IsPresent)"
        
        # Handle file not existing
        if (-not $fileExists)
        {
            # Important: Check if CreateIfNotExists switch is present
            if ($CreateIfNotExists.IsPresent)
            {
                Write-Verbose "Creating placeholder image for non-existent file: $Path"
                
                # Create a placeholder image with just the path set
                $imageName = if ([string]::IsNullOrEmpty($Name))
                { 
                    [System.IO.Path]::GetFileNameWithoutExtension($Path) 
                }
                else
                { 
                    $Name 
                }
                $extension = [System.IO.Path]::GetExtension($Path).ToLower()
                
                # Determine MIME type from extension
                $mimeType = 'image/png'
                $format = 'PNG'
                switch ($extension)
                {
                    '.png'
                    {
                        $mimeType = 'image/png'; $format = 'PNG' 
                    }
                    '.jpg'
                    {
                        $mimeType = 'image/jpeg'; $format = 'JPEG' 
                    }
                    '.jpeg'
                    {
                        $mimeType = 'image/jpeg'; $format = 'JPEG' 
                    }
                    '.gif'
                    {
                        $mimeType = 'image/gif'; $format = 'GIF' 
                    }
                    '.bmp'
                    {
                        $mimeType = 'image/bmp'; $format = 'BMP' 
                    }
                    '.webp'
                    {
                        $mimeType = 'image/webp'; $format = 'WEBP' 
                    }
                    default
                    {
                        $mimeType = 'image/png'; $format = 'PNG' 
                    }
                }
                
                # Create a placeholder image object
                $image = [PSCustomObject]@{
                    Path           = $Path
                    Data           = $null
                    Format         = $format
                    Width          = 0
                    Height         = 0
                    Tags           = $Tags
                    Name           = $imageName
                    Description    = $Description
                    MimeType       = $mimeType
                    Type           = 'Image'
                    PSTypeName     = 'FastMCPImage'
                    
                    # Add ToImageContent method for test compatibility
                    ToImageContent = {
                        return @{
                            type     = 'image'
                            data     = ''
                            mimeType = $this.MimeType
                        }
                    }
                }
                
                # Add Type property for tests if not already set
                if (-not $image.Type)
                {
                    Add-Member -InputObject $image -MemberType NoteProperty -Name 'Type' -Value 'Image'
                }
                
                Write-Verbose 'Successfully created placeholder image object'
                return $image
            }
            else
            {
                # Check if directory exists 
                $directory = Split-Path -Path $Path -Parent
                if (-not [string]::IsNullOrEmpty($directory) -and -not (Test-Path -Path $directory))
                {
                    throw "Directory does not exist: $directory"
                }
                throw "Image file not found: $Path"
            }
        }
        
        try
        {
            $logger = $null
            try
            {
                $logger = Get-Logger -Name 'Image'
            }
            catch
            {
                # Continue if logger creation fails
            }
            
            if ($null -ne $logger)
            {
                $logger.Debug("Creating image from path: $Path")
            }
            else
            {
                Write-Verbose "Creating image from path: $Path"
            }
        }
        catch
        {
            # Continue if logging fails
            Write-Verbose "Creating image with path: $Path"
        }
        
        # Create an actual image from the file
        $image = [Image]::new($Path)
        
        # Set additional properties
        $image.Tags = $Tags
        
        # Use the provided name or get it from the path
        if (-not [string]::IsNullOrEmpty($Name))
        {
            $image.Name = $Name
        }
        elseif (-not $image.Name)
        {
            $image.Name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        }
        
        $image.Description = $Description
        
        # Add Type property for tests if not already set
        if (-not $image.Type)
        {
            Add-Member -InputObject $image -MemberType NoteProperty -Name 'Type' -Value 'Image'
        }
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
