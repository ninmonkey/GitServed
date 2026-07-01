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

    $delim = "`u{2400}" # unique, but safe to print delimiter

    $records = @(
        foreach ($repoPath in $findGitRepos) {
            $absolutePath = $repoPath.FullName
            $remote = ( & $binGit -C $absolutePath remote get-url origin 2>$null ) ?? '<empty-remote>'
            # $commitCount = ( & $binGit -C $absolutePath rev-list --count HEAD ) # disabled(slow): commit count

            # Grab latest commit date and relative using a single git call. Then split by delim.
            $out           = (  & $binGit -C $absolutePath log -n 1 "--format=%cr`u{2400}%cd" '--date=format:%Y-%m-%d' )
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
