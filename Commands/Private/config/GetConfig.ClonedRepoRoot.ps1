function GetConfig.ClonedRepoRoot {
    <#
    .synopsis
        (internal) Get app configuration for root directories to search ( ie: local, vs docker, etc )
    .DESCRIPTION
        Get root directories for cloned repos.
    #>
    [OutputType( [System.IO.DirectoryInfo[]] )]
    [CmdletBinding()]
    param(
        # Always return the first match. Default is to return all
        [Alias('LimitOne')]
        [switch] $FirstOnly
    )

    $potential = @( 'H:/RootClonedRepos', '/cloned-repos' )

    $rootPaths = @(
        $potential
        | Where-Object { Test-Path $_ } | Get-Item -ea ignore
    )

    if( $First ) {
        return $rootPaths | Select-Object -First 1
    }
    return $rootPaths
}
