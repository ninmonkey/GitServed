function /repo/log {
    <#
    .SYNOPSIS
        Return git logs based on repo OwnerRepoPair '/<owner>/<repo>'
    .DESCRIPTION
    Query Parameters:
        name   - Short repo name like "BurntSushi/ripgrep"
        since  - "2.months"
        after  - '2024-01-01'
        before - '2024-01-01'

        name: [string]
            The short 'OwnerRepoPair' for a cloned repo. Like:
            BurntSushi/ripgrep

        limit: [int]
            Return at most this many records.
            ( The git logs limit parameter )
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/log?name=BurntSushi/ripgrep'
        irm 'http://127.0.0.1:3001/repo/log?name=BurntSushi/ripgrep&limit=4'
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/log?name=BurntSushi/ripgrep&before=2025-01-01&limit=2'
        irm 'http://127.0.0.1:3001/repo/log?name=BurntSushi/ripgrep&since=2.weeks&limit=4'
        irm 'http://127.0.0.1:3001/repo/log?name=BurntSushi/ripgrep&before=2.month&limit=3'
        irm 'http://127.0.0.1:3001/repo/log?name=BurntSushi/ripgrep&since=2.month&limit=3'
    #>

    [OutputType( 'GitServe.Route.Repo.Log' )]
    [Alias('GitServe.Route.Get-Log')]
    [CmdletBinding()]
    param(
        # a request from the listen server
        [Parameter(Mandatory)]
        [Net.HttpListenerRequest] $Request
    )
    $endpointLabel = '/repo/log'
    [Collections.Specialized.NameValueCollection] $parsedQuery =
        [Web.HttpUtility]::ParseQueryString( $Request.Url.Query.ToLower() )

    #region Build Git Args
    [string] $OwnerRepoPair = $parsedQuery.Get('name')
    [int] $MaxLogs = $parsedQuery.Get('limit')

    if ( [String]::IsNullOrWhitespace( $ClonedRepoRoot ) ) {
        $ClonedRepoRoot = GetConfig.ClonedRepoRoot | Get-Item -ea 'stop'
        'RootPath: {0}' -f ( $ClonedRepoRoot ) | Write-Verbose
    }
    $RepoPath = Join-Path $ClonedRepoRoot $OwnerRepoPair # todo(sanitization): use a better escape and match method
    if ( ! ( Test-Path $RepoPath )) {
        "${endpointLabel} Error: Invalid OwnerRepoPair! '${OwnerRepoPair}'" | Write-Host -fore red
        throw "${endpointLabel} Error: Invalid OwnerRepoPair! '${OwnerRepoPair}'"
    }
    # build git limiting args, which are common across ugit and git
    #endregion Build Git Args

    [Collections.Generic.List[object]] $gitArgs = @(
        'log'
        if ( $MaxLogs ) {
            '-n'
            $MaxLogs
        }
    )

    $SelectProperty = 'CommitDate', 'GitUserName', 'Date', 'Scope', 'CommitType', 'Merged', 'CommitHash', 'Trailer', 'Trailers'
    $UGit_splat = @{
        FromPath = $RepoPath
        GitArgList = $gitArgs
    }
    if( $parsedQuery.Get('since') ) {
        $UGit_splat['since'] = $parsedQuery.Get('since')
    }
    if( $parsedQuery.Get('before') ) {
        $UGit_splat['before'] = $parsedQuery.Get('before')
    }
    if( $parsedQuery.Get('after') ) {
        $UGit_splat['after'] = $parsedQuery.Get('after')
    }

    #region Invoke Git
    try {

        $results = Invoke-GitServeUGit @UGit_splat
            | Select-Object -Property $SelectProperty
    }
    catch {
        "${endpointLabel} Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
        | Write-Host
        "${endpointLabel} Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
        | Write-Error
    }
    return $results
    #endregion Invoke Git
}
