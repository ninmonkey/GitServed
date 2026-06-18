function InvokeCli.Git.CloneRepo { # or FromDictionaryEntry
    <#
    .SYNOPSIS
        private invoke cloning git command
    .DESCRIPTION
    .EXAMPLE
    .LINK
        GitServe\Invoke-GitClone
    #>
    # [CmdletBinding()]
    # [Alias('_Cli.Git.Clone')]
    param(
        [Parameter(Mandatory)]
        [string] $CloneUrl,

        # CWD to clone from
        [Alias('GitCwd')]
        [string] $FromPath = '.',

        [Alias('VerboseOutput')]
        [switch] $PSHost
    )

    $CdStackName    = 'cli.git-clone'

    $uriPrefix, $OwnerName, $RepoName = $CloneUrl -split '/', -3
    $RepoName = $RepoName -replace '\.git$'

    <#
    example uri output values:
        > $cloneUrl = 'https://github.com/BurntSushi/ripgrep.git'
        > $uriPrefix, $OwnerName, $RepoName
        https://github.com, BurntSushi, ripgrep.git
    #>


    [ordered]@{ OwnerName = $OwnerName; RepoName = $RepoName; UriPrefix = $UriPrefix ; CloneUrl = $CloneUrl }
        | ConvertTo-Json -Compress -depth 2
        | Write-Verbose

    if( [String]::IsNullOrWhiteSpace( $OwnerName ) ) {
        throw "OwnerName from the CloneUrl is blank!"
    }

    Push-Location -Stack $CdStackName $FromPath

    # Run real git with args:
    #region Invoke Real Git Args
    $binGit = Get-Command -CommandType Application -Name 'git' -ea 'Stop' -TotalCount 1
    [Collections.Generic.List[object]] $gitArgs = @(
        'clone'
        $CloneUrl
    )

    if( -not (Test-Path (Join-Path $FromPath $ownerName)) ) {
        $gitArgs
            | Join-String -sep ' ' -op 'Clone: invoke ''git'' => '
            | Write-Host -fg 'gray60'

        $results = & $binGit @gitArgs
        if( $PSHost ) {
            $Results
        }
        # $results
    } else {
        "Directory '${ownerName}' already exists. Skipping clone."
            | Write-Host -fg 'Green'
    }

    Pop-Location -Stack $cdStackName # -ea Ignore

    #endregion Invoke Real Git Args
}
