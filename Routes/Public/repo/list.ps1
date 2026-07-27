function /repo/list {
    <#
    .SYNOPSIS
        Return user's cloned repos. Cached.
    .description

    .NOTES
        Caches response to module variable 'Script:ResponseCache'
    #>
    [OutputType( 'GitServe.Route.Repo.List' )]
    param()
    $searchRoot = @( GetConfig.ClonedRepoRoot )
    $findGitRepos = Get-ChildItem $searchRoot -Filter '.git' -Directory -Force -Recurse | ForEach-Object Parent

    $delim = "`u{2400}" # unique, but safe to print delimiter

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
    return $records
}
