$MyModuleName = 'GitServe'
$MyPesterContainerConfig = @{
    EnableLogMockDebug = $false
    AlwaysRebuildModule = $false
}

$PSStyle.OutputRendering = 'Host'

# shared imports
Import-Module -Force ( Gi -ea 'stop' (  Join-Path $PSScriptRoot 'Tests/test_utils.psm1' ) )

if( $MyPesterContainerConfig.AlwaysRebuildModule ) {
    # running rebuild is redundant here, if you came from '/tests.ps1'
    .\Build\Build.Module.ps1
}

# force importing new module
Import-Module "$PSScriptRoot/${MyModuleName}.psd1" -Force

if( $MyPesterContainerConfig.EnableLogMockDebug ) {
    $PesterPreference.Debug.WriteDebugMessages = $true
    $PesterPreference.Debug.WriteDebugMessagesFrom = "Mock"
}
