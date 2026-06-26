function /repo/metric/commit {
    <#
    .SYNOPSIS
        Number of commits grouped and sorted by: "<Year>-<Month>_<GitUserName>" as text Descending
    .DESCRIPTION
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/metric/commit?repo=BurntSushi/ripgrep'
        irm 'http://127.0.0.1:3001/repo/metric/commit?url=microsoft/vscode-tmdl'
    .EXAMPLE
    .LINK
        GitServe\Metric-GitServeCommitCount
    #>
    [OutputType( 'GitServe.Route.Repo.Metric.Commit' )]
    [Alias('GitServe.Get-Log')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Net.HttpListenerRequest] $Request
    )
    $endpointLabel = '/repo/metric/commit'
    $parsedQuery = [Web.HttpUtility]::ParseQueryString( $Request.Url.Query.ToLower() )
    [string] $OwnerRepoPair = @( $parsedQuery.GetValues('url') )

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
    # $binGit = Get-Command -CommandType Application -Name 'git' -ea 'Stop' -TotalCount 1
    [Collections.Generic.List[object]] $gitArgs = @(
        'log'
        # '-n'
        # '100'
        '-C'
        $RepoPath
        # $OwnerRoot # if not using provider, declare path
    )

    $gitArgs
        | Join-String -sep ' ' -op 'Clone: invoke ''git'' => '
        | Write-Verbose

    try {
        $SelectProperty = 'CommitDate', 'GitUserName', 'Date', 'Scope', 'CommitType', 'Merged', 'CommitHash', 'Trailer', 'Trailers'
        # [object[]]
        $results = Use-git -GitArg $gitArgs
            | GitServe.Metric.CommitCount
            # | Select-Object -Property $SelectProperty
    } catch {
        "${endpointLabel} Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
            | Write-Host
        "${endpointLabel} Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
            | Write-Error
    }
    finally { }

    return $results
    #endregion Invoke Git Args
}
