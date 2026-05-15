# Smoke test for PSEG Pole Check API
# Usage: .\smoke-test.ps1 -ApiBaseUrl "https://your-container-app.azurecontainerapps.io"
param(
    [Parameter(Mandatory=$true)]
    [string]$ApiBaseUrl
)

$ErrorActionPreference = "Stop"
$failures = 0

function Test-Endpoint {
    param([string]$Name, [string]$Url, [string]$Method = "GET")
    Write-Host "Testing $Name..." -NoNewline
    try {
        $response = Invoke-RestMethod -Uri $Url -Method $Method -TimeoutSec 30
        Write-Host " PASS" -ForegroundColor Green
        return $response
    } catch {
        Write-Host " FAIL: $_" -ForegroundColor Red
        $script:failures++
        return $null
    }
}

# Test 1: Health / root endpoint
Test-Endpoint -Name "API Root" -Url "$ApiBaseUrl/"

# Test 2: Check that the API responds (at minimum) — adapt URL pattern to match actual routes if needed
# The API has /image/analyze endpoint based on docker image name
# Add more endpoint tests as the API surface becomes known

Write-Host ""
if ($failures -eq 0) {
    Write-Host "All smoke tests PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "$failures smoke test(s) FAILED" -ForegroundColor Red
    exit 1
}
