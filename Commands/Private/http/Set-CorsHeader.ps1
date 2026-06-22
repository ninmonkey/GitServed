function Set-CorsHeader {
    <#
    .SYNOPSIS
        (internal) Set CORS headers
    #>
    param(
        [Parameter(Mandatory)] [Net.HttpListenerRequest] $Request,
        [Parameter(Mandatory)] [Net.HttpListenerResponse] $Response,
        [Parameter(Mandatory)] [hashtable] $State
    )

    [string[]] $allowOrigins = @($State.CorsAllowOrigin)
    if (-not $allowOrigins -or $allowOrigins.Count -eq 0) {
        $allowOrigins = @('*')
    }

    $origin = $Request.Headers['Origin']
    $allowOriginHeader = $null

    if ($allowOrigins -contains '*') {
        if ($State.CorsAllowCredentials -and $origin) {
            $allowOriginHeader = $origin
        }
        else {
            $allowOriginHeader = '*'
        }
    }
    elseif ($origin -and ($allowOrigins -contains $origin)) {
        $allowOriginHeader = $origin
    }

    if ($allowOriginHeader) {
        $Response.Headers['Access-Control-Allow-Origin'] = $allowOriginHeader
    }

    if ($origin -and $allowOriginHeader -and $allowOriginHeader -ne '*') {
        $Response.Headers['Vary'] = 'Origin'
    }

    if ($State.CorsAllowCredentials -and $allowOriginHeader -and $allowOriginHeader -ne '*') {
        $Response.Headers['Access-Control-Allow-Credentials'] = 'true'
    }

    if ($State.CorsAllowMethods) {
        $Response.Headers['Access-Control-Allow-Methods'] = $State.CorsAllowMethods
    }

    $requestHeaders = $Request.Headers['Access-Control-Request-Headers']
    if ($requestHeaders) {
        $Response.Headers['Access-Control-Allow-Headers'] = $requestHeaders
    }
    elseif ($State.CorsAllowHeaders) {
        $Response.Headers['Access-Control-Allow-Headers'] = $State.CorsAllowHeaders
    }
}
