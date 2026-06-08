function Start-GitServe {  # 'Start-GitServeServer' sounded bad
    <#
    .synopsis
        Start listen server
    .DESCRIPTION
    .notes
        - calls Stop-GitServe if listener is active
        - aliased as Start-GitServe, GitServe.Start
    .example
        # random ports
        > GitServe Start

    .example
        > GitServe Start -Host ip -Port port
    Maybe allow:
        > GitServe Start ip:port
        > GitServe Start port
    .LINK
        Start-GitServe
    .LINK
        Stop-GitServe
    .LINK
        GitServe
    #>
    [Alias('GitServe.Start')]
    # [OutputType( [string] )]
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

    "Next: Start-RouteThread; Start-ListenLoop" | Write-Host -fg salmon

    $startRouteThreadSplat = @{
        Runspace      = [runspace]::DefaultRunspace
        Listener      = $curListener
        ThrottleLimit = 50
    }

    Start-RouteThread @startRouteThreadSplat

    $startListenLoopSplat = @{
        Listener = $Script:Listener
    }

    "before => startListenLoop" | Write-Host -fg 'yellow'
    Start-ListenLoop @startListenLoopSplat
    "after  => startListenLoop" | Write-Host -fg 'yellow'

    #   [Parameter()] [Runspace] $RunSpace = ([Runspace]::DefaultRunspace), # can param binding to default cause threadsafe issues, ie: is evaluated once, or before other lifetimes?
    #     [Net.HttpListener] $Listener = $Null,
    #     # [hashtable] $Query = [ordered]@{}, Request.Url ParsedQuery String
    #     # [hashtable] $JobParams = [ordered]@{},
        # [int] $ThrottleLimit = 50
}
