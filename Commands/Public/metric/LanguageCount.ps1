function Metric-GitServeLanguageCount {
    <#
    .SYNOPSIS
        Which languages are used in a repo
    .NOTES
        Expects input type: 'git.log'
    .EXAMPLE
        git log | Metric-LanguageCount
        git log | Metric-GitServeLanguageCount -Period month
    .EXAMPLE
        GitServe.Metric.LanguageCount -Path '.'
    #>
    [Alias('GitServe.Metric.LangaugeCount')]
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
    }
    process {
    }
    end {
        $results = InvokeCli.Git.LsTree.Files -GitRepositoryPath $GitRepositoryPath
        # note: slow because of the provider, but,
        $instances = $results | gi | % Extension
        $found = ($instances | Get-item | % Extension ) | Group-Object -NoElement | Sort count -Descending

        $summary = $found.GetEnumerator() | %{
            $extension = $_.Name -replace '^\.'
            $count    = $_.Count
            [pscustomobject][ordered]@{
                PSTYpeName = 'GitServe.Metric.LanguageCount'
                Extension  = $extension
                Count      = $count
                KeyId      = $extension
            }
        }
        , @( $summary )
    }
}
