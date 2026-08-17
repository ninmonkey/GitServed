function /repo/md/readme {
    <#
    .SYNOPSIS
        Get main readme file for a project
    .DESCRIPTION
    Query Parameters:
        name   - Short repo name like "BurntSushi/ripgrep"
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/md/readme?name=BurntSushi/ripgrep'
    .LINK
    #>
    [OutputType( 'GitServe.Route.Repo.Md.File' )]
    [Alias('GitServe.Route.Metric.Md.Readme')]
    [CmdletBinding()]
    param(
        # a request from the listen server
        [Parameter(Mandatory)]
        [object] $Request

    )
    $endpointLabel = '/repo/md/readme'
    [Collections.Specialized.NameValueCollection] $parsedQuery = ParseQueryString $Request
    [string] $OwnerRepoPair = $parsedQuery.Get('name')
    $RepoPath = Path.ConvertFrom-ShortRepoName -Name $OwnerRepoPair -Throw

    $found = Get-ChildItem -LiteralPath $RepoPath -Recurse -Filter readme.md -File
    $first = $found | Select-Object -First 1

    "  ${endpointLabel} Found $( $found.count ) 'readme.md'" | Write-Verbose -Verbose

    if ( $found.count -gt 1 ) {
        "  ${endpointLabel} Found $( $found.count ) 'readme.md'" | Write-Host
    }
    return [pscustomobject][ordered]@{
        PSTypeName = 'GitServe.Route.Repo.Md.File'
        Name       = $first.Name
        FullName   = $first.FullName.ToString()     # to prevent cache or json returning bytes
    }

}
