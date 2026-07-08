function SetConfig.ClonedRepoRoot {
    <#
    .synopsis
        Set app configuration for root directories to search ( ie: local, vs docker, etc )
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
}
