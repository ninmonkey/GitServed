"$( Get-Date ) Enter: debug_harness.ps1" | Write-Host -fg 'orange'
$
PSCommandPath
    | Join-String -f "`n    enter: <file:///{0}>"
    | Write-Host -fg 'gray60'

"$( Get-Date ) Exit: debug_harness.ps1" | Write-Host -fg 'orange'
