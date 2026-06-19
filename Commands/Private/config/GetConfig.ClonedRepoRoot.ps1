function GetConfig.ClonedRepoRoot {
    <#
    .synopsis
        (internal) Get app configuration for root directories to search ( ie: local, vs docker, etc )
    .DESCRIPTION
        Get root directories for cloned repos.
    #>
    [OutputType( [System.IO.DirectoryInfo[]] )]
    [CmdletBinding()]
    param()

    $potential = @( 'H:/RootClonedRepos', '/cloned-repos' )

    $rootPaths = @(
        $potential
        | Where-Object { Test-Path $_ } | Get-Item -ea ignore
    )

    return $rootPaths
}
