"$( Get-Date ) Enter: debug_harness.ps1" | Write-Host -fg 'orange'
$PSCommandPath
    | Join-String -f "`n    enter: <file:///{0}>"
    | Write-Host -fg 'gray60'

$HarnessConfig = @{
    RebuildModule      = $True
    RebuildFormat      = $false
    ClearErrors        = $true
    RunExampleTests    = $True
    RunClearCloneTests = $true
    RunCloneTests      = $false
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

# ipmo .\GitServed.psd1 -PassThru -Force
if( $Error.count -gt 0 ) {
    "Errors! $( $Error.count ) " | Write-Host -fg 'orange' # This might require script/global scope if this runs in the extension's debug terminal
}



if( $HarnessConfig.RunExampleTests ) {
    # section: optional examples

    $cloneUrl = 'https://github.com/BurntSushi/ripgrep.git'

    if( $HarnessConfig.RunCloneTests ) {
        # & ( $curModule ) { _InvokeCli.Git.CloneRepo -Url $cloneRepo }
        & ( $curModule ) {
            _InvokeCli.Git.CloneRepo -CloneUrl $cloneUrl -PsHost -FromPath $GitPath
        }
    }
    if( $HarnessConfig.RunClearCloneTests ) {
        gci -Path 'H:\temp_clone\GitServedTemp' -Directory
            | %{ rm $_ -Confirm:$false -Recurse -Force }

    }
}






"$( Get-Date ) Exit: debug_harness.ps1" | Write-Host -fg 'orange'
