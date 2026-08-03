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

    if ( [String]::IsNullOrWhitespace( $ClonedRepoRoot ) ) {
        $ClonedRepoRoot = GetConfig.ClonedRepoRoot | Get-Item -ea 'stop'
        'RootPath: {0}' -f ( $ClonedRepoRoot ) | Write-Verbose
    }

    #region Build Git Args
    $RepoPath = Join-Path $ClonedRepoRoot $OwnerRepoPair # todo(sanitization): use a better escape and match method
    if( ! ( Test-Path $RepoPath )) {
        "${endpointLabel} Error: Invalid OwnerRepoPair! '${OwnerRepoPair}'" | Write-Host -fore red
        throw "${endpointLabel} Error: Invalid OwnerRepoPair! '${OwnerRepoPair}'"
    }

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

    #endregion Build Git Args
    #region Invoke Git Args
    try {

        [object[]] $results = Invoke-GitServeRealGit @RealGit_splat
            | Sort-Object -Unique
            # | Select-Object -Property $SelectProperty
            # | GitServe.Metric.CommitCount -Period $Period
    }
    catch {
        "${endpointLabel} Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
        | Write-Host
        "${endpointLabel} Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
        | Write-Error
    }
    finally { }

    return [pscustomobject]@{
        PSTypeName = 'GitServe.Route.Repo.Author'
        Authors = , @( $results )

    }
    # return ,$results
    #endregion Invoke Git Args
}
