function FastGitLog {
    <#
    .SYNOPSIS
        a Faster version of 'git log' than ugit, but still returns objects
    #>
    param(
# Arguments passed to real 'git'. Or any not configurable from the other parameters
        [Alias('ArgList', 'GitArgs', 'RealGitArgs')]
        [string[]] $GitArgList,

        # What path will you execute from? This saves you the overhead of changing directories
        [Alias('Path', 'PSPath', 'GitRepositoryPath', 'RepoPath')]
        [Parameter()]
        [string] $FromPath, # = '.',

        # for git argument: '--since=<string>'
        [string] $Since,

        # for git argument: '--before=<string>'
        [string] $Before,

        # for git argument: '--after=<string>'
        [string] $After
    )

    # working:
    # $logs = GitServe.Invoke-RealGit -NoPager -GitArgList log, --date=iso, --pretty=format:"%cd${delim}%an${delim}%ae${delim}[%s]"

    # get all parameters
    # $params = @{} + $PSBoundParameters
    $passedParams = [hashtable]::new( $PSBoundParameters )
    $delim = "`u{2400}"

    $passedParams['GitArgList'] = @(
        $passedParams['GitArgList']
        '--date=iso'
        "--pretty=format:`"%cd${delim}%an${delim}%ae${delim}[%s]`""
    )

    # git.exe --no-pager log --pretty=format:"%cd${delim}%an${delim}%ae${delim}[%s]" --date=iso
    # $logs  = ...

    # $logs = Invoke-GitServeRealGit -PSHost -Verbose @passedParams
    Invoke-GitServeRealGit -PSHost -Verbose @passedParams
    | % {
        $date, $author, $email, $rest  =  $_ -split $delim, 4
        [pscustomobject]@{
            CommitDate = $Date
            GitUserName = $Author
            GitUserEmail = $Email
        }
    }
}
