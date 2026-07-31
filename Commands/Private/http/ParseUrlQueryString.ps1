
function Convert-GitServeQueryString {
    <#
    .SYNOPSIS
        (internal) Parse request query strings. returns the named value collection
    .NOTES
        You can pass a raw Url or an HttpListenerRequest instance
        This does not use [ValueFromPipelineByPropertyName]
    #>
    [Alias(
        'ParseQueryString',
        'GitServe.Convert.RequestQueryString'
    )]
    [OutputType(
        [System.Collections.Specialized.NameValueCollection]
    )]
    [CmdletBinding()]
    param(
        # a raw Url or from an HttpListenerRequest instance
        [Alias( 'HttpListenerRequest', 'Request', 'Listener', 'RawUrl', 'Url' )]
        [Parameter(Mandatory, ValueFromPipeline )]
        [object] $ListenerOrUrl
    )

    begin { }
    process {
        if ( $null -eq $ListenerOrUrl ) {
            throw "ParseQueryString: Blank Url/ListenerRequest!"
        }

        if( $ListenerOrUrl -is [System.Net.HttpListenerRequest] ) {
            [System.Net.HttpListenerRequest] $Listener = $ListenerOrUrl
            [Collections.Specialized.NameValueCollection] $keyCollection =
                [Web.HttpUtility]::ParseQueryString( $Listener.Url.Query.ToLower() )

            return $keyCollection
        }

        if( $ListenerOrUrl -is [System.Uri]) {
            [System.Uri] $Url = $ListenerOrUrl
            [Collections.Specialized.NameValueCollection] $keyCollection =
                [Web.HttpUtility]::ParseQueryString( $Url.Query.ToLower() )

            return $keyCollection
        }

        throw "Unhandled Object type! $( ( $ListenerOrUrl )?.GetType() ) "    }
    end {
    }
}
