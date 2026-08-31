
# Cache the binary lookup because it's slow
$script:BinRealGit = Get-Command -CommandType Application -Name 'git' -ea 'Continue' -TotalCount 1

function Invoke-GitServeUGit {
    <#
    .synopsis
        always invokes UGit command
    .notes
        Use-Git requires -C param to be last, rather than first. ie:

            > Use-Git -GitArgument @( 'log', '-n', '3', '-C', (gi '.' ) )
    .example
        # RealGit vs UGit, same syntax:
        > GitServe.Invoke-UGit    -FromPath (gi .) -GitArgList 'log', '-n', '3'
        > GitServe.Invoke-RealGit -FromPath (gi .) -GitArgList 'log', '-n', '3'
    .example
        GitServe.Invoke-Ugit -FromPath '..\GitServed\' status
        GitServe.Invoke-UGit log, -n, 2
    .link
        Invoke-GitServeRealGit
    .link
        Invoke-GitServeUGit
    #>
    [Alias(
        'GitServe.Invoke-UGit'
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
        [string] $Since,

        # for git argument: '--before=<string>'
        [string] $Before,

        # for git argument: '--after=<string>'
        [string] $After,

        # Like -DryRun but returns the arguments instead of printing them
        [Alias('PassThru')]
        [switch] $OutputArgAsList,

        # Write to host
        [Alias('VerboseOutput')]
        [switch] $PSHost
    )
    begin {
        #region collect UGit args
        $binGit = $script:BinRealGit
        [Collections.Generic.List[Object]] $gitArgs = @()
        if( $GitArgList.count -gt 0 ) {
            # any extra parsing or filtering of user args?
            $gitArgs.AddRange( @( $GitArgList ) )
        }
        if( -not [string]::IsNullOrWhiteSpace( $Since ) ) {
            $gitArgs.Add( ( '--since="{0}"' -f $Since ))
        }
        if( -not [string]::IsNullOrWhiteSpace( $Before ) ) {
            $gitArgs.Add( ( '--before="{0}"' -f $Before ))
        }
        if( -not [string]::IsNullOrWhiteSpace( $After ) ) {
            $gitArgs.Add( ( '--after="{0}"' -f $After ))
        }
        if( $PSBoundParameters.ContainsKey('FromPath') ) {
            <#
            ugit warning: '-C' must be placed in the correct position or else you get a silent error
            It must be the *very last*, which is the incorrect position for RealGit
                GitServe.Invoke-UGit '-C', (gi '.' ), log # Silently fails, returning error objects
                GitServe.Invoke-UGit log, '-C', (gi '.')  # working query
            #>
            $absolutePath = Get-Item $FromPath -ea 'stop'
            $gitArgs.AddRange( @('-C', $absolutePath.FullName ) )
        }
        #endregion collect UGit args
    }
    process { }
    end {
        #region invoke UseGit
        "enter => '$( $MyInvocation.MyCommand.Name )'" | Write-Debug

        if( $OutputArgAsList ) {
            return @( $GitArgs )
        }
        if( $DryRun ) {
            $gitArgs
            | Join-String -sep ' ' -op 'Calling UseGit => git '
            | Write-host -fg 'SlateGray'
            return
        }

        # option to always log to host
        if( $PSHost ) {
            $gitArgs
            | Join-String -sep ' ' -op '  UseGit => git '
        }
        $gitArgs
            | Join-String -sep ' ' -op 'Calling UseGit => git '
            | Write-Debug

        Use-Git -GitArgument $gitArgs
        #endregion invoke UseGit
    }
}
function Invoke-GitServeRealGit {
    <#
    .synopsis
        always invokes native/real git
    .NOTES
        future includes an ignore redirect like 2>$null ? Or move that to a special command that invokes this
    .example
        # to run: git --no-pager log -n 4 --format=oneline --color=always
        GitServe.Invoke-RealGit --no-pager, log, -n, 4, --format=oneline, --color=always

        # or the same using cmdlet parameters
        GitServe.Invoke-RealGit -NoPager -ColorAlways log, -n, 4, --format=oneline
    .example
        # setting custom output format
        GitServe.Invoke-RealGit -Format oneline log, -n, 4, --abbrev-commit, --after=2022-12-01
    .example
        # DryRun: Do not actually invoke git. Just print the arguments that would be
        > GitServe.Invoke-RealGit -DryRun -FromPath 'C:\data\myGit\GitServed' -ArgList 'log', '-n', '2'
    .example
        > GitServe.Invoke-RealGit -FromPath 'C:\data\myGit\GitServed' -ArgList 'log', '-n', '2'
    .example
        # example: list HEAD files
        # the original command was: git.exe -C (gi '.') ls-tree -r HEAD --name-only
        GitServe.Invoke-RealGit -Path '.' -GitArgList 'ls-tree', '-r', 'HEAD', '--name-only'
    .example
        # show tags, jump to tag
        GitServe.Invoke-RealGit -ColorAlways -NoPager tag, -n
        # out: v0.0.12
        GitServe.Invoke-RealGit -ColorAlways -NoPager show, v0.0.12

        # show hash and message since tag
        GitServe.Invoke-RealGit -ColorAlways -NoPager log, v0.0.12..HEAD, --oneline

        # show commit message only since tag
        GitServe.Invoke-RealGit -ColorAlways -NoPager log, v0.0.12..HEAD, --format=%s
    .link
        Invoke-GitServeRealGit
    .link
        Invoke-GitServeUGit
    #>
    [Alias(
        'Git',
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
        [string] $Since,

        # for git argument: '--before=<string>'
        [string] $Before,

        # for git argument: '--after=<string>'
        [string] $After,

        # for git argument: --no-pager
        # depending on the command, and if you're running as jobs, this may or may not matter ( at least when ran in non-interactive mode )
        [switch] $NoPager,

        # always output ansi escapes: for git argument: --color=always
        [switch] $ColorAlways,

        # for git argument: --format=<format>:
        <#
        note(valid): valid formats for  'git log':
            one of oneline, short, medium, full, fuller, reference, email, raw, format:<string> and tformat:<string>.
            When <format> is none of the above, and has %placeholder in it, it acts as if --pretty=tformat:<format> were given.
        #>
        [ArgumentCompletions('oneline', 'short', 'medium', 'full', 'fuller', 'reference', 'email', 'raw'  )]
        [string] $Format,

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

        #region args before -C
        if( $NoPager ) {
            $gitArgs.Add('--no-pager')
        }
        #endregion args before -C

        if( $PSBoundParameters.ContainsKey('FromPath')) {
            # note: real git requires '-C' before almost all args.
            $absolutePath = Get-Item $FromPath -ea 'stop'
            $gitArgs.AddRange( @('-C', $absolutePath.FullName ) )
        }

        if( $GitArgList.count -gt 0 ) {
            # any extra parsing or filtering of user args?
            $gitArgs.AddRange( @( $GitArgList ) )
        }

        if( -not [string]::IsNullOrWhiteSpace( $Since ) ) {
            $gitArgs.Add( ( '--since="{0}"' -f $Since ))
        }
        if( -not [string]::IsNullOrWhiteSpace( $Before ) ) {
            $gitArgs.Add( ( '--before="{0}"' -f $Before ))
        }
        if( -not [string]::IsNullOrWhiteSpace( $After ) ) {
            $gitArgs.Add( ( '--after="{0}"' -f $After ))
        }

        #region args after all other git args
        if( $Format ) {
            $gitArgs.Add( "--format=${Format}" )
        }
        if( $ColorAlways ) {
            $gitArgs.Add( '--color=always' )
        }
        #endregion args after all other git args
        #endregion collect RealGit args
    }
    process { }
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
        $Git_ExitCode = $LASTEXITCODE
        if( $Git_ExitCode -ne 0) {
            throw "GitServe.Invoke-RealGit: Git exit code != 0 !: ${Git_ExitCode} "
        }
        $results
        # captures and emit so that the future is easily cache-able, and may redirect stderr to null
        #endregion invoke RealGit
    }
}
