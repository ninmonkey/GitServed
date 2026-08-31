function /repo/fastlog {
    <#
    .SYNOPSIS
        (using simplified, faster log ) Return git logs based on repo OwnerRepoPair '/<owner>/<repo>'
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
        irm 'http://127.0.0.1:3001/repo/fastlog?name=BurntSushi/ripgrep'
        irm 'http://127.0.0.1:3001/repo/fastlog?name=BurntSushi/ripgrep&limit=4'
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/fastlog?name=BurntSushi/ripgrep&before=2025-01-01&limit=2'
        irm 'http://127.0.0.1:3001/repo/fastlog?name=BurntSushi/ripgrep&since=2.weeks&limit=4'
        irm 'http://127.0.0.1:3001/repo/fastlog?name=BurntSushi/ripgrep&before=2.month&limit=3'
        irm 'http://127.0.0.1:3001/repo/fastlog?name=BurntSushi/ripgrep&since=2.month&limit=3'
    .LINK
        /repo/log
    .LINK
        /repo/fastlog
    #>

    [OutputType( 'GitServe.Route.Repo.FastLog' )]
    [Alias('GitServe.Route.Get-FastLog')]
    [CmdletBinding()]
    param(
        # a request from the listen server
        [Parameter(Mandatory)]
        [object] $Request
    )
    $endpointLabel = '/repo/fastlog'
    [Collections.Specialized.NameValueCollection] $parsedQuery = ParseQueryString $Request

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


    [Collections.Generic.List[object]] $gitArgs = @(
        'log'
        if ( $MaxLogs ) {
            '-n'
            $MaxLogs
        }
    )

    # $SelectProperty = 'CommitDate', 'GitUserName', 'Date', 'Scope', 'CommitType', 'Merged', 'CommitHash', 'Trailer', 'Trailers'
    $git_splat = @{
        FromPath = $RepoPath
        # GitArgList = @(
        #     # $gitArgs
        #     # 'log'
        #  )
    }
    if( $parsedQuery.Get('since') ) {
        $git_splat['since'] = $parsedQuery.Get('since')
    }
    if( $parsedQuery.Get('before') ) {
        $git_splat['before'] = $parsedQuery.Get('before')
    }
    if( $parsedQuery.Get('after') ) {
        $git_splat['after'] = $parsedQuery.Get('after')
    }
    #endregion Build Git Args

    #region Invoke Git
    try {

        $results = FastGitLog @git_splat
        # $results = Invoke-GitServeRealGit @git_splat
            # | Select-Object -Property $SelectProperty
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
