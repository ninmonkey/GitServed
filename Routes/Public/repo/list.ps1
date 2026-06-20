function /repo/list {
    <#
    .SYNOPSIS
        Return user's cloned repos
    .description
    .NOTES
        Response is not explicitly cached
    #>
    [OutputType( 'GitServe.Route.Repo.List' )]
    param()

    $searchRoot = @( GetConfig.ClonedRepoRoot )
    $findGitRepos = Get-ChildItem $searchRoot -Filter '.git' -Directory -Force -Recurse | ForEach-Object Parent

    $records = @(
        foreach ($repoPath in $findGitRepos) {
            $absolutePath = $repoPath.FullName
            $remote = ( & git -C $absolutePath remote get-url origin 2>$null ) ?? '<empty-remote>'
            $commitCount = ( & git -C $absolutePath rev-list --count HEAD )
            $newestCommitRelative = ( & git -C $absolutePath log -1 --format=%cr )
            $newestCommitDateOnly = ( & git -C $absolutePath log -n 1 --format=%cd --date=format:'%Y-%m-%d' )
            $ownerPathName = $repoPath.FullName | Split-path -Parent | split-path  -Leaf

            [pscustomobject]@{
                PSTypeName = 'GitServe.Route.Repo.List'
                Name                 = $repoPath.BaseName
                Path                 = $repoPath.FullName
                Owner                = $ownerPathName
                NewestCommitDate     = $newestCommitDateOnly
                NewestCommitRelative = $newestCommitRelative
                CommitCount          = $commitCount
                Remote               = $remote
                # '( git remote get-url origin 2>$null | out-null ) ?? '<missing>''
            }
        }
    )
    return $records
}
