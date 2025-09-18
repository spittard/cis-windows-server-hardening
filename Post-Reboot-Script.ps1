# =============================================================================
# POST-REBOOT CIS HARDENING COMMANDS
# =============================================================================
# Run these commands after the server reboots from the main hardening script
# =============================================================================

Write-Host "=== POST-REBOOT CIS HARDENING COMMANDS ===" -ForegroundColor Cyan
Write-Host "Run these commands after reconnecting with AWS Session Manager" -ForegroundColor Yellow

Write-Host "`n1. Apply the modified CIS policy:" -ForegroundColor Green
Write-Host "C:\projects\cis-windows-server-hardening\LGPO_30\LGPO.exe /g `"C:\projects\cis-windows-server-hardening\Server2022StandAlonev1.0.0\MS-L1`"" -ForegroundColor White

Write-Host "`n2. Create firewall rule for RDP:" -ForegroundColor Green
Write-Host "New-NetFirewallRule -DisplayName `"Allow RDP`" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow" -ForegroundColor White

Write-Host "`n3. Verify RDP service status:" -ForegroundColor Green
Write-Host "Get-Service -Name TermService" -ForegroundColor White

Write-Host "`n4. Test RDP connectivity:" -ForegroundColor Green
Write-Host "Test-NetConnection -ComputerName localhost -Port 3389" -ForegroundColor White

Write-Host "`n5. Rename CISADMIN to Administrator:" -ForegroundColor Green
Write-Host "Rename-LocalUser -Name CISADMIN -NewName Administrator" -ForegroundColor White
Write-Host "Write-Host 'CISADMIN account renamed to Administrator successfully' -ForegroundColor Green" -ForegroundColor White

Write-Host "`n6. Verify Administrator account:" -ForegroundColor Green
Write-Host "Get-LocalUser -Name Administrator" -ForegroundColor White
Write-Host "Get-LocalGroupMember -Group Administrators | Where-Object {`$_.Name -like '*Administrator*'}" -ForegroundColor White
Write-Host "Get-LocalGroupMember -Group 'Remote Desktop Users' | Where-Object {`$_.Name -like '*Administrator*'}" -ForegroundColor White

Write-Host "`n=== COMPLETE SETUP INSTRUCTIONS ===" -ForegroundColor Cyan
Write-Host "`n1. Launch a fresh, new EC2 instance" -ForegroundColor Yellow
Write-Host "2. Prepare the server:" -ForegroundColor Yellow
Write-Host "   - Clone the repository to C:\projects\cis-windows-server-hardening" -ForegroundColor White
Write-Host "   - Ensure LGPO.exe is in LGPO_30 folder" -ForegroundColor White
Write-Host "   - Ensure Server2022StandAlonev1.0.0 folder is present" -ForegroundColor White
Write-Host "   - CISADMIN user will be created and later renamed to Administrator" -ForegroundColor White
Write-Host "   - Confirm you can log in with RDP" -ForegroundColor White
Write-Host "3. Run the main hardening script via AWS Session Manager" -ForegroundColor Yellow
Write-Host "4. After reboot, reconnect with Session Manager and run the post-reboot commands above" -ForegroundColor Yellow

Write-Host "`nYour server is now hardened with CIS baseline and RDP access is fully functional!" -ForegroundColor Green
