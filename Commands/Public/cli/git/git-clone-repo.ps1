# function Invoke-GitClone {
function Invoke-GitServeClone {
    <#
    .synopsis
        Clone a public git repo using the 'git' cli ( without using 'gh' )
    .example
        > GitServe.Git.Clone 'https://github.com/BurntSushi/ripgrep.git'
    #>
    [Alias(
        'GitServe.Git.Clone'
    )]
    [CmdletBinding( DefaultParameterSetName = 'CloneFromRawUrl' )]
    param(
        # Git url to clone
        [Parameter( ParameterSetName = 'CloneFromRawUrl', Position = 0, Mandatory )]
        [Alias( 'Repo', 'Clone', 'Url', 'GitUrl')]
        [ArgumentCompletions(
            'https://github.com/BurntSushi/ripgrep.git'
        )]
        [string] $CloneUrl, # ( string because not all valid git clone urls are valid,

        [string] $FromPath = '.'
    )
    end {
        "enter => '$( $MyInvocation.MyCommand.Name )'" | Write-Debug
        _InvokeCli.Git.CloneRepo -CloneUrl $CloneUrl -FromPath $FromPath -PSHost:$True
    }
    # [pscustomobject]@{
    #     PSTypeName = 'GitServe.Git.Clone'
    #     CloneUrl = $CloneUrl
    #     Result = '<NYI>'
    # }
}
