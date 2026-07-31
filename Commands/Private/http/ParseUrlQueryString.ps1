function ParseQueryString {
    <#
    .SYNOPSIS
        (internal) Parse request query strings. returns the named value collection
    .NOTES
        Currently not throwing via parameterbinding
    #>
    [OutputType(
        [System.Collections.Specialized.NameValueCollection]
    )]
    [CmdletBinding()]
    param(
        # From an HttpListener
        [Alias('HttpListener' )]
        [Parameter(
            ParameterSetName = 'FromListener',
            ValueFromPipeline
        )]
        [Net.HttpListenerRequest] $Listener,

        # from a raw Url. No server.
        [Alias('RequestUrl')]
        [Parameter(
            ParameterSetName = 'FromUrl',
            ValueFromPipeline
        )]
        [Uri] $Url
    )

    begin { }
    process {
        if ( -not $Listener -and -not $Url ) {
            throw "ParseQueryString: Blank Url/ListenerRequest!"
        }

        if( $null -ne $Listener ) {
            [Collections.Specialized.NameValueCollection] $keyCollection =
                [Web.HttpUtility]::ParseQueryString( $Listener.Url.Query.ToLower() )

            return $keyCollection
        }


        # otherwise it's a non-blank url
        [Collections.Specialized.NameValueCollection] $keyCollection =
                [Web.HttpUtility]::ParseQueryString( $Url.Query.toLower() )
        return $keyCollection

    }
    end {
    }
}
