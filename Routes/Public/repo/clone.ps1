function /repo/clone {
    <#
    .SYNOPSIS
        Clone a repository to the docker volume
    .Description
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/Clone?url=https://github.com/BurntSushi/ripgrep.git'
    .NOTES
        Response is not explicitly cached
    #>
    [OutputType( 'GitServe.Route.Repo.Clone' )]
    param(
        [Net.HttpListenerRequest] $Request
    )

    $Request | ConvertTo-Json -depth 1 -wa ignore | Write-Debug

    $parsedQuery = [Web.HttpUtility]::ParseQueryString( $Request.Url.Query.ToLower() )
    [string] $gitUrl = @( $parsedQuery.GetValues('url') )[0]

    InvokeCli.Git.CloneRepo -Url $gitUrl -path (GetConfig.ClonedRepoRoot -First)
        | Write-Debug

    Clear-ResponseCacheKey -Key '/repo/list' -Verbose:$false

    [pscustomobject]@{
        PSTypeName         = 'GitServe.Route.Repo.Clone'
        Query              = $request.Url.PathAndQuery
        CloneUrl           = $gitUrl
        # DebugRequest       = $Request
    }

}
