function Metric-GitServeCommitCount {
    <#
    .SYNOPSIS
        Number of commits grouped and sorted by: "<Year>-<Month>_<GitUserName>" as text Descending
    .NOTES
        Expects input type: 'git.log'
    .EXAMPLE
        git log | Metric-CommitCount
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
        [object] $InputObject
    )
    begin {
        function __toKeyId {
            # Generate a PrimaryKey. This determines distinct testing for records
            param( $Obj )
            '{0}_{1}' -f @(
                $Obj.CommitDate.ToString('yyyy-MM')
                $Obj.GitUserName
            )
        }
        $reverseComparer = [System.Collections.Generic.Comparer[string]]::Create({
            param($x, $y) [string]::Compare($y, $x)
        })
        [Collections.Generic.SortedDictionary[string,object]] $metric = $reverseComparer

        #//@{}
    }
    process {
        $key = __toKeyId $InputObject
        if( -not $metric.ContainsKey( $key ) ) {
            $initialValue = [pscustomobject][ordered]@{
                PSTYpeName  = 'GitServe.Metric.CommitCount'
                DateString  = $CommitDate.ToString('yyyy-MM')
                GitUserName = $GitUserName
                CommitCount = 1
                Year        = $CommitDate.Year
                Month       = $CommitDate.Month
                KeyId       = $key
                CommitDate  = $CommitDate
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
