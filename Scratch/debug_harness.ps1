"$( Get-Date ) Enter: debug_harness.ps1" | Write-Host -fg 'orange'
$PSCommandPath
    | Join-String -f "`n    enter: <file:///{0}>"
    | Write-Host -fg 'gray60'

$HarnessConfig = @{
    RebuildModule      = $false
    RebuildFormat      = $false
    ClearErrors        = $true
    RunExampleTests    = $True
    RunClearCloneTests = $true
    RunCloneTests      = $false
    TestPort = 3004
}

if( $HarnessConfig.ClearErrors ) {
    $error.clear()
}

$WorkspaceModuleName = 'GitServe'
$HomePath       = gi -ea 'stop' (Join-Path $PSScriptRoot '..')
$GitPath        = Gi -ea 'stop' 'H:\temp_clone\GitServedTemp'
$DotDebugPath   = Get-Item $PSCommandPath
$ModBuildPath   = Gi -ea 'stop' (Join-Path $PSSCriptRoot '../Build/Build.Module.ps1')
$ModBuildEzPath = Gi -ea 'stop' (Join-Path $PSSCriptRoot '../Build/Build.ezout.ps1')
$WorkspaceModuleImportPath = Join-Path $PSScriptRoot "../${WorkspaceModuleName}"

if( $HarnessConfig.RebuildModule ) {
    . $ModBuildPath
}
if( $HarnessConfig.RebuildFormat ) {

    . $ModBuildEzPath
}

# Join-Path $PSSCriptRoot '../Build/Build.Module.ps1'
# Join-Path '.' '../Build/Build.Module.ps1'


'See: $HomePath, $GitPath, $DotDebugPath, $curModule <instance>' | Write-Host -fg 'salmon'
Remove-Module $WorkspaceModuleName -ea 'ignore'
# Import-Module "${WorkspaceModuleName}.psd1" -Passthru -Force
# Import-Module $WorkspaceModuleName -Passthru -Force

$curModule = Import-Module $WorkspaceModuleImportPath -Passthru -Force -ea 'stop'
# $curModule = Import-Module "./${WorkspaceModuleName}" -Passthru -Force -ea 'stop'
$curModule.ExportedCommands.Values | Ft -auto

function ShowJobErr {
    param( $Job )
    # $job = Get-Job | ? name -Match 'gitserve' | Select -First 1
    $serr = $job.Error
    if( -not $serr ) {
        'No errors in first job!' | Write-Host -fg 'green'
        return
    }
    $serr.Exception | Get-Error
    $serr.Exception | fl * -Force
}


# ipmo .\GitServed.psd1 -PassThru -Force
if( $Error.count -gt 0 ) {
    "Errors! $( $Error.count ) " | Write-Host -fg 'orange' # This might require script/global scope if this runs in the extension's debug terminal
}


GitServe.Start -Port $HarnessConfig.TestPort

$irmSplat = @{
    Uri                      = 'http://127.0.0.1:{0}' -f $HarnessConfig.TestPort
    MaximumRetryCount        = 1
    OperationTimeoutSeconds  = 2
    ConnectionTimeoutSeconds = 2
    RetryIntervalSec         = 1
}

irm @irmSplat
