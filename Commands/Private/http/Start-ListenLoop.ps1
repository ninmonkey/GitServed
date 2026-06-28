#region Watch for events
function Start-ListenLoop {
    <#
    .synopsis
        (internal) Main HttpListener loop ( Called by Start-GitServe )
    #>
    [CmdletBinding()]
    param(
        [ValidateNotNull()]
        [Parameter(Mandatory)]
        [Net.HttpListener] $Listener,

        # log request debug info to the console
        [Alias('DebugInfo')]
        [switch] $PSHost
    )

    if( $null -eq $Listener ) {
        Write-Warning 'Start-ListenLoop: Listener is null!'
        # throw "Start-ListenLoop: Listener is Null"
        write-error "Start-ListenLoop: Listener is Null"
        return # test non-terminating
    }

    # While the listener is listening:
    while ($Listener.IsListening) {
        # Get every http* event
        foreach ($event in @(Get-Event HTTP*)) {
            [Management.Automation.PSEventArgs] $event = $event
            # Try to get the context, request, and response from the event
            $context, $request, $response = $event.SourceArgs

            # enable static completions using types
            [Net.HttpListenerContext] $context   = $context
            [Net.HttpListenerRequest] $request   = $request
            [Net.HttpListenerResponse] $response = $response

            # and if there is no output stream, continue
            if (-not $response.OutputStream) {
                continue
            }

            Set-CorsHeader -Request $request -Response $response -State $script:ModuleState

            if ($request.HttpMethod -eq 'OPTIONS' -and $request.Headers['Origin']) {
                $response.StatusCode = 204
                $response.Close()
                $event | Remove-Event
                continue
            }

            # If we haven't already, cache a pointer to possible routes.
            if (-not $script:PossibleRoutes) {
                # (in this case, we'll presume any command with a slash in it could be a route)
                $script:PossibleRoutes = $ExecutionContext.SessionState.InvokeCommand.GetCommands('*/*', 'Alias,Function', $true)
            }

            $mappedCommand = $null

            $schemeAndHostSegment = $request.Url.Scheme,
            '://',
            $request.Url.DnsSafeHost -join ''

            $portSegment =
            if ($request.Url.Port -notin '80', '443') {
                ':' + $request.Url.Port
            }

            # Now let's create a list of possible route names for this request, in the order we'd prefer them
            $possibleRouteNames = @(
                # $schemeAndHostSegment, $portSegment, $request.Url.LocalPath -join ''
                # $schemeAndHostSegment, $request.Url.LocalPath -join ''
                # "$schemeAndHostSegment/"
                # $schemeAndHostSegment
                $request.Url.LocalPath
                # For this example, we'll just use the local path.
                # (this will work for a single server, for multitenant hosting, you'd need to include the host)
            )

            if( $PSHost ) {
                '{0} {1} ' -f @(
                    $request.HttpMethod
                    $request.Url
                ) | Write-Host -ForegroundColor 'gray60'
            }

            # Now we'll loop through the possible route names
            foreach ($possibleRouteName in $possibleRouteNames ) {
                # and see if a command exists for that route
                $commandExists = @($script:PossibleRoutes -match "^$([Regex]::Escape($possibleRouteName))$")[0]
                if ($commandExists) {
                    $mappedCommand = $commandExists
                    break
                }
            }

            # If we've mapped a command
            if ($mappedCommand) {
                if( $PSHost ) {
                    'Mapped to {0}' -f $mappedCommand | Write-Host -ForegroundColor 'gray60'
                }
                # Run it, and capture all of the streams
                $cmdParams = @{
                    Request = $Request
                }

                [string] $requestCacheKey = $Request.Url.PathAndQuery
                $result = Get-ResponseCache -Key $requestCacheKey

                [string[]] $NeverCacheRouteNames = @(
                    '/cache/list', '/cache/request/clear', '/cache/clear'
                )

                $neverCacheResponse = $requestCacheKey -in $NeverCacheRouteNames
                if( $null -eq $result -or $neverCacheResponse ) {
                    if( $PSHost ) {
                        '    Cache key is stale: "{0}" ( neverCache: {1} )' -f @(
                            $requestCacheKey
                            $neverCacheResponse
                        ) | Write-Host -fg 'yellow'
                    }
                    # Cache is stale, so invoke the Url Route
                    $result = . $mappedCommand @cmdParams # *>&1

                    if( -not $neverCacheResponse ) {
                        Set-ResponseCache -Key $requestCacheKey -Value $result
                    }
                }

                # The result can tell us it is a content type by giving itself a content type as a type name
                $ContentTypePattern = '^(?>audio|application|font|image|message|model|text|video)/.+?'
                $resultIsContentType = @($result.pstypenames -match $ContentTypePattern)[0]
                # If the result was a content type
                if ($resultIsContentType) {
                    # set that header
                    $response.ContentType = $resultIsContentType
                }

                # If the result was a string
                if ($result -is [int] -and $result -ge 300 -and $result -lt 600) {
                    # set the status code
                    $response.StatusCode = $result
                    $response.Close()
                }
                elseif ($result -is [string]) {
                    # encode it using $OutputEncoding and close the response
                    $response.Close( $outputEncoding.GetBytes( $result ), $false ) # warning: assumes user set default non-ascii
                }
                # If the result was a byte[]
                elseif ($result -is [byte[]]) {
                    # respond with the bytes
                    $response.Close( $result, $false )
                }
                elseif ($result -is [IO.FileInfo]) {
                    # This block may want to be rewritten from old template
                    $BufferSize = 1mb
                    $serveFileJob = Start-ThreadJob -Name ($Request.Url -replace '^https?', 'file') -ScriptBlock {
                        param($result, $Request, $response, $BufferSize = 1mb)
                        if ($request.Method -eq 'HEAD') {
                            $response.ContentLength64 = $result.Length
                            $response.Close()
                            return
                        }

                        $response.Headers['Accept-Ranges'] = 'bytes'
                        $range = $request.Headers['Range']
                        $rangeStart, $rangeEnd = 0, 0
                        $fileStream = [IO.File]::OpenRead($result.Fullname)
                        if ($range) {
                            $null = $range -match 'bytes=(?<Start>\d{1,})(-(?<End>\d{1,})){0,1}'
                            $rangeStart, $rangeEnd = ($matches.Start -as [long]), ($matches.End -as [long])
                        }
                        if ($rangeStart -gt 0 -and $rangeEnd -gt 0) {
                            $buffer = [byte[]]::new($BufferSize)
                            $fileStream.Seek($rangeStart, 'Begin')
                            $bytesRead = $fileStream.Read($buffer, 0, $BufferSize)
                            $contentRange = "$RangeStart-$($RangeStart + $bytesRead - 1)/$($fileStream.Length)"

                            $response.StatusCode = 206
                            $response.ContentLength64 = $bytesRead
                            $response.Headers['Content-Range'] = $contentRange
                            $response.OutputStream.Write($buffer, 0, $bytesRead)
                            $response.OutputStream.Close()
                        }
                        else {
                            # if that stream has a content length
                            if ($result.ContentLength64 -gt 0) {
                                # set the content length
                                $response.ContentLength64 = $result.ContentLength64
                            }
                            # Then copy the stream to the response.
                            $fileStream.CopyTo($response.OutputStream)
                        }
                        $response.Close()
                        $fileStream.Close()
                        $fileStream.Dispose()
                    } -ThrottleLimit 100 -ArgumentList $result, $request, $response
                }
                else {
                    # otherwise, convert the result to JSON
                    # and set the content type to application/json if it is not already set
                    if (-not $response.ContentType) {
                        $response.ContentType = 'application/json'
                    }
                    $response.Close($outputEncoding.GetBytes((ConvertTo-Json -InputObject $result)), $false)
                }
                $duration = [DateTime]::Now - $event.TimeGenerated

                $elapsedText  = $duration.TotalMilliseconds.ToString('n0') + ' ms'
                $elapsedColor = ( $duration.TotalMilliseconds -gt 500 ) ? "${fg:red}" : ''

                Write-Host "Responded to $($request.Url) in ${duration} - ${elapsedColor}${elapsedText}" -ForegroundColor Cyan
                if( $PSHost ) {
                    @(
                        '    {0} {1} ' -f @(
                            $request.HttpMethod
                            $request.Url
                        )
                        '    Response: Status: {0}, ContentType: {1}' -f @(
                            $response.StatusDescription
                            $response.ContentType
                        )
                    )  | Write-Host -ForegroundColor Cyan

                }
            }
            else {
                $response.StatusCode = 404
                $response.ContentType = 'application/json'
                $body = @{
                    Error         = 'Endpoint not found'
                    RequestUrl    = $request.RawUrl
                    Query         = $request.QueryString
                    Method        = $request.HttpMethod
                    RequestHeader = $request.Headers
                } | ConvertTo-Json -Depth 3

                $buffer = [System.Text.Encoding]::UTF8.GetBytes( $body )
                $response.ContentLength64 = $buffer.Length
                $response.ContentEncoding = [System.Text.Encoding]::UTF8
                $response.OutputStream.Write( $buffer, 0, $buffer.Length )
                $response.Close()
            }
            $event | Remove-Event
        }
    }
}
#endregion Watch for events
