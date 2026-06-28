function /cache/list {
    <#
    .SYNOPSIS
        Debug. Displays metadata on cached responses
    .description
        Basic info on the state of '$Script:ResponseCache'
    #>
    [OutputType( 'GitServe.Route.Cache.List' )]
    param()
    $cache = $Script:ResponseCache
    $cache.GetEnumerator() | %{
        [pscustomobject][ordered]@{
            PSTypeName = 'GitServe.Route.Cache.List'
            Key        = $_.Key
            ValueType  = $_.Value | % GetType | % Name | Sort-Object -unique | Join-String -sep ', '
        }
    }
}
