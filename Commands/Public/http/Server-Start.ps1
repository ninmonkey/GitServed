function Start-GitServe {  # 'Start-GitServeServer' sounded bad
    <#
    .synopsis
        Start listen server
    .notes
        aliased as Start-GitServe, GitServe.Start
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
        [String] $Host,

        [Parameter()]
        [int] $Port
    )

    if( -not $Port ) {
        $Port = Get-Random -Minimum 3000 -Maximum 4000
    }

    $script:ModuleState.HostName = $Host
    $script:ModuleState.Port = $Port
    "GitServe: started listening on: ${Host}:${Port} at $( (Get-Date).ToString('u'))"
        | Write-Host
}
