# PowerShell script to fix line 1895 in admin_dashboard_screen.dart
$file = "lib\screens\admin_dashboard_screen.dart"
$content = Get-Content $file -Raw

# Replace the malformed line
$content = $content -replace "if \(_isHistoryExpanded\) \.\.\.\[\\r\\n +_buildCalendarBookingInterface\(l10n\),", "if (_isHistoryExpanded) ...[`r`n                            _buildCalendarBookingInterface(l10n),"

Set-Content $file -Value $content -NoNewline
Write-Host "Fixed line 1895 in $file"
