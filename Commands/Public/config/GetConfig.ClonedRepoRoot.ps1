function GetConfig.ClonedRepoRoot {
    <#
    .synopsis
        Get app configuration for root directories to search ( ie: local, vs docker, etc )
    .DESCRIPTION
        Get root directories for cloned repos.
    #>
    [Alias('GitServe.Get-ConfigRepoRoot')]
    [OutputType( [System.IO.DirectoryInfo[]] )]
    [CmdletBinding()]
    param(
        # Always return the first match. Default is to return all
        [Alias('LimitOne')]
        [switch] $FirstOnly
    )

    $rootPaths = @(
        $script:ModuleState.ClonedRepoRoot
        | Where-Object { Test-Path $_ } | Get-Item -ea ignore
    )

    if( $First ) {
        return $rootPaths | Select-Object -First 1
    }
    return $rootPaths
}
