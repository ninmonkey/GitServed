function Metric-GitServeCommitCount {
    <#
    .SYNOPSIS
        Number of commits grouped and sorted by: "<Year>-<Month>_<GitUserName>" as text Descending
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
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [DateTime] $CommitDate,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $GitUserName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $GitUserEmail,

        # Input has 'ugit' properties like 'git.log'
        [Parameter(ValueFromPipeline)]
        [object] $InputObject,

        # Period to aggregate by: 'year' | 'month' | 'day'
        [ValidateSet('month', 'day', 'year')]
        [string] $Period = 'month'
    )
    begin {
        $dateDisplayFormat = 'yyyy-MM-dd'
        switch( $Period ) {
            'year' { $keyFormat  = 'yyyy' }
            'month' { $keyFormat  = 'yyyy-MM' }
            'day' { $keyFormat  = 'yyyy-MM-dd' }
            default { throw "Invalid Period! ${Period}" }
        }
        function __toKeyId {
            # Generate a PrimaryKey. This determines distinct testing for records
            param( $Obj )
            '{0}_{1}' -f @(
                $Obj.CommitDate.ToString( $keyFormat )
                $Obj.GitUserName
            )
        }
        $reverseComparer = [System.Collections.Generic.Comparer[string]]::Create({
            param($x, $y) [string]::Compare($y, $x)
        }) # todo: use numeric date sort
        [Collections.Generic.SortedDictionary[string,object]] $metric = $reverseComparer
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
        ,@( $metric.Values )
    }
}
