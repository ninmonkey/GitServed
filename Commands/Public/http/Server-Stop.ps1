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
    # 1] Stop ThreadJobs - force stop without waiting for output
    # 2] Stop, Close, and null HttpListener
    $threadJobs = Get-Job | Where-Object Name -Match 'GitServe.*'
    if( $threadJobs.Count -gt 0 ) {
        $threadJobs.Name
            | Join-String -sep ', ' -SingleQuote -op 'GitServe Jobs: ' -os '. Stopping. Waiting for threads to stop...'
            | Write-Warning

        $threadJobs | Stop-Job -PassThru | Receive-Job -AutoRemoveJob -Wait

        # Force stop immediately - suppress errors from closing runspace state
        # $threadJobs | Stop-Job -Force -Confirm:$false -ErrorAction SilentlyContinue

        # # Brief delay for OS cleanup
        # Start-Sleep -Milliseconds 100

        # # Force remove any remaining jobs without accessing their output
        # Get-Job | Where-Object Name -Match 'GitServe.*' `
        #     | Remove-Job -Force -Confirm:$false -ErrorAction SilentlyContinue
    }

    # I thought I'd want to exit jobs then close the listener? testing the inverse.
    if( $List.IsListening ) {
        "[w] $( (Get-Date).ToString('u')) GitServe: Stopped listening" | Write-Warning
        $List.Close()
        $list = $Null
    }

}
