function / {
    # This demo will be a lot of randomly generated content, so we'll set a random refresh rate
    # variable context is shared between functions, so other animations can know the ideal timeframe to use.

    # The refresh interval is the only dynamic part of this page.
    # $Html = '<h1>Docker</h1><p>Now: {0}</p>' -f (  Get-Date )

    [string] $Html = "<h1 style='text-align:center'> Responded in $( ([DateTime]::Now - $event.TimeGenerated) )</h1>"
    New-HtmlTemplate -Title 'Index' -HtmlContent $Html
}
