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
    param()

    [Net.HttpListener] $list = $Script:Listener
    # Close HttpListener first so route jobs unblock from GetContextAsync().
    if( $null -ne $List ) {
        if( $List.IsListening ) {
            "$( (Get-Date).ToString('u')) GitServe: Stopped listening" | Write-Host
            $List.Stop()
        }
        $List.Close()
        $Script:Listener = $null
    }

    Get-Job -State Completed | ? Name -match 'GitServe.*' | Remove-Job

    $threadJobs = @( Get-Job | Where-Object Name -Match 'GitServe.*' )
    if( $threadJobs.Count -gt 0 ) {
        $threadJobs.Name
            | Join-String -sep ', ' -SingleQuote -op 'GitServe Jobs: ' -os '. Stopping...'
            | Write-Warning

        $threadJobs | Stop-Job -ErrorAction Continue
        $threadJobs | Remove-Job -Force -ErrorAction Continue
    }
}
