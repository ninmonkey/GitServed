function Metric-GitServeLanguageCount {
    <#
    .SYNOPSIS
        Which languages are used in a repo
    .NOTES
        Expects input type: 'git.log'
    .EXAMPLE
        git log | Metric-CommitCount
        git log | Metric-GitServeCommitCount -Period month
    .EXAMPLE
        Use-Git -GitArg 'log', '-n', 4, '-C', $path | GitServe.Metric.CommitCount
    #>
    [Alias('GitServe.Metric.CommitCount')]
    [OutputType(
        '[System.Collections.Generic.SortedDictionary[string,object]]'
    )]
    [CmdletBinding()]
    param(
        # Path of git repo
        [Parameter(Mandatory)]
        [Alias('BaseDir', 'Repository', 'Path')]
        [string] $GitRepositoryPath
    )
    begin {
        # ( git.exe -C (gi .\Azure\) ls-tree -r HEAD --full-tree --name-only ).count
        # todo: refactor generic
    }
    process {
        $key = __toKeyId $InputObject
        if( -not $metric.ContainsKey( $key ) ) {
            $initialValue = [pscustomobject][ordered]@{
                PSTYpeName  = 'GitServe.Metric.CommitCount'
                DateDisplay  = $CommitDate.ToString( $dateDisplayFormat )
                GitUserName = $GitUserName
                CommitCount = 1
                Year        = $CommitDate.Year
                Month       = $CommitDate.Month
                CommitDate  = $CommitDate
                KeyId       = $key
            }
            $metric[ $key ] = $initialValue
        } else {
            $metric[ $key ].CommitCount += 1
        }
    }
    end {
        # if( $IncludeMissingDates ) {
        #     # add any missing dates as explicit 0. Dates are based on the selected $period type. year/month/day/etc.
        # }
        ,@( $metric.Values )
    }
}
