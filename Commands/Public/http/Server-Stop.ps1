function Stop-GitServe {  # 'Stop-GitServeServer' sounded bad
    <#
    .synopsis
        Stop listen server
    .notes
        aliased as Stop-GitServe, GitServe.Stop
    .example
        # random ports
        > GitServe Stop

    .example
        > GitServe Stop -Host ip -Port port
    Maybe allow:
        > GitServe Stop ip:port
        > GitServe Stop port
    .LINK
        Stop-GitServe
    .LINK
        Stop-GitServe
    .LINK
        GitServe
    #>
    [Alias('GitServe.Stop')]
    [CmdletBinding()]
    param( )

    [Net.HttpListener] $list = $Script:Listener

    if( $script:nin_dbg ) {
        wait-debugger
    }
    if( $list.IsListening -or $null -ne $ModuleState.JobName ) {
        ( $list )?.Close()
        ( $list )?.Dispose()
        $list = $null

        Write-Warning "Job '${JobName}' was already running, stopping jobs..."
        Get-Job $ModuleState.JobName | Stop-Job -PassThru | Receive-Job -AutoRemoveJob -Wait

        if( -not ( Get-Job $ModuleState.JobName -ea ignore ) ) {
            $JobName = $Null
        }
        # $JobName = $Null
        'Total Remaining Jobs: {0}' -f (Get-Job).count | Write-Host
    }

    $msg = 'http://{0}:{1}' -f ( $script:ModuleState.HostName, $script:ModuleState.Port )
    "$( (Get-Date).ToString('u')) GitServe: Stopped listening on: ${msg}"
        | Write-Host

    if( $script:nin_dbg ) {
        wait-debugger
    }
}
