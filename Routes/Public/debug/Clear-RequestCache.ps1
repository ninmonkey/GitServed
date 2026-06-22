function /cache/clear {
    <#
    .synopsis
        Clear all caches
    #>
    [OutputType( 'GitServe.Route.Debug.ClearCache' )]
    param()

    /cache/request/clear
}
function /cache/request/clear {
    <#
    .SYNOPSIS
        Debug. Clears RequestCache
    .description
        Clears module variable 'Script:ResponseCache'
    #>
    [OutputType( 'GitServe.Route.Debug.ClearCache' )]
    param()

    $cache = $Script:ResponseCache
    'Removing {0} keys' -f ( $cache.Keys.count ) | Write-Host -fore Cyan
    $cache.clear()

    [pscustomobject][ordered]@{
        PSTypeName = 'GitServe.Route.Debug.ClearCache'
        Message    = 'RequestCache cleared'
        Now        = [Datetime]::Now
    }
}
