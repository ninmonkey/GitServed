<#
.SYNOPSIS
    Rebuild module, force reload, start, optionally with auto starting the listener
.example
    # defaults for everything
    . ./debug_harness.ps1

    # silence some outputs
    . .\debug_harness.ps1 -NoVerboseImport -NoVerboseServe -NoShowModuleExports

    # build, import, but also run from this thread
    . ./debug_harness.ps1 -StartListener

#>

param(
    [switch] $StartListener, # auto start HTTP Listener on 3001
    [switch] $NoVerboseImport, # Import-Module is verbose by default
    [switch] $NoVerboseServe, # Default is to make GitServe.Start run with -PSHost
    [switch] $NoThrowOnImport, # default is to throw this script if 'Import-Module' has any errors
    [switch] $NoShowModuleExports, # Don't show ExportedCommands after import?
    [int] $Port = 3001 # port number to listen on
)

#region config setup
$ModuleRoot = Get-Item -ea 'stop' ( Join-Path $PSScriptRoot '../..' )

$script:DebugPath = [ordered]@{
    WorkspaceRoot  = $ModuleRoot
    # ModuleRoot     = $ModuleRoot # is the same, does the user want to know ?
    ModuleManifest     = Join-Path $ModuleRoot 'GitServe.psd1'
    # ModuleImportPath = Join-Path $ModuleRoot 'GitServe'
    DebugHarnessScript = Get-Item $PSCommandPath
    ModuleRoot         = Get-Item -ea 'stop' $ModuleRoot
    BuildScript        = Get-Item ( Join-Path $ModuleRoot 'Build/Build.Module.ps1' )
    PesterRoot         = Get-Item ( Join-Path $ModuleROot 'Tests' )
    CommandsRoot       = Get-Item ( Join-Path $ModuleRoot 'Commands')
    RoutesRoot         = Get-Item ( Join-Path $ModuleRoot 'Routes')
}
$PSDefaultParameterValues['GitServe.Invoke-RealGit:PSHost'] = $true
$PSDefaultParameterValues['GitServe.Invoke-UGit:PSHost'] = $true
filter LogHeader {
    # Ie: <H1> Console color with formatting.
    $_ | JOin-String -f "`n## {0} ##`n" | write-host -fg LightCoral
}
filter LogInfo {
    # Ie: <INFO> Console color with formatting.
    $_ | write-host -fg MediumSeaGreen
}
filter LogWarn {
    $_ | Write-host -fg DarkRed -bg LightSalmon
}
#endregion config setup

#region build and import module
'Config: as $DebugPath' | LogInfo
$DebugPath | ft -AutoSize

$error.clear()
remove-module Gitserve -ea Ignore # Cleans up existing HttpListeners
'Building' | LogHeader
. $DebugPath.BuildScript

'Importing: as $curModInfo' | LogHeader
( $script:curModInfo = Import-Module $DebugPath.ModuleManifest -Force -PassThru -Verbose:( -not $NoVerboseImport ) )

if( $Global:Error.count -gt 0 ) {
    'Global Errors! {0}' -f $Global:Error.count | Write-Warning
    $Global:Error | Join-String -sep "`n" -f "- {0}" | LogWarn
    if( -not $NoThrowOnImport  ) { throw "ThrowOnImport!" }
}
if( -not $NoShowModuleExports ) {
    '(Get-Module).ExportedCommands' | LogHeader
    $curModInfo.ExportedCommands.Values | Ft -auto
}

#endregion build and import module

#region start example tests
'Start Example tests' | LogHeader
'Ex RealGit' | LogInfo
GitServe.Invoke-RealGit -DryRun -FromPath 'C:\data\myGit\GitServed' -ArgList 'log', '-n', '2'
#endregion start example tests

#region auto run after tests
if( $StartListener ) {
    "StartListener: GitServe.Start on port ${Port}" | LogInfo
    GitServe.Start -PSHost:( -not $NoVerboseServe ) -Port $Port
}
'Config: as $DebugPath' | LogInfo
$DebugPath | ft -AutoSize

'Debug vars: $DebugPath, $CurModInfo' | LogHeader
#endregion auto run after tests

# GitServe.Get-DatePaginationKey -StartDate ([datetime]::Now.AddDays(4)) -Period month
# GitServe.Get-NextDatePeriod'
# GitServe.Get-NextDatePeriod -CurrentDate $today -Period month
