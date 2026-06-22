function Get-ResponseCache {
    <#
    .SYNOPSIS
        (internal) Read shared response cache
    #>
    param(
        # Missing keys will return null
        [Alias('Name', 'Key' ) ]
        [Parameter(Mandatory)]
        [string] $KeyName,

        # Only test, returns true if the key exists
        [Alias('TestOnly')]
        [bool] $HasKey
    )
    $cache = $Script:ResponseCache

    $exists = $cache.ContainsKey( $KeyName )
    if( $HasKey ) {
        return $exists
    }

    return $cache[ $KeyName ]
}
