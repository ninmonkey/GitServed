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

    if( -not $Port ) {
        $Port = Get-Random -Minimum 3000 -Maximum 4000
    }
    $msg = '{0}:{1}' -f ( $script:ModuleState.HostName, $script:ModuleState.Port )
    "GitServe: Stopped listening on: ${msg} at $( (Get-Date).ToString('u'))"
        | Write-Host
}
