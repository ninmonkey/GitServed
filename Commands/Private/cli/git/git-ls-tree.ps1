function InvokeCli.Git.LsTree.Files {
    <#
    .SYNOPSIS
        (internal) Invoke native git ls-tree to list files
    .EXAMPLE
        InvokeCli.Git.LsTree.Files -Repo 'https://github.com/owner/repo.git'
    #>
    # [Alias('InvokeCli.Git.LsTree.Files')]
    [CmdletBinding()]
    param(
        # root directory to clone under. '/cloned-repos' would clone to '/cloned-repos/owner/repository'
        [Parameter(Mandatory)]
        [Alias('Path', 'PSPath', 'GitRepo', 'RepoRoot')]
        [string] $GitRepositoryPath,

        # default uses 'ls-tree --full-tree'
        [switch] $WithoutIncludeFullTree
    )

    # Run real git with args:
    #region Invoke Real Git Args
    $binGit = Get-Command -CommandType Application -Name 'git' -ea 'Stop' -TotalCount 1
    [Collections.Generic.List[object]] $gitArgs = @(
        '-C'
        (Get-Item -ea 'stop' $GitRepositoryPath)
        'ls-tree'
        '-r'
        'HEAD'
        if( $WithoutIncludeFullTree ) { '--full-tree' }
        '--name-only'
    )

    $gitArgs
        | Join-String -sep ' ' -op 'invoke ''git'' => '
        | Write-Verbose

    $results = & $binGit @gitArgs

    $results
    #endregion Invoke Real Git Args
}
