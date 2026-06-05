function _InvokeCli.Git.CloneRepo { # or FromDictionaryEntry
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
        [string] $CloneUrl
    )

    $CdStackName    = 'cli.git-clone'

    $uriPrefix, $OwnerName, $RepoName = $CloneUrl -split '/', -3
    $RepoName = $RepoName -replace '\.git$'

    try {
        if( [String]::IsNullOrWhiteSpace( $OwnerName ) ) {
            Write-Error "OwnerName from the CloneUrl is blank!"
            Pop-Location -stack $CdStackName @eaIgnore
            Push-Location $OriginalPath
            return
        }
    } catch {
        $msg = "Exception from command: $( $MyInvocation.MyCommand.Name )"
        $msg | Write-Error
        $msg | Write-Host -fg 'orange'
        throw $_
    }
    finally {
        Push-Location -Stack $CdStackName -ea 'Ignore'
    }



    <#
    example uri output values:
        > $cloneUrl = 'https://github.com/BurntSushi/ripgrep.git'
        > $uriPrefix, $OwnerName, $RepoName
        https://github.com, BurntSushi, ripgrep.git
    #>
}


return

[ordered]@{ OwnerName = $OwnerName; RepoName = $RepoName; UriPrefix = $UriPrefix ; CloneUrl = $CloneUrl }
    | ConvertTo-Json -Compress | Write-Host

if( [String]::IsNullOrWhiteSpace( $OwnerName ) ) {
    Write-Error "OwnerName from the CloneUrl is blank!"
    Pop-Location -stack $CdStackName @eaIgnore
    Push-Location $OriginalPath
    return
}

# create and cd into the folder <OwnerName> before cloning the repo
$ReposRoot = Get-Item @eaStop -Path $PwshWebConfig.Paths.ClonedReposRoot # ex: '/cloned-repos'
$OwnerRoot = Join-Path $ReposRoot $OwnerName
$binGit    = Get-Command -CommandType Application -Name 'git' @eaStop -TotalCount 1

if( -not ( Test-Path $OwnerRoot ) ) {
    $OwnerRoot = New-Item -ItemType Directory -Path $OwnerRoot @eaStop
}
Push-Location -StackName $CdStackName $OwnerRoot

[Collections.Generic.List[object]] $gitArgs = @(
    'clone'
    $CloneUrl
)

if( -not (Test-Path (Join-Path '.' $ownerName)) ) {
    $gitArgs | Join-String -sep ' ' -op 'Clone: invoke ''git'' => ' | Write-Host
    & $binGit @gitArgs
} else {
    "Directory '${ownerName}' already exists. Skipping clone." | Write-Host
}

Pop-Location  -StackName $CdStackName
Push-Location $OriginalPath

#endregion Clone Repo Block

"exit => '$( $MyInvocation.MyCommand.Name )'" | Write-Host
