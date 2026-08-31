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

    # $buffer = @( $passedParams['GitArgList'] )

    $passedParams['GitArgList'] = @(
        'log'
        # @buffer
        # $passedParams['GitArgList'] # this was sometimes blank
        '--date=iso'
        "--pretty=format:%cd${delim}%an${delim}%ae${delim}[%s]"
    )
    $DateIsoFstr = "yyyy-MM-dd HH:mm:ss zzz"

    # git.exe --no-pager log --pretty=format:"%cd${delim}%an${delim}%ae${delim}[%s]" --date=iso
    # $logs  = ...

    # $logs = Invoke-GitServeRealGit -PSHost -Verbose @passedParams
    $passedParams | ConvertTo-Json | Write-Host -fg 'cyan'
    Invoke-GitServeRealGit -NoPager @passedParams # -ea break # -PSHost -Verbose
    | % {
        $dateStr, $author, $email, $rest  =  $_ -split $delim, 4

        # $Date = [DateTime]::ParseExact($date, $DateIsoFstr, ([cultureinfo]::InvariantCulture) )
        $Date = [DateTime]::ParseExact($date, $DateIsoFstr, $null )
        $date = $dateStr

        [pscustomobject]@{
            CommitDate = $Date
            GitUserName = $Author
            GitUserEmail = $Email
        }
    }
}
