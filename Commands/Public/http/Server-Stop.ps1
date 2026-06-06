function Stop-GitServe {  # 'Stop-GitServeServer' sounded bad
    <#
    .synopsis
        Stop listen server. Dispose of HttpListener and ThreadJobs
    .example
        > GitServe Stop
    .LINK
        Start-GitServe
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

    # or if( $list.IsListening -or $null -ne $list ) {
    if( $null -ne $list ) {
        ( $list )?.Stop()
        ( $list )?.Close()
        $list = $null
        $script:Listener = $null
    }
    "$( (Get-Date).ToString('u')) GitServe: Stopped listening"
        | Write-Host

}
