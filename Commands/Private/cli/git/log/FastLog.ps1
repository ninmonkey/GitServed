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
        [string] $After,

        # Should it write errors when date format fails ? otherwise coerce them into null
        [switch] $ShowDateError,

        [switch] $PSHost
    )

    # working:
    # $logs = GitServe.Invoke-RealGit -NoPager -GitArgList log, --date=iso, --pretty=format:"%cd${delim}%an${delim}%ae${delim}[%s]"

    # get all parameters
    # $params = @{} + $PSBoundParameters
    $passedParams = [hashtable]::new( $PSBoundParameters )
    $delim = "`u{2400}"
    $strLFSymbol = "`u{240a}"

    # $buffer = @( $passedParams['GitArgList'] )

    $passedParams['GitArgList'] = @(
        'log'
        # @buffer
        # $passedParams['GitArgList'] # this was sometimes blank
        '--date=iso'

        # this
        # "--pretty=format:%cd${delim}%an${delim}%ae${delim}[%s]"
        # should be
        # '--pretty=format:%cd␀%an␀%ae␀[%s]'
        "--pretty=format:%cd${Delim}%an${Delim}%ae${Delim}[%s]"
    )
    $DateIsoFstr = "yyyy-MM-dd HH:mm:ss zzz"

    # git.exe --no-pager log --pretty=format:"%cd${delim}%an${delim}%ae${delim}[%s]" --date=iso
    # $logs  = ...

    # $logs = Invoke-GitServeRealGit -PSHost -Verbose @passedParams
    if( $PSHost ) {
        $passedParams | ConvertTo-Json | Write-Host -fg 'cyan'
    }
    Invoke-GitServeRealGit -NoPager @passedParams # -ea break # -PSHost -Verbose
    | % {
        $line = $_
        $dateStr, $author, $email, $commitMessage, $rest  =  $line -split $delim, 5

        # $Date = [DateTime]::ParseExact($date, $DateIsoFstr, ([cultureinfo]::InvariantCulture) )
        # $Date = [DateTime]::ParseExact($date, $DateIsoFstr, $null )
        $date = $dateStr
        try { $date = [datetime]::ParseExact( $dateStr, $DateIsoFstr, $Null ) }
        catch {
            $date = $null
            if( ShowDateError ) {
                "Failed parsing commit date for line: '${Line}'" | Write-Error
            }
        }

        [pscustomobject]@{
            CommitDate =
                $DateStr
                # $Date
            GitUserName = $Author
            GitUserEmail = $Email
            CommitMessage = $commitMessage -join "`n"  #or symbol:  $strLFSymbol
            Rest = $Rest -join $strLFSymbol
        }
    }
}
