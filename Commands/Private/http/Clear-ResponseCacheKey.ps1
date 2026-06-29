function Clear-ResponseCacheKey {
    <#
    .SYNOPSIS
        (internal) Clears cache by key names
    .NOTES
        Currently it allows  you to set the value to null
    #>
    [CmdletBinding()]
    param(
        [Alias('Name') ]
        [Parameter(Mandatory)]
        [string] $KeyName
    )
    "Clear-ResponseCache -Key '${KeyName}'" | Write-Verbose
    $cache = $Script:ResponseCache
    $cache.Remove( $KeyName ) # safe for missing keys
}
