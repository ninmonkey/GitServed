function ConvertFrom-GitServeShortRepoName {
    <#
    .synopsis
        (internal) Resolve a valid directory path using relative repo names
    .DESCRIPTION
        Exceptions - Does not throw unless you opt in. Default behavior is to write error and returns $Null.

        -Throw : always throw when path is missing. Opposite of NeverThrow
    .notes
        should it throw an exception if more than one repo matches the name?
        should it throw if none is found? Or write error and return null?
    .example
        > $optional = GitServe.Path.FromShortRepoName -Name 'BurntSushi/ripgrep'
        > $required = GitServe.Path.FromShortRepoName -Name 'BurntSushi/ripgrep' -Throw
    #>
    [Alias('GitServe.Path.FromShortRepoName')]
    [OutputType(
        [System.IO.DirectoryInfo]
    )]
    [CmdletBinding()]
    param(
        # ex: "BurntSushi/ripgrep" . ( see "OwnerRepoPair" from /repo/list )
        [Alias('Name', 'RepoOwnerPair' )]
        [Parameter(Mandatory)]
        [string] $ShortRepoName,

        # Base directory to search. Default is from: GetConfig.ClonedRepoRoot
        [Alias('ClonedRepoRoot', 'RelativeRoot', 'Root', 'Path')]
        [string] $BasePath,

        # opt-in to throwing on missing paths ( Does not throw unless you opt in. Default behavior is to write error and returns $Null )
        [switch] $Throw
    )

    if ( [String]::IsNullOrWhitespace( $BasePath ) ) {
        $ClonedRepoRoot = GetConfig.ClonedRepoRoot | Get-Item -ea 'stop'
        'RootPath: {0}' -f ( $ClonedRepoRoot ) | Write-Verbose
    }
    $RepoPath = Join-Path $ClonedRepoRoot $ShortRepoName # todo(sanitization): use a better escape and match method
    if( ! ( Test-Path $RepoPath )) {
        $ErrorMsg = "Error: Invalid ShortRepoName! '${ShortRepoName}'"
        if( $Throw ) { throw $ErrorMsg }

        $errorMsg | Write-Error
        return # or throw "Error: Invalid ShortRepoName! '${ShortRepoName}'"
    }
    return (Get-Item $RepoPath)
}
