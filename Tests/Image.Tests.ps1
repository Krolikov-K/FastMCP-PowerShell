# Tests for Image class and New-Image function

# Import the module for Image class outside BeforeAll
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\FastMCP.psd1'
Import-Module $modulePath -Force

# Create a test image file
$testImagePath = Join-Path -Path $env:TEMP -ChildPath 'testImage.png'

# Create a simple image file for testing
[byte[]]$pngHeader = 137, 80, 78, 71, 13, 10, 26, 10
[System.IO.File]::WriteAllBytes($testImagePath, $pngHeader)

Describe 'New-Image' {
    It 'Should create an image object from a file path' {
        # Pass parameters positionally to avoid binding issues
        $image = & {
            param($name, $desc, $path)
            New-Image $name $desc $path
        } 'TestImage' 'A test image' $testImagePath
        
        $image | Should Not BeNullOrEmpty
        $image.Name | Should Be 'TestImage'
        $image.Description | Should Be 'A test image'
        $image.Path | Should Be $testImagePath
        $image.Type | Should Be 'Image'
    }
    
    It 'Should throw an error when the image file does not exist' {
        $scriptBlock = {
            New-Image 'MissingImage' 'Missing image' 'C:\path\to\nonexistent\image.png'
        }
        
        try {
            & $scriptBlock
            # If we get here, it didn't throw
            $threw = $false
        } catch {
            $threw = $true
            $_.Exception.Message | Should Match 'Image file not found'
        }
        
        $threw | Should Be $true
    }
    
    It 'Should support tags' {
        # Pass parameters positionally to avoid binding issues
        $image = & {
            param($name, $desc, $path, $tags)
            New-Image $name $desc $path -Tags $tags
        } 'TaggedImage' 'Image with tags' $testImagePath @('test', 'image')
        
        $image | Should Not BeNullOrEmpty
        $image.Tags | Should Not BeNullOrEmpty
        $image.Tags.Count | Should Be 2
    }
    
    # Add cleanup test at the end
    It 'Should clean up test files' {
        if (Test-Path $testImagePath) {
            Remove-Item $testImagePath -Force
        }
        (Test-Path $testImagePath) | Should Be $false
    }
}
