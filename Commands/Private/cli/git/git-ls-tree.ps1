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
        [Alias('Path', 'PSPath', 'GitRepo', 'RepoRoot', 'FromPath')]
        [string] $GitRepositoryPath,

        # default uses 'ls-tree --full-tree'
        [switch] $WithoutIncludeFullTree
    )
    #region Invoke RealGit
    $gitArgs
        | Join-String -sep ' ' -op 'invoke ''git'' => '
        | Write-Verbose

    $realGit_splat = @{
        FromPath = Get-Item -ea 'stop' $GitRepositoryPath
        GitArgList = @(
            'ls-tree'
            '-r'
            'HEAD'
            if( $WithoutIncludeFullTree ) { '--full-tree' }
            '--name-only'
        )
    }

    $results = GitServe.Invoke-RealGit @realGit_splat
    $results
    #endregion Invoke RealGit
}
