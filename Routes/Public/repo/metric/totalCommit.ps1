function /repo/metric/totalcommit {
    <#
    .SYNOPSIS
        Number of commits grouped and sorted by: "<CommitDate> Descending
    .DESCRIPTION
        You get one single aggregated record for each **date period**

    Query Parameters:
        name   - Short repo name like "BurntSushi/ripgrep"
        since  - "2.months"
        after  - '2024-01-01'
        before - '2024-01-01'
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/metric/commitcount?name=BurntSushi/ripgrep'
        irm 'http://127.0.0.1:3001/repo/metric/commitcount?name=BurntSushi/ripgrep&period=month'
        irm 'http://127.0.0.1:3001/repo/metric/commitcount?name=BurntSushi/ripgrep&period=day'
        irm 'http://127.0.0.1:3001/repo/metric/commitcount?name=BurntSushi/ripgrep&period=year'
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/metric/commitcount?name=BurntSushi/ripgrep&since=2.months'
        irm 'http://127.0.0.1:3001/repo/metric/commitcount?name=BurntSushi/ripgrep&after=2024-01-01'
        irm 'http://127.0.0.1:3001/repo/metric/commitcount?name=BurntSushi/ripgrep&before=2026-01-01'
    .example
        # multiple filters
        irm 'http://127.0.0.1:3001/repo/metric/commitcount?name=startautomating/ezout&after=2024-01-01&before=2024-09-04'
    .EXAMPLE
    .LINK
        GitServe\Metric-GitServeCommitCount
    #>
    [OutputType( 'GitServe.Route.Repo.Metric.Commit' )]
    [Alias('GitServe.Route.Metric.Commit')]
    [CmdletBinding()]
    param(
        # a request from the listen server
        [Parameter(Mandatory)]
        [Net.HttpListenerRequest] $Request
    )
    $endpointLabel = '/repo/metric/commit'
    [Collections.Specialized.NameValueCollection] $parsedQuery =
        [Web.HttpUtility]::ParseQueryString( $Request.Url.Query.ToLower() )

    [string] $OwnerRepoPair = $parsedQuery.Get('name')
    [string] $Period = $parsedQuery.Get('period') ?? 'year'

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

    #endregion Build Git Args
    #region Invoke Git Args
    try {

        [object[]] $results = Invoke-GitServeUGit @UGit_splat
            | Select-Object -Property $SelectProperty
            | GitServe.Metric.CommitCount -Period $Period
    }
    catch {
        "${endpointLabel} Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
        | Write-Host
        "${endpointLabel} Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
        | Write-Error
    }
    finally { }

    # todo(performance): redundant operations here

    # first determine date dimension keys. Insert into sorted hashtable in-order
    $results = $results | Sort-Object CommitDate
    $groupByPeriod =  $results | Group-Object -Prop { $_.CommitDate.ToString('yyyy-MM-dd') }
    [string[]] $datePeriodKeys = $groupByPeriod.Name

    $dateAccum = [ordered]@{}
    foreach( $name in $datePeriodKeys ) {
        @{
            CommitDate = $Null
            XAxisKey = $name
            CommitCount = 0
            RepoName = '<RepoName>'
        }
    }


    function _accumRecord {
        # merge existing and new values
        param(
            [string] $KeyName,
            [object] $Record
        )
    }

    foreach( $groupRecord in $groupByPeriod ) {
        $curKey = $groupRecord.Name
        $totalCommits = $groupRecord.Group | Measure-Object -Sum -Property 'CommitCount' | Select-Object -ExpandProperty Sum
        $firstDate = $groupRecord.Group
                | Measure-object CommitDate -Minimum
                | % Minimum


        $dateAccum[ $curKey ] = [pscustomobject]@{
            CommitDate = $FirstDate
            # XAxisKey = $curKey
            TotalCommits = $totalCommits ?? 0
            RepoName = '<RepoName>'
            OwnerRepoName = $OwnerRepoPair
            Authors = $groupRecord.Group.GitUserName | Sort-Object -Unique
        }
    }



    # $trash | Group -p { $_.CommitDate.Date } | sort  count


    # return ,$results
    return ,$dateAccum.Values
    #endregion Invoke Git Args
}
