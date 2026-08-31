<#
.synopsis
    Get changed commit messages since last tag
.example
    ./GetChangesSinceTag.ps1 -Simple
.example
    ./GetChangesSinceTag.ps1 -TagFrom 'v0.0.12' -CompareTagName 'v0.0.13' -Simple
.example
    ./GetChangesSinceTag.ps1 -TagFrom 'v0.0.13' -Simple
#>

param(

    # starting tag, ex "v0.0.13"
    # Default is the latest
    [ArgumentCompletions("'v0.0.13'")]
    [Parameter(Position=0)]
    [string] $TagFrom,

    # up to tag name, default is "HEAD"
    [Parameter(Position=1)]
    [ArgumentCompletions("'HEAD'", "'v0.0.14'")]
    [string] $CompareTagName = 'HEAD',

    # shows commit messages only
    [switch] $Simple
)

$binGit = gcm 'git' -CommandType Application -TotalCount 1 -ea stop
if( -not $TagFrom ) {
    $tagFrom = & $binGit describe --tags --abbrev=0
}
$target ="${TagFrom}..${CompareTagName}"
$GitArgs = @(
    '--no-pager'
    'log'
    $Target
    if( $Simple ) {
        '--format=%s'
    }
)
& $binGit @GitArgs | Set-Clipboard -PassThru
"for ""${target}""" | Write-Verbose -Verbose
