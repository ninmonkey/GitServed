function Invoke-GitClone {
    <#
    .synopsis
        Clone a public git repo using the 'git' cli ( without using 'gh' )
    .example
        > GitServe.Git.Clone 'https://github.com/BurntSushi/ripgrep.git'
    #>
    # [Alias('GitServe.Cli.Git.Clone')]
    [CmdletBinding( DefaultParameterSetName = 'CloneFromRawUrl' )]
    param(
        # Git url to clone
        [Parameter( ParameterSetName = 'CloneFromRawUrl', Position = 0, Mandatory )]
        [Alias('Clone', 'Url', 'GitUrl')]
        [ArgumentCompletions(
            'https://github.com/BurntSushi/ripgrep.git'
        )]
        [string] $CloneUrl # ( string because not all valid git clone urls are valid
    )
    end {
        "enter => '$( $MyInvocation.MyCommand.Name )'" | Write-Debug
        throw "NYI"
        _InvokeCli.Git.CloneRepo -CloneUrl $CloneUrl
    }
    # [pscustomobject]@{
    #     PSTypeName = 'GitServed.Git.Clone'
    #     CloneUrl = $CloneUrl
    #     Result = '<NYI>'
    # }
}
