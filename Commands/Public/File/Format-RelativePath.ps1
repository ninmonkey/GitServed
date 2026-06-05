function Format-GitServeRelativePath {
    <#
    .synopsis
        Abbreviate a full path relative to another directory
    .example
        # Print paths relative the current Directory
        gci . -Depth 2 | Format-GitServeRelativePath
    .example
        > Get-Item 'c:\git\pwsh\SeeminglyScience'
            | Format-GitServeRelativePath 'c:\git'

        pwsh\SeeminglyScience
    #>
    [Alias('GitServe.Format-RelativePath')]
    [OutputType( [string] )]
    [CmdletBinding()]
    param(
        [Alias('BasePath')]
        [Parameter(Position = 0)]
        $RelativeTo = '.',

        # Strings / paths to convert
        [Alias('PSPath', 'FullName', 'InObj')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]] $Path,

        # Emit an object with path properties, including the raw original path
        [Alias('PassThru')]
        [switch] $AsObject
    )
    process {
        $RelativeTo = Get-Item $RelativeTo
        foreach( $item in ( $Path | Convert-Path ) ) {
            $relPath = [System.IO.Path]::GetRelativePath(
                <# string: relativeTo #> $RelativeTo,
                <# string: path #>  $Item )

            if( -not $AsObject ) {
                $relPath
                continue
            } else {
                [pscustomobject]@{
                    PSTypeName = 'GitServed.RelativePath'
                    Path       = $relPath
                    Original   = $Item
                    RelativeTo = $RelativeTo
                }
                continue
            }
        }
    }
}
