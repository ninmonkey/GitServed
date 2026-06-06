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
        [String] $Host = '127.0.0.1',

        [Parameter()]
        [int] $Port
    )

    Stop-GitServe
    $state = $Script:ModuleState
    $script:Listener = [Net.HttpListener]::new()

    if( -not $Port ) { $Port = Get-Random -Minimum 3000 -Maximum 4000 }
    $state.HostName = $Host
    $state.Port = $Port
    [string[]] $prefix = 'http://{0}:{1}/' -f @(
        $state.HostName
        $state.Port
    )

    foreach( $curPrefix in $prefix ) {
        $Listener.Prefixes.Add( $curPrefix )
    }

    $Listener.Prefixes
        | Join-String -f '    add prefix {0}' | Write-Host -fg 'gray50'

    $Listener.Start()

    "$( (Get-Date).ToString('u')) GitServe: started listening on: http://$( $state.HostName ):$( $state.Port ))"
        | Write-Host
}
