function Stop-GitServe {  # 'Stop-GitServeServer' sounded bad
    <#
    .synopsis
        Stop listen server. Dispose of HttpListener and ThreadJobs
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
    .LINK
        https://learn.microsoft.com/en-us/dotnet/api/system.net.httplistener?view=net-10.0
    #>
    [Alias('GitServe.Stop')]
    [CmdletBinding()]
    param( )

    [Net.HttpListener] $list = $Script:Listener
    # 1] Stop ThreadJobs
    # 2] Stop, Close, and null HttpListener

    $threadJobs = Get-Job | ? Name -Match 'GitServe.*'
    if( $threadJobs.Count -gt 0 ) {
        $threadJobs.Name
            | Join-String -sep ', ' -SingleQuote -op 'GitServe Jobs already running: ' -os '. Stopping...'
            | Write-Warning
    }
    $threadJobs | Stop-Job -PassThru | Receive-Job -AutoRemoveJob -Wait

    if( $list.IsListening -or $null -ne $list ) {
        ( $list )?.Stop()
        ( $list )?.Close()
        $list = $null
    }
    $msg = 'http://{0}:{1}' -f ( $script:ModuleState.HostName, $script:ModuleState.Port )
    "$( (Get-Date).ToString('u')) GitServe: Stopped listening on: ${msg}"
        | Write-Host

}
