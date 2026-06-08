function Start-GitServe {  # 'Start-GitServeServer' sounded bad
    <#
    .synopsis
        Start listen server
    .DESCRIPTION
    .notes
        - calls Stop-GitServe if listener is active
        - aliased as Start-GitServe, GitServe.Start
    .example
        # random ports
        > GitServe Start

    .example
        > GitServe Start -Host ip -Port port
    Maybe allow:
        > GitServe Start ip:port
        > GitServe Start port
    .LINK
        Start-GitServe
    .LINK
        Stop-GitServe
    .LINK
        GitServe
    #>
    [Alias('GitServe.Start')]
    # [OutputType( [string] )]
    [CmdletBinding()]
    param(
        [ArgumentCompletions(
            "'127.0.0.1'", "'*'", "'localhost'" # "'0.0.0.0'", "'*'", "'localhost'"
        )]
        [Alias('Ip')]
        [Parameter(Position = 0)]
        [String] $HostName = '127.0.0.1',

        [Parameter()]
        [int] $Port
    )
    $state = $Script:ModuleState

    [Net.HttpListener] $curListen = $Script:Listener ?? [Net.HttpListener]::new()
    if( $curListen.IsListening ) {
        '😡 curListen.IsListening' | Write-host -fg 'orange'
        "[w] $( (Get-Date).ToString('u')) GitServe: Stopped listening" | Write-Warning
        $curListen.Close()
        $curListen = $Null
        Stop-GitServe
        $curListen = [Net.HttpListener]::new()
    }
    if( -not $Port ) { $Port = Get-Random -Minimum 3000 -Maximum 4000 }
    $state.HostName = $HostName
    $state.Port = $Port
    $prefix = 'http://{0}:{1}/' -f @(
        $state.HostName
        $state.Port
    )
    $prefix | join-string -op 'Prefix: ' | Write-host -bg 'orange'
    if( $null -eq $curListen ) {
        throw "Listener was null!"
    }
    if($null -eq $curListen ) {
        "👽 Start => Can't add prefix if listen is null" | Write-warning
        return
    }
    $curListen.Prefixes.Add( $prefix )

    # foreach( $curPrefix in $prefix ) {
    # }
    $curListen.Prefixes
        | Join-String -f '    add prefix {0}' | Write-Host -fg 'gray50'


    # try {
        $curListen.Start()
    # } catch [Net.HttpListenerException] {
    #     # if $_ -match 'failed to listen on prefix.*existing registration'
    #     'Error, is port in use?' | Write-Error -ErrorId 'Start-GitServe.PortInUse' -Category ResourceExists
    #     $Script:Listener = $null
    #     return
    # }

    "$( (Get-Date).ToString('u')) GitServe: started listening on: http://$( $state.HostName ):$( $state.Port ))"
        | Write-Host

    "Next: Start-RouteThread; Start-ListenLoop" | Write-Host -fg salmon

    # $startRouteThreadSplat = @{
    #     Runspace      = [runspace]::DefaultRunspace
    #     Listener      = $curListen
    #     ThrottleLimit = 50
    # }
    '🟢 before : Start-ThreadJob' | Write-Host -fg 'salmon'

    $JobName =  'GitServe http://{0}:{1}/' -f @(
        $state.HostName
        $state.Port
    )


    # Start-RouteThread -RunSpace ([Runspace]::DefaultRunspace) -Listener $curListen
    Start-ThreadJob -ScriptBlock {
        param($MainRunspace, $Listener, $PwshWebConfig, $eventId = 'http')
        while ( $Listener.IsListening ) {
            $nextRequest = $Listener.GetContextAsync()
            while (-not ( $nextRequest.IsCompleted -or $nextRequest.IsFaulted -or $nextRequest.IsCanceled )) {

            }
            if ($nextRequest.IsFaulted) {
                Write-Error -Exception $nextRequest.Exception -Category ProtocolError
                continue
            }
            $context = $(try { $nextRequest.Result } catch { $_ })
            if ($context.Request.Url -match '/favicon.ico$') {
                $context.Response.StatusCode = 404
                $context.Response.Close()
                continue
            }
            $MainRunspace.Events.GenerateEvent(
                $eventId, $Listener, @( $context, $context.Request, $context.Response ),
                [Ordered]@{
                    Url      = $context.Request.Url
                    Context  = $context
                    Request  = $context.Request
                    Response = $context.Response
                }
            )
        }
    } -Name $JobName -ArgumentList ([Runspace]::DefaultRunspace, $CurListener ) -ThrottleLimit 50
        # | Add-Member -NotePropertyMembers ([Ordered]@{HttpListener = $Listener }) -PassThru
        # | Add-Member -NotePropertyMembers ([Ordered]@{HttpListener = $CurListener }) -PassThru


    '🟢 after  : Start-ThreadJob' | Write-Host -fg 'salmon'
    '🟢 before  : while event blocking loop' | Write-Host -fg 'salmon'


    #region Watch for events
    # While the listener is listening:
    while ($Listener.IsListening) {
        # Get every http* event
        foreach ($event in @(Get-Event HTTP*)) {
            # Try to get the context, request, and response from the event
            $context, $request, $response = $event.SourceArgs
            # and if there is no output stream, continue
            if (-not $response.OutputStream) {
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
                # Run it, and capture all of the streams
                $result = . $mappedCommand $request *>&1

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
                    $response.Close( $outputEncoding.GetBytes( $result ), $false )
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
            Write-Host "Responded to $($request.Url) in $([DateTime]::Now - $event.TimeGenerated)" -ForegroundColor Cyan
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
#endregion Watch for events



    '🟢 after   : while event blocking loop' | Write-Host -fg 'salmon'


    '🟢 done' | Write-Host -fg 'salmon'
}
