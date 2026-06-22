function Set-ResponseCache {
    <#
    .SYNOPSIS
        (internal) Writes to shared response cache
    .NOTES
        Currently it allows  you to set the value to null
    #>
    param(
        [Alias('Name') ]
        [Parameter(Mandatory)]
        [string] $KeyName,

        # Only test, returns true if the key exists
        [Alias('Object')]
        $Value
    )
    $cache = $Script:ResponseCache
    $cache[ $keyName ] = $Value
}
