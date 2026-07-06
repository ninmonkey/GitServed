#requires -Module Mintils

function _PickRepo {
    <#
    .synopsis
       (debug util). quickly swap example repos
    .example
        ($out = git log -C (_PickRepo) | Metric-GitServeCommitCount ) | ft -AutoSize
    #>
    [CmdletBinding()]
    param(
        # Root folder of cloned repos
        [ArgumentCompletions( 'C:\GitLoggerApp\ClonedRepos', '.' )]
        [Parameter()]
        [string] $BaseRepoPath = 'C:\GitLoggerApp\ClonedRepos'
    )
    $choices = Mint.Find-GitRepository -BaseDirectory $BaseRepoPath -MaxDepth 4 -PassTHru
    $pick = $choices.fullName | fzf | Get-Item
    '$SelectedGitRepo = {0}' -f $pick | Write-Host -fg 'SlateGray'

    # save and emit new repo path
    $script:SelectedGitRepo  = $pick
    $pick
 }
