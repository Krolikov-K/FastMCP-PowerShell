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
    BeforeAll {
        # Check if System.Drawing is available
        try {
            Add-Type -AssemblyName System.Drawing -ErrorAction Stop
            $script:systemDrawingAvailable = $true
        }
        catch {
            $script:systemDrawingAvailable = $false
            Write-Warning "System.Drawing not available. Some tests will be skipped."
        }
    }
    
    It 'Should create an image object from a file path' {
        $image = New-Image -Path $testImagePath -Description 'A test image' -Name 'TestImage'
        
        $image | Should -Not -BeNullOrEmpty
        $image.Name | Should -Be 'TestImage'
        $image.Description | Should -Be 'A test image'
        $image.Path | Should -Be $testImagePath
        $image.Type | Should -Be 'Image'
    }
    
    It 'Should throw an error when the image file does not exist' {
        $scriptBlock = {
            New-Image -Path 'C:\path\to\nonexistent\image.png' -Description 'Missing image' -Name 'MissingImage'
        }
        
        $scriptBlock | Should -Throw -ExpectedMessage 'Image file not found*'
    }
    
    It 'Should support tags' {
        $image = New-Image -Path $testImagePath -Description 'Image with tags' -Name 'TaggedImage' -Tags @('test', 'image')
        
        $image | Should -Not -BeNullOrEmpty
        $image.Tags | Should -Not -BeNullOrEmpty
        $image.Tags.Count | Should -Be 2
    }
    
    # Test metadata loading only when System.Drawing is available
    It 'Should load image metadata with System.Drawing if available' -Skip:(-not $script:systemDrawingAvailable) {
        $image = New-Image -Path $testImagePath -Description 'Test Image' -Name 'MetadataTest'
        
        # These properties get populated when System.Drawing is loaded
        $image.Format | Should -Not -BeNullOrEmpty
        $image.MimeType | Should -Not -BeNullOrEmpty
    }
    
    # Add cleanup test at the end
    It 'Should clean up test files' {
        if (Test-Path $testImagePath) {
            Remove-Item $testImagePath -Force
        }
        (Test-Path $testImagePath) | Should -Be $false
    }
}
