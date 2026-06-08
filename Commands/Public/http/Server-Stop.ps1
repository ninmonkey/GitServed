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
    # $threadJobs | Stop-Job -PassThru | Receive-Job -AutoRemoveJob -Wait
    $threadJobs | Stop-Job -PassThru -Verbose #| Receive-Job -AutoRemoveJob -Wait

    'before StopJob step [1]' | Write-Verbose -verbose
    (get-job).count | Write-Host -fg 'gray40'
    Get-Job | ? Name -Match 'GitServe.*' | Remove-Job -Verbose

    'before StopJob step [2]' | Write-Verbose -verbose
    (get-job).count | Write-Host -fg 'gray40'
    Get-Job | ? Name -Match 'GitServe.*' | Stop-Job

    'before StopJob step [3]' | Write-Verbose -verbose
    (get-job).count | Write-Host -fg 'gray40'
    Get-Job | ? Name -Match 'GitServe.*' | Receive-Job -AutoRemoveJob -Wait

    (get-job).count | Write-Host -fg 'gray40'

    if( $List.IsListening ) {
        # test debug streams, do they both emit?
        "[w] $( (Get-Date).ToString('u')) GitServe: Stopped listening" | Write-Warning
        # "[v] $( (Get-Date).ToString('u')) GitServe: Stopped listening" | Write-Verbose -verbose
        # "[h] $( (Get-Date).ToString('u')) GitServe: Stopped listening" | Write-Host

        $List.Close()
        $list = $Null
    }
}
