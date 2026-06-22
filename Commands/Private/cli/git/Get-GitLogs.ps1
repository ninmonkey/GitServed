

function InvokeCli.Git.Log { # or FromDictionaryEntry
    <#
    .SYNOPSIS
        (internal) Invoke native git clone, and create folders based on the url: '/<root>/<owner>/<repo>'
    .DESCRIPTION
        ClonedRepoRoot - '/cloned-repos' will clone to '/cloned-repos/owner/repository'
    .EXAMPLE
        InvokeCli.Git.CloneRepo -CloneUrl 'https://github.com/owner/repo.git'
    .EXAMPLE
        # change root and print debug info
        InvokeCli.Git.CloneRepo -CloneUrl 'https://github.com/owner/repo.git' -Path '/cloned-repos' -PSHost -Verbose
    .LINK
        GitServe\Invoke-GitClone
    .LINK
        GitServe\GitServe.Clone
    #>
    [CmdletBinding()]
    param(
        [Alias('Url')]
        [Parameter(Mandatory)]
        [string] $CloneUrl,

        # root directory to clone under. '/cloned-repos' would clone to '/cloned-repos/owner/repository'
        [Alias('Path', 'PSPath')]
        [string] $ClonedRepoRoot,

        # Write to host
        [Alias('VerboseOutput')]
        [switch] $PSHost
    )

    $OriginalPath = Get-Item '.'
    if ( [String]::IsNullOrWhitespace( $ClonedRepoRoot ) ) {
        $ClonedRepoRoot = GetConfig.ClonedRepoRoot | Get-Item -ea 'stop'
        'Path: {0}' -f ( $ClonedRepoRoot ) | Write-Verbose
    }

    $uriPrefix, $OwnerName, $RepoName = $CloneUrl -split '/', -3
    $RepoName = $RepoName -replace '\.git$'

    <#
    example uri output values:
        > $cloneUrl = 'https://github.com/BurntSushi/ripgrep.git'
        > $uriPrefix, $OwnerName, $RepoName
        https://github.com, BurntSushi, ripgrep.git
    #>

    [ordered]@{ OwnerName = $OwnerName; RepoName = $RepoName; UriPrefix = $UriPrefix ; CloneUrl = $CloneUrl; ClonedRepoRoot = $ClonedRepoRoot }
        | ConvertTo-Json -Compress -depth 2
        | Write-Verbose

    if( [String]::IsNullOrWhiteSpace( $OwnerName ) ) {
        throw "OwnerName from the CloneUrl is blank!"
    }
    $OwnerRoot = Join-Path $ClonedRepoRoot $OwnerName
    if( -not ( Test-Path $OwnerRoot ) ) {
        $OwnerRoot = New-Item -ItemType Directory -Path $OwnerRoot -ea 'stop'
    }

    Set-Location -Path $OwnerRoot -ea 'stop' # note(threading): May need to remove provider use for threading

    # Run real git with args:
    #region Invoke Real Git Args
    $binGit = Get-Command -CommandType Application -Name 'git' -ea 'Stop' -TotalCount 1
    [Collections.Generic.List[object]] $gitArgs = @(
        'clone'
        $CloneUrl
        # $OwnerRoot # if not using provider, declare path
    )

        if( -not (Test-Path (Join-Path $OwnerRoot $OwnerName)) ) {
        $gitArgs
            | Join-String -sep ' ' -op 'Clone: invoke ''git'' => '
            | Write-Verbose

        $results = & $binGit @gitArgs
        if( $PSHost ) {
            $Results | Write-Host
        }
        # $results
    } else {
        if( $PSHost ) {
        "Directory '${ownerName}' already exists. Skipping clone."
            | Write-Host -fg 'Green'
        }
    }

    Set-Location -Path $OriginalPath
    #endregion Invoke Real Git Args
}
