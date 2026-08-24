function /repo/author {
    <#
    .SYNOPSIS
        Return distinct list of authors in a time period
    .DESCRIPTION
    Query Parameters:
        name   - Short repo name like "BurntSushi/ripgrep"
        since  - "2.months"
        after  - '2024-01-01'
        before - '2024-01-01'
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/author?name=BurntSushi/ripgrep&period=2.months'
    #>
    [OutputType( 'GitServe.Route.Repo.Author' )]
    [Alias('GitServe.Route.Author')]
    [CmdletBinding()]
    param(
        # a request from the listen server
        [Parameter(Mandatory)]
        [object] $Request

    )
    $endpointLabel = '/repo/author'
    [Collections.Specialized.NameValueCollection] $parsedQuery = ParseQueryString $Request

    [string] $OwnerRepoPair = $parsedQuery.Get('name')
    [bool] $Using_ByEmail   = $parsedQuery.Get('ByEmail') ??  $false
    [string] $Period        = $parsedQuery.Get('period') ?? 'year'

    #region Build Git Args
    $RepoPath = GitServe.Path.FromShortRepoName -ShortRepoName $OwnerRepoPair -Throw

    [Collections.Generic.List[object]] $gitArgs = @(
        'log'
        if( $Using_ByEmail ) {
            '--format="%ae"' # if email
        } else {
            '--format="%an"'
        }
    )

    $RealGit_splat = @{
        FromPath = $RepoPath
        GitArgList = $gitArgs
    }
    if( $parsedQuery.Get('since') ) {
        $RealGit_splat['since'] = $parsedQuery.Get('since')
    }
    if( $parsedQuery.Get('before') ) {
        $RealGit_splat['before'] = $parsedQuery.Get('before')
    }
    if( $parsedQuery.Get('after') ) {
        $RealGit_splat['after'] = $parsedQuery.Get('after')
    }
    write-warning 'WIP: requires Metric-GitServeCommitCount'

    #endregion Build Git Args
    #region Invoke Git Args
    try {
        $ErrorActionPreference = 'stop' # wip: fix this route
        # $SelectProperty =

        [object[]] $results = Invoke-GitServeRealGit @RealGit_splat
            | Sort-Object -Unique
            # | Select-Object -Property $SelectProperty
            | GitServe.Metric.CommitCount -Period $Period
    }
    catch {
        "${endpointLabel} Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
        | Write-Host
        "${endpointLabel} Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
        | Write-Error
    }
    finally {
        $ErrorActionPreference = 'continue'
    }

    return [pscustomobject]@{
        PSTypeName = 'GitServe.Route.Repo.Author'
        Authors = , @( $results )

    }
    # return ,$results
    #endregion Invoke Git Args
}
