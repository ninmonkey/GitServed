"$( Get-Date ) Enter: debug_harness.ps1" | Write-Host -fg 'orange'
$PSCommandPath
    | Join-String -f "`n    enter: <file:///{0}>"
    | Write-Host -fg 'gray60'

$HarnessConfig = @{
    RebuildModule = $True
    RebuildFormat = $false
}

$HomePath = gi -ea 'stop' (Join-Path $PSScriptRoot '..')
$GitPath = Gi -ea 'stop' 'H:\temp_clone\GitServedTemp'
$DotDebugPath = Get-Item $PSCommandPath
$ModBuildPath = Gi -ea 'stop' (Join-Path $PSSCriptRoot '../Build/Build.Module.ps1')
$ModBuildEzPath = Gi -ea 'stop' (Join-Path $PSSCriptRoot '../Build/Build.ezout.ps1')

if( $HarnessConfig.RebuildModule ) {
    . $ModBuildPath
}
if( $HarnessConfig.RebuildFormat ) {
    . $ModBuildEzPath
}

Join-Path $PSSCriptRoot '../Build/Build.Module.ps1'
Join-Path '.' '../Build/Build.Module.ps1'


'See: $HomePath, $GitPath, $DotDebugPath' | Write-Host -fg 'salmon'

"$( Get-Date ) Exit: debug_harness.ps1" | Write-Host -fg 'orange'
