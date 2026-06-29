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
    $binGit = Get-Command -CommandType Application -Name 'git' -ea 'Stop' -TotalCount 1

    $searchRoot = @( GetConfig.ClonedRepoRoot )
    $findGitRepos = Get-ChildItem $searchRoot -Filter '.git' -Directory -Force -Recurse | ForEach-Object Parent

    $records = @(
        foreach ($repoPath in $findGitRepos) {
            $absolutePath = $repoPath.FullName
            $remote = ( & $binGit -C $absolutePath remote get-url origin 2>$null ) ?? '<empty-remote>'
            $commitCount = ( & $binGit -C $absolutePath rev-list --count HEAD )
            $newestCommitRelative = ( & $binGit -C $absolutePath log -1 --format=%cr )
            $newestCommitDateOnly = ( & $binGit -C $absolutePath log -n 1 --format=%cd --date=format:'%Y-%m-%d' )
            $ownerPathName = $repoPath.FullName | Split-path -Parent | split-path  -Leaf

            [pscustomobject][ordered]@{
                PSTypeName           = 'GitServe.Route.Repo.List'
                CommitCount          = $commitCount
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
