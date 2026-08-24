function Get-GitServeRepoList {
    <#
    .synopsis
        List git repos. Same as: irm /repo/list
    .DESCRIPTION
    .notes
    .example
        >
    #>
    [Alias('GitServe.Repo.List')]
    [OutputType( 'GitServe.Route.Repo.List' )]
    [CmdletBinding()]
    param(
        # Force refresh, clear repo listing cache
        [Alias('Force')]
        [switch] $WithoutCache
    )

    $searchRoot = @( GetConfig.ClonedRepoRoot )
    $findGitRepos = Get-ChildItem $searchRoot -Filter '.git' -Directory -Force -Recurse | ForEach-Object Parent
    $delim = "`u{2400}" # unique, but safe to print delimiter

    #region load cache
    $JsonCache = $script:ModuleState.JsonCacheRepoList
    $cache = $null
    [Collections.Generic.List[object]] $records = @()

    if( $WithoutCache ) {
        Remove-Item -LiteralPath $JsonCache
    }

    if( -not $WithoutCache ) {
        $JsonCache | Join-String -op 'Using Cache: ' | Write-Verbose
        $cache = Get-Content $JsonCache | ConvertFrom-Json
        # valid results?
        if( $cache.RepoList ) {
            write-warning 'ensure PSTYpeName'
            $records = $cache.RepoList
        }
    }
    #endregion load cache


    if( $WithoutCache -or $records.count -eq 0 ) {
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

    # save cache
    @{
        LastUpdate = [datetime]::Now
        RepoList = @( $records )
    }   | ConvertTo-Json
        | Set-Content -Encoding utf8 -Path $JsonCache


    return $records
}
