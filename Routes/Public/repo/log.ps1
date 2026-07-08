function /repo/log {
    <#
    .SYNOPSIS
        Return git logs based on repo OwnerRepoPair '/<owner>/<repo>'
    .DESCRIPTION
    Query Parameters:
        name: [string]
            The short 'OwnerRepoPair' for a cloned repo. Like:
            BurntSushi/ripgrep

        limit: [int]
            Return at most this many records.
            ( The git logs limit parameter )

    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/log?name=BurntSushi/ripgrep'
        irm 'http://127.0.0.1:3001/repo/log?name=BurntSushi/ripgrep&limit=4'
    .EXAMPLE

    .EXAMPLE
    .LINK
        GitServe\Invoke-GitClone
    .LINK
        GitServe\GitServe.Clone
    #>

    [OutputType( 'GitServe.Route.Repo.Log' )]
    [Alias('GitServe.Get-Log')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Net.HttpListenerRequest] $Request

        # [Alias('Name', 'RepoName')]
        # [Parameter(Mandatory)]
        # [string] $OwnerRepoPair
    )
    $parsedQuery = [Web.HttpUtility]::ParseQueryString( $Request.Url.Query.ToLower() )
    [string] $OwnerRepoPair = $parsedQuery.Get('name')
    [int] $MaxLogs = $parsedQuery.Get('limit')
    $UsingUGit = $true

    if ( [String]::IsNullOrWhitespace( $ClonedRepoRoot ) ) {
        $ClonedRepoRoot = GetConfig.ClonedRepoRoot | Get-Item -ea 'stop'
        'RootPath: {0}' -f ( $ClonedRepoRoot ) | Write-Verbose
    }
    $RepoPath = Join-Path $ClonedRepoRoot $OwnerRepoPair # todo(sanitization): use a better escape and match method
    if ( ! ( Test-Path $RepoPath )) {
        "/repo/log Error: Invalid OwnerRepoPair! '${OwnerRepoPair}'" | Write-Host -fore red
        throw "/repo/log Error: Invalid OwnerRepoPair! '${OwnerRepoPair}'"
    }
    # Run real git with args:
    #region Invoke Real Git Args
    $binGit = Get-Command -CommandType Application -Name 'git' -ea 'Stop' -TotalCount 1
    [Collections.Generic.List[object]] $gitArgs = @(
        '-C'
        $RepoPath
        'log'
        if ( $MaxLogs ) {
            '-n'
            $MaxLogs
        }
        # $OwnerRoot # if not using provider, declare path
    )

    $gitArgs
    | Join-String -sep ' ' -op 'Clone: invoke ''git'' => '
    | Write-Verbose

    if ( $UsingUGit ) {
        #  use regular git or ugit
        # note: this is because ugit doesn't support '-C' flag (edit: does if last)
        try {
            Push-Location $RepoPath -ea 'stop' -StackName 'GitServe.Get-Log'
            $gitArgs = @(
                'log'
                if ( $MaxLogs ) {
                    '-n'
                    $MaxLogs
                }
            )
            $SelectProperty = 'CommitDate', 'GitUserName', 'Date', 'Scope', 'CommitType', 'Merged', 'CommitHash', 'Trailer', 'Trailers'

            $results = & 'Ugit\git' @gitArgs
            | Select-Object -Property $SelectProperty
        }
        catch {
            "/repo/log Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
            | Write-Host
            "/repo/log Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
            | Write-Error
        }
        finally {
            Pop-Location -ea 'ignore' -StackName 'GitServe.Get-Log'
        }
        return $results
    }

    # regular git
    $results = & $binGit @gitArgs

    <#
    $parsedQuery = [Web.HttpUtility]::ParseQueryString( $Request.Url.Query.ToLower() )
    [string] $gitUrl = @( $parsedQuery.GetValues('url') )[0]

    InvokeCli.Git.CloneRepo -Url $gitUrl -path (GetConfig.ClonedRepoRoot -First)
        | Write-Debug

    [pscustomobject]@{
        PSTypeName         = 'GitServe.Route.Repo.Clone'
        Query              = $request.Url.PathAndQuery
        CloneUrl           = $gitUrl
        # DebugRequest       = $Request
    }
    #>
    $results
    #endregion Invoke Real Git Args
}
