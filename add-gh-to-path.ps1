# Script to find and add GitHub CLI to system PATH
Write-Host "Searching for GitHub CLI installation..." -ForegroundColor Green

# Common installation paths for GitHub CLI
$possiblePaths = @(
    "C:\Program Files\GitHub CLI\gh.exe",
    "$env:LOCALAPPDATA\Programs\GitHub CLI\gh.exe",
    "$env:PROGRAMFILES\GitHub CLI\gh.exe",
    "$env:PROGRAMFILES(X86)\GitHub CLI\gh.exe"
)

$ghPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $ghPath = Split-Path $path -Parent
        Write-Host "Found GitHub CLI at: $ghPath" -ForegroundColor Green
        break
    }
}

if ($ghPath) {
    # Add to current session PATH
    $env:PATH += ";$ghPath"
    Write-Host "Added to current session PATH" -ForegroundColor Yellow
    
    # Add to system PATH permanently
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$ghPath*") {
            [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$ghPath", "Machine")
            Write-Host "Added to system PATH permanently" -ForegroundColor Green
        } else {
            Write-Host "Already in system PATH" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to add to system PATH. Run as Administrator." -ForegroundColor Red
    }
    
    # Test the installation
    Write-Host "Testing GitHub CLI..." -ForegroundColor Cyan
    & "$ghPath\gh.exe" --version
    
} else {
    Write-Host "GitHub CLI not found. Installing..." -ForegroundColor Yellow
    
    # Try to install using winget
    try {
        winget install --id GitHub.cli --accept-package-agreements --accept-source-agreements
        Write-Host "GitHub CLI installed successfully!" -ForegroundColor Green
        Write-Host "Please restart your terminal or run this script again." -ForegroundColor Yellow
    } catch {
        Write-Host "Failed to install GitHub CLI. Please install manually from:" -ForegroundColor Red
        Write-Host "https://cli.github.com/" -ForegroundColor Cyan
    }
}

Write-Host "`nTo verify GitHub CLI is working, run:" -ForegroundColor Cyan
Write-Host "gh --version" -ForegroundColor White
