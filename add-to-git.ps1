# Script to add all directories to Git repository
Write-Host "Adding all directories to Git repository..." -ForegroundColor Green

# Add all files and directories
git add .

# Check status
Write-Host "Git status:" -ForegroundColor Yellow
git status

# Commit all changes
Write-Host "Committing all changes..." -ForegroundColor Green
git commit -m "Add all local directories and CIS hardening files"

# Show final status
Write-Host "Final git status:" -ForegroundColor Yellow
git status

Write-Host "Done! All directories have been added to the repository." -ForegroundColor Green
