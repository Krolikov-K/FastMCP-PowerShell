# Test runner for FastMCP module tests with Pester 3.4.0 compatibility

Write-Host "FastMCP Test Runner for Pester 3.4.0" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host

# List the test files to execute
$testFiles = @(
    'FastMCP.Tests.ps1',             # Core module tests
    'ResourceManager.Tests.ps1',      # Resource manager tests
    'ToolManager.Tests.ps1',         # Tool manager tests
    'Context.Tests.ps1',             # Context tests that work well
    'Server.Tests.ps1',              # Server tests (to be fixed)
    'Tool.Tests.ps1',                # Tool tests (to be fixed)
    'Image.Tests.ps1',               # Image tests (to be fixed)
    'Resource.Tests.ps1',            # Resource tests (to be fixed) 
    'Prompt.Tests.ps1',              # Prompt tests (to be fixed)
    'PromptManager.Tests.ps1',       # PromptManager tests (to be fixed)
    'Integration.Tests.ps1'          # Integration tests (to be fixed)
)

# Initialize test counters
$totalPassed = 0
$totalFailed = 0
$totalSkipped = 0
$failedTests = @()

# Run each test file separately to avoid errors with test handling
foreach ($testFile in $testFiles) {
    $testPath = Join-Path -Path $PSScriptRoot -ChildPath $testFile
    
    if (Test-Path $testPath) {
        Write-Host "Running tests in $testFile" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Cyan
        
        try {
            # Run the test and capture results
            $results = Invoke-Pester -Path $testPath -PassThru
            
            # Update counters
            $totalPassed += $results.PassedCount
            $totalFailed += $results.FailedCount
            $totalSkipped += $results.SkippedCount
            
            if ($results.FailedCount -gt 0) {
                $failedTests += $testFile
            }
        }
        catch {
            Write-Warning "Error running tests in $testFile"
            Write-Warning $_.Exception.Message
            $totalFailed++
            $failedTests += $testFile
        }
        
        Write-Host
    }
    else {
        Write-Host "Test file not found: $testFile" -ForegroundColor Yellow
    }
}

# Print summary
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "-----------" -ForegroundColor Cyan
Write-Host "Passed: $totalPassed" -ForegroundColor Green
Write-Host "Failed: $totalFailed" -ForegroundColor $(if ($totalFailed -gt 0) { 'Red' } else { 'Green' })
Write-Host "Skipped: $totalSkipped" -ForegroundColor Yellow
Write-Host

if ($failedTests.Count -gt 0) {
    Write-Host "Failed test files:" -ForegroundColor Red
    foreach ($file in $failedTests) {
        Write-Host " - $file" -ForegroundColor Red
    }
    Write-Host
}

Write-Host "NOTE: Some tests may fail due to Pester 3.4.0 compatibility issues." -ForegroundColor Yellow
Write-Host "To run specific tests, use: Invoke-Pester -Path '<path_to_test_file>'" -ForegroundColor Yellow

# Return success/failure for CI/CD pipelines
if ($totalFailed -gt 0) {
    exit 1
}
else {
    exit 0
}
