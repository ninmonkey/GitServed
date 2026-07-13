function /repo/metric/language {
    <#
    .SYNOPSIS
        Get count of file extensions in HEAD
    .DESCRIPTION
    Query Parameters:
        name   - Short repo name like "BurntSushi/ripgrep"
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/metric/language?name=BurntSushi/ripgrep'
    .EXAMPLE
    .LINK
        GitServe\Metric-GitServeLanguageCount
    #>
    [OutputType( 'GitServe.Route.Repo.Metric.Commit' )]
    [Alias('GitServe.Route.Metric.Language')]
    [CmdletBinding()]
    param(
        # a request from the listen server
        [Parameter(Mandatory)]
        [Net.HttpListenerRequest] $Request
    )
    $endpointLabel = '/repo/metric/language'
    [Collections.Specialized.NameValueCollection] $parsedQuery =
        [Web.HttpUtility]::ParseQueryString( $Request.Url.Query.ToLower() )

    [string] $OwnerRepoPair = $parsedQuery.Get('name')

    if ( [String]::IsNullOrWhitespace( $ClonedRepoRoot ) ) {
        $ClonedRepoRoot = GetConfig.ClonedRepoRoot | Get-Item -ea 'stop'
        'RootPath: {0}' -f ( $ClonedRepoRoot ) | Write-Verbose
    }
    $RepoPath = Join-Path $ClonedRepoRoot $OwnerRepoPair # todo(sanitization): use a better escape and match method
    if( ! ( Test-Path $RepoPath )) {
        "${endpointLabel} Error: Invalid OwnerRepoPair! '${OwnerRepoPair}'" | Write-Host -fore red
        throw "${endpointLabel} Error: Invalid OwnerRepoPair! '${OwnerRepoPair}'"
    }

    #region Invoke Git Args
    $results = Metric-GitServeLanguageCount -GitRepositoryPath $RepoPath
    return ,$results
    #endregion Invoke Git Args
}
