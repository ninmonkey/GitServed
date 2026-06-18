<#
.synopsis
    Rebuilds module source, TypeData/FormatData (if existing). Removes the module and force loads the new version.
#>
$DefaultPort         = 3006
$DefaultHost         = '127.0.0.1'
$WorkspaceModuleName = 'GitServe'
$GitPath             = Gi -ea 'stop' 'H:\temp_clone\GitServedTemp'

$WorkspaceRoot  = gi -ea 'stop' (Join-Path $PSScriptRoot '..')
$DotDebugPath   = Get-Item $PSCommandPath
$ModBuildPath   = Gi -ea 'stop' (Join-Path $PSScriptRoot './Build.Module.ps1')
$ModBuildEzPath = Gi -ea 'stop' (Join-Path $PSScriptRoot './Build.ezout.ps1')
$WorkspaceModuleImportPath = Join-Path $WorkspaceRoot "../${WorkspaceModuleName}"

if( $HarnessConfig.RebuildModule ) {
    . $ModBuildPath
}
if( $HarnessConfig.RebuildFormat ) {
    . $ModBuildEzPath
}

$curModule = Import-Module $WorkspaceModuleImportPath -Passthru -Force -ea 'stop'
$curModule.ExportedCommands.Values | Ft -auto

GitServe.Start -Verbose -Port $DefaultPort -HostName $DefaultHost
@'
    ## Usage:

        GitServe.Start -Port 3006 -HostName '127.0.0.1'
        GitServe.Stop

    # from another term
        irm 127.0.0.1:3006/repo/list -RetryIntervalSec 1 -MaximumRetryCount 1 -SkipHttpErrorCheck
'@  | Write-Host -bg 'gray30' -fg 'gray60'
