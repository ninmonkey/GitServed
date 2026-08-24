function Get-GitServeRepoList {
    <#
    .synopsis
        List git repos. Same as: irm /repo/list
    .DESCRIPTION
    .notes
    .example
        GitServe.Repo.List
    .example
        # force updating the repo listing
        GitServe.Repo.List -WithoutCache
    #>
    [Alias('GitServe.Repo.List')]
    [OutputType( 'GitServe.Route.Repo.List' )]
    [CmdletBinding()]
    param(
        # Force refresh, clear repo listing cache. Saves result to cache file.
        [Alias('Force')]
        [switch] $WithoutCache
    )

    $searchRoot = @( GetConfig.ClonedRepoRoot )
    $findGitRepos = Get-ChildItem $searchRoot -Filter '.git' -Directory -Force -Recurse | ForEach-Object Parent
    $delim = "`u{2400}" # unique, but safe to print delimiter

    $outputTypeName = 'GitServe.Route.Repo.List'

    #region load cache
    $JsonCachePath = $script:ModuleState.JsonCacheRepoList
    $cache = $null
    [Collections.Generic.List[object]] $records = @()

    if( $WithoutCache ) {
        '$WithoutCache, deleting: ' | Write-Verbose
        Remove-Item -LiteralPath $JsonCachePath
    }

    if( -not $WithoutCache ) {
        $JsonCachePath | Join-String -op 'Using Cache: ' | Write-Verbose
        $cache = Get-Content $JsonCachePath -ea ignore | ConvertFrom-Json
        $cache.RepoList.Count | Join-String -op '$cache.RepoList.Count: ' | Write-Verbose
        # if valid results, emit correct type names
        if( $cache.RepoList ) {
            $records = $cache.RepoList | %{
                $_.PSObject.TypeNames.Insert(0, $outputTypeName )
                $_
            }
        }
    }
    #endregion load cache

    $records.count | Join-String -op 'records loaded records from cache? ' | Write-Verbose

    if( $WithoutCache -or ( $records.count -eq 0 ) ) {
        #region calculate new return value
        # cache was either invalid or was disabled
        'Calculating fresh repo list' | Write-Verbose

        $records = @(
            foreach ($repoPath in $findGitRepos) {
                # get remote, or fallback string
                $remote = ( ( GitServe.Invoke-RealGit -FromPath $repoPath.FullName -GitArgList 'remote', 'get-url', 'origin'  ) 2>$Null ) ?? '<empty-remote>'

                # Grab latest commit date and relative using a single git call. Then split by delim.

                $delim = "`u{2400}"
                $fStr = "--format=%cr${delim}%cd"
                $out = GitServe.Invoke-RealGit -FromPath $repoPath.FullName -GitArgList @(
                    'log', '-n', '1',
                    $fStr, '--date=format:%Y-%m-%d'
                )
                $newestCommitRelative, $newestCommitDateOnly = $out -split $delim, 2
                $ownerPathName = $repoPath.FullName | Split-path -Parent | split-path  -Leaf

                [pscustomobject][ordered]@{
                    PSTypeName           = 'GitServe.Route.Repo.List'
                    # CommitCount          = $commitCount  # disabled(slow): commit count
                    Name                 = $repoPath.BaseName
                    NewestCommitDate     = $newestCommitDateOnly
                    NewestCommitRelative = $newestCommitRelative
                    Owner                = $ownerPathName
                    OwnerRepoPair            = '{0}/{1}' -f @( $ownerPathName, $repoPath.BaseName )
                    Path                 = $repoPath.FullName
                    Remote               = $remote
                    # '( git remote get-url origin 2>$null | out-null ) ?? '<missing>''
                }
            }
        )
        #endregion calculate new return value
    }

    $records.count | Join-String -op 'final $records.count: ' | Write-Verbose

    # save cache if any records are found
    if( $records.count -gt 0  ) {
        $JsonCachePath | Join-String -op 'Writing: ' | Write-Verbose
        @{
            LastUpdate = [datetime]::Now
            RepoList = @( $records )
        }   | ConvertTo-Json
            | Set-Content -Encoding utf8 -Path $JsonCachePath
    }

    # Always remove file if records are empty
    if( $records.count -eq 0 ) {
        $JsonCachePath | Join-String -op 'Records count == 0, deleting: ' | Write-Verbose
        Remove-Item -LiteralPath $JsonCachePath
    }


    return $records
}
