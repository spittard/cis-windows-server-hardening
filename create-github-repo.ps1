# Script to create GitHub repository and push code
param(
    [string]$RepoName = "cis-windows-server-hardening",
    [string]$Description = "CIS Windows Server 2022 hardening scripts with RDP connectivity fixes"
)

Write-Host "Creating GitHub repository: $RepoName" -ForegroundColor Green

# Check if GitHub CLI is available
try {
    $ghVersion = gh --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "GitHub CLI found. Creating repository..." -ForegroundColor Yellow
        
        # Create repository using GitHub CLI
        gh repo create $RepoName --public --description $Description --source=. --remote=origin --push
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Repository created successfully!" -ForegroundColor Green
            Write-Host "Repository URL: https://github.com/$(gh api user --jq .login)/$RepoName" -ForegroundColor Cyan
        } else {
            Write-Host "Failed to create repository with GitHub CLI" -ForegroundColor Red
            Write-Host "Please create the repository manually at: https://github.com/new" -ForegroundColor Yellow
        }
    } else {
        throw "GitHub CLI not found"
    }
} catch {
    Write-Host "GitHub CLI not available. Please create repository manually:" -ForegroundColor Yellow
    Write-Host "1. Go to https://github.com/new" -ForegroundColor White
    Write-Host "2. Repository name: $RepoName" -ForegroundColor White
    Write-Host "3. Description: $Description" -ForegroundColor White
    Write-Host "4. Make it Public" -ForegroundColor White
    Write-Host "5. Don't initialize with README (we already have one)" -ForegroundColor White
    Write-Host "6. Click 'Create repository'" -ForegroundColor White
    Write-Host ""
    Write-Host "Then run these commands:" -ForegroundColor Yellow
    Write-Host "git remote add origin https://github.com/YOUR_USERNAME/$RepoName.git" -ForegroundColor White
    Write-Host "git push -u origin master" -ForegroundColor White
}

# Show current git status
Write-Host "`nCurrent Git Status:" -ForegroundColor Cyan
git status --short

Write-Host "`nFiles ready to push:" -ForegroundColor Cyan
git ls-files | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
