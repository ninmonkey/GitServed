"$( Get-Date ) Enter: debug_harness.ps1" | Write-Host -fg 'orange'
$PSCommandPath
    | Join-String -f "`n    enter: <file:///{0}>"
    | Write-Host -fg 'gray60'

$HarnessConfig = @{
    RebuildModule = $True
    RebuildFormat = $false
    ClearErrors = $true
}

if( $HarnessConfig.ClearErrors ) {
    $error.clear()
}

$WorkspaceModuleName = 'GitServed'
$HomePath       = gi -ea 'stop' (Join-Path $PSScriptRoot '..')
$GitPath        = Gi -ea 'stop' 'H:\temp_clone\GitServedTemp'
$DotDebugPath   = Get-Item $PSCommandPath
$ModBuildPath   = Gi -ea 'stop' (Join-Path $PSSCriptRoot '../Build/Build.Module.ps1')
$ModBuildEzPath = Gi -ea 'stop' (Join-Path $PSSCriptRoot '../Build/Build.ezout.ps1')

if( $HarnessConfig.RebuildModule ) {
    . $ModBuildPath
}
if( $HarnessConfig.RebuildFormat ) {
    . $ModBuildEzPath
}

# Join-Path $PSSCriptRoot '../Build/Build.Module.ps1'
# Join-Path '.' '../Build/Build.Module.ps1'


'See: $HomePath, $GitPath, $DotDebugPath' | Write-Host -fg 'salmon'

Remove-Module $WorkspaceModuleName -ea 'ignore'
# Import-Module "${WorkspaceModuleName}.psd1" -Passthru -Force
# Import-Module $WorkspaceModuleName -Passthru -Force
Import-Module "./${WorkspaceModuleName}" -Passthru -Force -ea 'stop'

# ipmo .\GitServed.psd1 -PassThru -Force
if( $Error.count -gt 0 ) {
    "Errors! $( $Error.count ) " | Write-Host -fg 'orange' # This might require script/global scope if this runs in the extension's debug terminal

}

"$( Get-Date ) Exit: debug_harness.ps1" | Write-Host -fg 'orange'
