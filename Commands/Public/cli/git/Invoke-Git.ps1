# function Invoke-UGit {
function Invoke-GitServeUGit {
    <#
    .synopsis
        always invokes UGit command
    .example
        >
    #>
    [Alias(
        'GitServe.Invoke-UGit'
    )]
    [CmdletBinding()]
    param()
    throw "NYI"
    #region collect UGIt args
    #endregion collect UGIt args
}

# Cache the binary lookup because it's slow
$script:BinRealGit = Get-Command -CommandType Application -Name 'git' -ea 'Continue' -TotalCount 1

# function Invoke-RealGit {
function Invoke-GitServeRealGit {
    <#
    .synopsis
        always invokes native/real git
    .NOTES
        future includes an ignore redirect like 2>$null ? Or move that to a special command that invokes this
    .example
        # DryRun: Do not actually invoke git. Just print the arguments that would be
        > GitServe.Invoke-RealGit -DryRun -FromPath 'C:\data\myGit\GitServed' -ArgList 'log', '-n', '2'
    .example
        > GitServe.Invoke-RealGit -FromPath 'C:\data\myGit\GitServed' -ArgList 'log', '-n', '2'
    .example
        # example: list HEAD files
        # the original command was: git.exe -C (gi '.') ls-tree -r HEAD --name-only
        GitServe.Invoke-RealGit -Path '.' -GitArgList 'ls-tree', '-r', 'HEAD', '--name-only'
    #>
    [Alias(
        'GitServe.Invoke-RealGit'
    )]
    [CmdletBinding()]
    param(
        # Arguments passed to real 'git'. Or any not configurable from the other parameters
        [Alias('ArgList', 'GitArgs', 'RealGitArgs')]
        [string[]] $GitArgList,

        # What path will you execute from? This saves you the overhead of changing directories
        [Alias('Path', 'PSPath', 'GitRepositoryPath', 'RepoPath')]
        [Parameter()]
        [string] $FromPath, # = '.',

        # view the commandline that *would* be ran, but don't actually run it.
        [Alias('TestOnly', 'WhatIf')]
        [switch] $DryRun,

        # for git argument: '--since=<string>'
        [ValidateScript({throw 'nyi'})]
        [string] $Since,

        # for git argument: '--before=<string>'
        [ValidateScript({throw 'nyi'})]
        [string] $Before,

        # for git argument: '--after=<string>'
        [ValidateScript({throw 'nyi'})]
        [string] $After,

        # Like -DryRun but returns the arguments instead of printing them
        [Alias('PassThru')]
        [switch] $OutputArgAsList,

        # Write to host
        [Alias('VerboseOutput')]
        [switch] $PSHost
    )
    begin {
        #region collect RealGit args
        $binGit = $script:BinRealGit
        [Collections.Generic.List[Object]] $gitArgs = @()

        # note: 'git' and 'ugit' requires you to place the '-C' args in a different location. The rest of the git args are normal between both.
        if( $PSBoundParameters.ContainsKey('FromPath')) {
            $absolutePath = Get-Item $FromPath -ea 'stop'
            $gitArgs.AddRange( @('-C', $absolutePath.FullName ) )
        }

        if( $GitArgList ) {
            # any extra parsing or filtering of user args?
            $gitArgs.AddRange( @( $GitArgList ) )
        }
        #endregion collect RealGit args
    }
    end {
        #region invoke RealGit
        "enter => '$( $MyInvocation.MyCommand.Name )'" | Write-Debug

        if( $OutputArgAsList ) {
            return @( $GitArgs )
        }
        if( $DryRun ) {
            $gitArgs
            | Join-String -sep ' ' -op 'Calling RealGit => git '
            | Write-host -fg 'SlateGray'

            return
        }

        # option to always log to host
        if( $PSHost ) {
            $gitArgs
            | Join-String -sep ' ' -op '  RealGit => git '
        }
        $gitArgs
            | Join-String -sep ' ' -op 'Calling RealGit => git '
            | Write-Debug

        $results = & $binGit @gitArgs
        $results
        # captures and emit so that the future is easily cache-able, and may redirect stderr to null
        #endregion invoke RealGit
    }
}
