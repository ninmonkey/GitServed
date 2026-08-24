function SetConfig.ClonedRepoRoot {
    <#
    .synopsis
        Set app configuration for root directories to search ( ie: local, vs docker, etc )
    .EXAMPLE
        # using one or more custom paths
        GitServe.Set-ConfigRepoRoot -Path 'C:\MyRepos', 'C:\MoreRepos'
        GitServe.Repo.List | Ft # shows updated repos
    .DESCRIPTION
        Set root directories for cloned repos.
    #>
    [Alias('GitServe.Set-ConfigRepoRoot')]
    [CmdletBinding()]
    param(
        # A list of root directories to search for git repos
        [Alias('RootDirectory')]
        [object[]] $Path
    )

    $script:ModuleState.ClonedRepoRoot = @( $Path )

    # Clear cached repos since the path[s] have changed
    Clear-ResponseCacheKey -Key '/repo/list' -Verbose:$false

    # clear JsonCache for for GitServe.Repo.List
    Remove-Item -ea ignore -LiteralPath $script:ModuleState.JsonCacheRepoList
}
