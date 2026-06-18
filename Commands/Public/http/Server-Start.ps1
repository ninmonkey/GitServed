function Start-GitServe {
    <#
    .synopsis
        Start listen server
    .DESCRIPTION
        Main entry point for the user
    .notes
        - calls Stop-GitServe if listener is active
        - aliased as Start-GitServe, GitServe.Start
    .example
        # default uses random ports on localhost:
        > Start-GitServe
        # or as an alias:
        # GitServe.Start
    .example
        > GitServe.Start -Host $ip -Port $port
    .LINK
        Start-GitServe
    .LINK
        Stop-GitServe
    .LINK
        GitServe
    #>
    [Alias('GitServe.Start')]
    [CmdletBinding()]
    param(
        [ArgumentCompletions(
            "'127.0.0.1'", "'*'", "'localhost'" # "'0.0.0.0'", "'*'", "'localhost'"
        )]
        [Alias('Ip')]
        [Parameter(Position = 0)]
        [String] $HostName = '127.0.0.1',

        [Parameter()]
        [int] $Port
    )
    if( $Script:Listener.IsListening ) {
        Stop-GitServe
    }
    $state = $Script:ModuleState
    if( $null -eq $Script:Listener ) {
        $Script:Listener = [Net.HttpListener]::new()
    }
    [Net.HttpListener] $curListener = $Script:Listener ?? [Net.HttpListener]::new()


    if( -not $Port ) { $Port = Get-Random -Minimum 3000 -Maximum 4000 }
    $state.HostName = $HostName
    $state.Port = $Port
    $prefix = 'http://{0}:{1}/' -f @(
        $state.HostName
        $state.Port
    )
    $prefix | join-string -op 'Prefix: ' | Write-host -bg 'orange'
    if( $null -eq $curListener ) {
        throw "Listener was null!"
    }
    $curListener.Prefixes.Add( $prefix )

    # foreach( $curPrefix in $prefix ) {
    # }
    $curListener.Prefixes
        | Join-String -f '    add prefix {0}' | Write-Host -fg 'gray50'

    try {
        $curListener.Start()
    } catch [Net.HttpListenerException] {
        # if $_ -match 'failed to listen on prefix.*existing registration'
        'Error, is port in use?' | Write-Error -ErrorId 'Start-GitServe.PortInUse' -Category ResourceExists
        $Script:Listener = $null
        return
    }

    "$( (Get-Date).ToString('u')) GitServe: started listening on: http://$( $state.HostName ):$( $state.Port ))"
        | Write-Host

    "Start-GitServe: <ctrl+c> to stop server" | Write-Host -fg darkblue

    $startRouteThreadOldSplat = @{
        Runspace      = [runspace]::DefaultRunspace
        Listener      = $curListener
        ThrottleLimit = 50
    }

    Start-RouteThreadOld @startRouteThreadOldSplat

    $startListenLoopSplat = @{
        Listener = $Script:Listener
    }

    "before => startListenLoop" | Write-Host -fg 'yellow'
    Start-ListenLoop @startListenLoopSplat
    "after  => startListenLoop" | Write-Host -fg 'yellow'
}
