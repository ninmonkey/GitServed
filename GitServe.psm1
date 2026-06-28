<#
.Description
    Module built on: 2026-06-28 13:27:32Z
#>

#region Module.Before.ps1

Import-Module ugit

# Ensure http outputs default to utf8
$OutputEncoding = (
    [Console]::OutputEncoding = [Console]::InputEncoding =
    [System.Text.UTF8Encoding]::new( <# bool: encoderShouldEmitUTF8Identifier #> $false )
)

# Core config passed to ThreadJobs
$script:ModuleState = [hashtable]::Synchronized(@{
    HostName = $null
    Port = $null
    JobName = $null
    Using_CleanupOnRemoveEvent = $true
    CorsAllowOrigin = @('*')
    CorsAllowMethods = 'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD'
    CorsAllowHeaders = 'Content-Type, Authorization, X-Requested-With'
    CorsAllowCredentials = $false
})


# Core shared cache # nyi
$script:ResponseCache = [hashtable]::Synchronized(@{})


[Net.HttpListener] $script:Listener = [Net.HttpListener]::new()


#endregion Module.Before.ps1


#region Private Module Functions



function InvokeCli.Git.Log { # or FromDictionaryEntry
    <#
    .SYNOPSIS
        (internal) Invoke native git clone, and create folders based on the url: '/<root>/<owner>/<repo>'
    .DESCRIPTION
        ClonedRepoRoot - '/cloned-repos' will clone to '/cloned-repos/owner/repository'
    .EXAMPLE
        InvokeCli.Git.CloneRepo -CloneUrl 'https://github.com/owner/repo.git'
    .EXAMPLE
        # change root and print debug info
        InvokeCli.Git.CloneRepo -CloneUrl 'https://github.com/owner/repo.git' -Path '/cloned-repos' -PSHost -Verbose
    .LINK
        GitServe\Invoke-GitClone
    .LINK
        GitServe\GitServe.Clone
    #>
    [CmdletBinding()]
    param(
        [Alias('Url')]
        [Parameter(Mandatory)]
        [string] $CloneUrl,

        # root directory to clone under. '/cloned-repos' would clone to '/cloned-repos/owner/repository'
        [Alias('Path', 'PSPath')]
        [string] $ClonedRepoRoot,

        # Write to host
        [Alias('VerboseOutput')]
        [switch] $PSHost
    )

    $OriginalPath = Get-Item '.'
    if ( [String]::IsNullOrWhitespace( $ClonedRepoRoot ) ) {
        $ClonedRepoRoot = GetConfig.ClonedRepoRoot | Get-Item -ea 'stop'
        'Path: {0}' -f ( $ClonedRepoRoot ) | Write-Verbose
    }

    $uriPrefix, $OwnerName, $RepoName = $CloneUrl -split '/', -3
    $RepoName = $RepoName -replace '\.git$'

    <#
    example uri output values:
        > $cloneUrl = 'https://github.com/BurntSushi/ripgrep.git'
        > $uriPrefix, $OwnerName, $RepoName
        https://github.com, BurntSushi, ripgrep.git
    #>

    [ordered]@{ OwnerName = $OwnerName; RepoName = $RepoName; UriPrefix = $UriPrefix ; CloneUrl = $CloneUrl; ClonedRepoRoot = $ClonedRepoRoot }
        | ConvertTo-Json -Compress -depth 2
        | Write-Verbose

    if( [String]::IsNullOrWhiteSpace( $OwnerName ) ) {
        throw "OwnerName from the CloneUrl is blank!"
    }
    $OwnerRoot = Join-Path $ClonedRepoRoot $OwnerName
    if( -not ( Test-Path $OwnerRoot ) ) {
        $OwnerRoot = New-Item -ItemType Directory -Path $OwnerRoot -ea 'stop'
    }

    Set-Location -Path $OwnerRoot -ea 'stop' # note(threading): May need to remove provider use for threading

    # Run real git with args:
    #region Invoke Real Git Args
    $binGit = Get-Command -CommandType Application -Name 'git' -ea 'Stop' -TotalCount 1
    [Collections.Generic.List[object]] $gitArgs = @(
        'clone'
        $CloneUrl
        # $OwnerRoot # if not using provider, declare path
    )

        if( -not (Test-Path (Join-Path $OwnerRoot $OwnerName)) ) {
        $gitArgs
            | Join-String -sep ' ' -op 'Clone: invoke ''git'' => '
            | Write-Verbose

        $results = & $binGit @gitArgs
        if( $PSHost ) {
            $Results | Write-Host
        }
        # $results
    } else {
        if( $PSHost ) {
        "Directory '${ownerName}' already exists. Skipping clone."
            | Write-Host -fg 'Green'
        }
    }

    Set-Location -Path $OriginalPath
    #endregion Invoke Real Git Args
}

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

function GetConfig.ClonedRepoRoot {
    <#
    .synopsis
        (internal) Get app configuration for root directories to search ( ie: local, vs docker, etc )
    .DESCRIPTION
        Get root directories for cloned repos.
    #>
    [OutputType( [System.IO.DirectoryInfo[]] )]
    [CmdletBinding()]
    param(
        # Always return the first match. Default is to return all
        [Alias('LimitOne')]
        [switch] $FirstOnly
    )

    $potential = @( 'H:/RootClonedRepos', '/cloned-repos' )

    $rootPaths = @(
        $potential
        | Where-Object { Test-Path $_ } | Get-Item -ea ignore
    )

    if( $First ) {
        return $rootPaths | Select-Object -First 1
    }
    return $rootPaths
}

function GetConfig.Host {
    <#
    .synopsis
        (internal) Get app configuration for root directories to search ( ie: local, vs docker, etc )
    .description
    EnvVars have priority, else fall back to defaults.

        GITSERVE_PORT = 3001
        GITSERVE_HOST = 127.0.0.1 # or '*' when using docker

    .DESCRIPTION
        Get Url for Host, Port, Authority, etc
    #>

    [CmdletBinding()]
    param()

    $Port     = $Env:GITSERVE_PORT ?? 3001
    $HostName = $Env:GITSERVE_HOST ?? '127.0.0.1'
    $Url      = "http://${HostName}:${Port}"

    [pscustomobject]@{
        PSTypeName = 'GitServe.Config.Host'
        Host       = $HostName
        Port       = $Port
        Url        = $Url                    # ie: UriPartial::Authority
    }
}

function InvokeCli.Git.CloneRepo { # or FromDictionaryEntry
    <#
    .SYNOPSIS
        (internal) Invoke native git clone, and create folders based on the url: '/<root>/<owner>/<repo>'
    .DESCRIPTION
        ClonedRepoRoot - '/cloned-repos' will clone to '/cloned-repos/owner/repository'
    .EXAMPLE
        InvokeCli.Git.CloneRepo -CloneUrl 'https://github.com/owner/repo.git'
    .EXAMPLE
        # change root and print debug info
        InvokeCli.Git.CloneRepo -CloneUrl 'https://github.com/owner/repo.git' -Path '/cloned-repos' -PSHost -Verbose
    .LINK
        GitServe\Invoke-GitClone
    .LINK
        GitServe\GitServe.Clone
    #>
    [CmdletBinding()]
    param(
        [Alias('Url')]
        [Parameter(Mandatory)]
        [string] $CloneUrl,

        # root directory to clone under. '/cloned-repos' would clone to '/cloned-repos/owner/repository'
        [Alias('Path', 'PSPath')]
        [string] $ClonedRepoRoot,

        # Write to host
        [Alias('VerboseOutput')]
        [switch] $PSHost
    )

    $OriginalPath = Get-Item '.'
    if ( [String]::IsNullOrWhitespace( $ClonedRepoRoot ) ) {
        $ClonedRepoRoot = GetConfig.ClonedRepoRoot | Get-Item -ea 'stop'
        'Path: {0}' -f ( $ClonedRepoRoot ) | Write-Verbose
    }

    $uriPrefix, $OwnerName, $RepoName = $CloneUrl -split '/', -3
    $RepoName = $RepoName -replace '\.git$'

    <#
    example uri output values:
        > $cloneUrl = 'https://github.com/BurntSushi/ripgrep.git'
        > $uriPrefix, $OwnerName, $RepoName
        https://github.com, BurntSushi, ripgrep.git
    #>

    [ordered]@{ OwnerName = $OwnerName; RepoName = $RepoName; UriPrefix = $UriPrefix ; CloneUrl = $CloneUrl; ClonedRepoRoot = $ClonedRepoRoot }
        | ConvertTo-Json -Compress -depth 2
        | Write-Verbose

    if( [String]::IsNullOrWhiteSpace( $OwnerName ) ) {
        throw "OwnerName from the CloneUrl is blank!"
    }
    $OwnerRoot = Join-Path $ClonedRepoRoot $OwnerName
    if( -not ( Test-Path $OwnerRoot ) ) {
        $OwnerRoot = New-Item -ItemType Directory -Path $OwnerRoot -ea 'stop'
    }

    Set-Location -Path $OwnerRoot -ea 'stop' # note(threading): May need to remove provider use for threading

    # Run real git with args:
    #region Invoke Real Git Args
    $binGit = Get-Command -CommandType Application -Name 'git' -ea 'Stop' -TotalCount 1
    [Collections.Generic.List[object]] $gitArgs = @(
        'clone'
        $CloneUrl
        # $OwnerRoot # if not using provider, declare path
    )

        if( -not (Test-Path (Join-Path $OwnerRoot $OwnerName)) ) {
        $gitArgs
            | Join-String -sep ' ' -op 'Clone: invoke ''git'' => '
            | Write-Verbose

        $results = & $binGit @gitArgs
        if( $PSHost ) {
            $Results | Write-Host
        }
        # $results
    } else {
        if( $PSHost ) {
        "Directory '${ownerName}' already exists. Skipping clone."
            | Write-Host -fg 'Green'
        }
    }

    Set-Location -Path $OriginalPath
    #endregion Invoke Real Git Args
}

function OnRemoveModule_Handler {
    <#
    .synopsis
        Free resources when module unloads: Cleanup threads and HttpListeners
    .description
        Automatically called by event: '$ExecutionContext.SessionState.Module.OnRemove'
    #>
    "GitServe: OnRemove => Cleaning up HttpListener and ThreadJobs..." | Write-Host -Fore 'Yellow'
    Stop-GitServe
}

function New-HtmlTemplate {
    <#
    .SYNOPSIS
        Return a bare-bones html doc with the right charset
    #>
    param(
        [string] $Title = 'GitServe',

        [Alias('Content')]
        [string] $HtmlContent = '<h1>GitLogger</h1>'
    )
    [string] $template = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${Title}</title>
</head>
<body>
${HtmlContent}
</body>
</html>
"@
    $template -join [Environment]::NewLine
}

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

function Start-RouteThread {
    <#
    .SYNOPSIS
        (internal function) ThreadJOb[s] that map and run routes. ( Called by Start-GitServe )
    .NOTES
        The public entrypoint to call this is through 'Server-Start'
    #>
    param(
        [Parameter()] [Runspace] $Runspace, # can param binding to default cause threadsafe issues, ie: is evaluated once, or before other lifetimes?

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [Alias('Listener')]
        [Net.HttpListener] $CurListener,
        # [hashtable] $Query = [ordered]@{}, Request.Url ParsedQuery String
        # [hashtable] $JobParams = [ordered]@{},
        [int] $ThrottleLimit = 50
    )
    $state = $Script:ModuleState
    $JobName =  'GitServe http://{0}:{1}/' -f @(
        $state.HostName
        $state.Port
    )

    if( -not $Runspace ) {
        $Runspace = [Runspace]::DefaultRunspace
        'Start-RouteThread: using default Runspace' | Write-warning
    }

    # Now we start our server in a thread job.
    # This lets us get requests in a background thread, and turn them into events.
    Start-ThreadJob -ScriptBlock {
        param(
            [Runspace] $MainRunspace,

            [Net.HttpListener] $Listener,
            $ThreadParams,

            $eventId = 'http'
        )
        while ( $Listener.IsListening ) {
            [Threading.Tasks.Task[System.Net.HttpListenerContext]] $nextRequest = $Listener.GetContextAsync()

            # while (-not ( $nextRequest.IsCompleted -or $nextRequest.IsFaulted -or $nextRequest.IsCanceled )) {
            #     '.' | Write-Host -bg 'salmon' -NoNewline
            #     # no-op?
            # }
            if ($nextRequest.IsFaulted) {
                Write-Error -Exception $nextRequest.Exception -Category ProtocolError
                "NextRequest.IsFaulted" | Write-Host -bg orange
                continue
            }
            $context = $(
                try { $nextRequest.Result }
                catch {
                    $msg = $_  | Join-String -op 'Error on nextRequest.Result! {0}'
                    $msg | write-warning
                    $msg | Get-Error | Write-Host -fg 'gray50' -bg 'gray30'
                    $_.ToString()
                }
            )
            if ($context.Request.Url -match '/favicon.ico$') {
                $context.Response.StatusCode = 404
                $context.Response.Close()
                continue
            }
            'Events.Generate()'
                | write-Host -bg 'salmon' -fg 'black'

            $eventArgs = @(
                $context,
                $context.Request,
                $context.Response
            )

            $extraData =  [Ordered]@{
                Url      = $context.Request.Url
                Context  = $context
                Request  = $context.Request
                Response = $context.Response
            }

            $MainRunspace.Events.GenerateEvent(
                <# sourceIdentifier: #> $eventId,
                <# sender: #> $Listener,
                <# args: #> $eventArgs,
                <# extraData: #> $extraData )

            # see also: Alternate overload:
            #
            # $MainRunspace.Events.GenerateEvent(
            #     <# sourceIdentifier: #> $sourceIdentifier,
            #     <# sender: #> $sender,
            #     <# args: #> $args,
            #     <# extraData: #> $extraData,
            #     <# processInCurrentThread: #> $processInCurrentThread,
            #     <# waitForCompletionInCurrentThread: #> $waitForCompletionInCurrentThread)
            # #>
        }
    } -Name $JobName -ArgumentList ( $Runspace, $CurListener, $ThreadParams ) -ThrottleLimit $ThrottleLimit
        | Add-Member -NotePropertyMembers (
            [Ordered]@{
                HttpListener = $CurListener
            }
        ) -PassThru
}


#endregion Private Module Functions


#region Public Functions

function Metric-GitServeCommitCount {
    <#
    .SYNOPSIS
        Number of commits grouped and sorted by: "<Year>-<Month>_<GitUserName>" as text Descending
    .NOTES
        Expects input type: 'git.log'
    .EXAMPLE
        git log | Metric-CommitCount
    .EXAMPLE
        Use-Git -GitArg 'log', '-n', 4, '-C', $path | GitServe.Metric.CommitCount
    #>
    [Alias('GitServe.Metric.CommitCount')]
    [OutputType(
        '[System.Collections.Generic.SortedDictionary[string,object]]'
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [DateTime] $CommitDate,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $GitUserName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $GitUserEmail,

        # Input has 'ugit' properties like 'git.log'
        [Parameter(ValueFromPipeline)]
        [object] $InputObject
    )
    begin {
        function __toKeyId {
            # Generate a PrimaryKey. This determines distinct testing for records
            param( $Obj )
            '{0}_{1}' -f @(
                $Obj.CommitDate.ToString('yyyy-MM')
                $Obj.GitUserName
            )
        }
        $reverseComparer = [System.Collections.Generic.Comparer[string]]::Create({
            param($x, $y) [string]::Compare($y, $x)
        })
        [Collections.Generic.SortedDictionary[string,object]] $metric = $reverseComparer

        #//@{}
    }
    process {
        $key = __toKeyId $InputObject
        if( -not $metric.ContainsKey( $key ) ) {
            $initialValue = [pscustomobject][ordered]@{
                PSTYpeName  = 'GitServe.Metric.CommitCount'
                DateString  = $CommitDate.ToString('yyyy-MM')
                GitUserName = $GitUserName
                CommitCount = 1
                Year        = $CommitDate.Year
                Month       = $CommitDate.Month
                KeyId       = $key
                CommitDate  = $CommitDate
            }
            $metric[ $key ] = $initialValue
        } else {
            $metric[ $key ].CommitCount += 1
        }
    }
    end {
        ,@( $metric.Values )
    }
}

function Format-GitServeRelativePath {
    <#
    .synopsis
        Abbreviate a full path relative to another directory
    .example
        # Print paths relative the current Directory
        gci . -Depth 2 | Format-GitServeRelativePath
    .example
        > Get-Item 'c:\git\pwsh\SeeminglyScience'
            | Format-GitServeRelativePath 'c:\git'

        pwsh\SeeminglyScience
    #>
    [Alias('GitServe.Format-RelativePath')]
    [OutputType( [string] )]
    [CmdletBinding()]
    param(
        [Alias('BasePath')]
        [Parameter(Position = 0)]
        $RelativeTo = '.',

        # Strings / paths to convert
        [Alias('PSPath', 'FullName', 'InObj')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string[]] $Path,

        # Emit an object with path properties, including the raw original path
        [Alias('PassThru')]
        [switch] $AsObject
    )
    process {
        $RelativeTo = Get-Item $RelativeTo
        foreach( $item in ( $Path | Convert-Path ) ) {
            $relPath = [System.IO.Path]::GetRelativePath(
                <# string: relativeTo #> $RelativeTo,
                <# string: path #>  $Item )

            if( -not $AsObject ) {
                $relPath
                continue
            } else {
                [pscustomobject]@{
                    PSTypeName = 'GitServe.RelativePath'
                    Path       = $relPath
                    Original   = $Item
                    RelativeTo = $RelativeTo
                }
                continue
            }
        }
    }
}

# function Invoke-GitClone {
function Invoke-GitServeClone {
    <#
    .synopsis
        Clone a public git repo using the 'git' cli ( without using 'gh' )
    .example
        > GitServe.Git.Clone 'https://github.com/BurntSushi/ripgrep.git'
    #>
    [Alias(
        'GitServe.Git.Clone'
    )]
    [CmdletBinding( DefaultParameterSetName = 'CloneFromRawUrl' )]
    param(
        # Git url to clone
        [Parameter( ParameterSetName = 'CloneFromRawUrl', Position = 0, Mandatory )]
        [Alias( 'Repo', 'Clone', 'Url', 'GitUrl')]
        [ArgumentCompletions(
            'https://github.com/BurntSushi/ripgrep.git'
        )]
        [string] $CloneUrl, # ( string because not all valid git clone urls are valid,

        [string] $FromPath = '.'
    )
    end {
        "enter => '$( $MyInvocation.MyCommand.Name )'" | Write-Debug
        InvokeCli.Git.CloneRepo -CloneUrl $CloneUrl -FromPath $FromPath -PSHost:$True
    }
    # [pscustomobject]@{
    #     PSTypeName = 'GitServe.Git.Clone'
    #     CloneUrl = $CloneUrl
    #     Result = '<NYI>'
    # }
}

function Start-GitServe {
    <#
    .synopsis
        Start listen server
    .DESCRIPTION
        Main entry point for the user
    .notes
        - calls Stop-GitServe if listener is active
        - aliased as Start-GitServe, GitServe.Start
    .example
        # default uses random ports on localhost:
        > Start-GitServe
        # or as an alias:
        # GitServe.Start
    .example
        > GitServe.Start -Host $ip -Port $port
    .LINK
        Start-GitServe
    .LINK
        Stop-GitServe
    .LINK
        GitServe
    #>
    [Alias('GitServe.Start')]
    [CmdletBinding()]
    param(
        [ArgumentCompletions(
            "'127.0.0.1'", "'*'", "'localhost'" # "'0.0.0.0'", "'*'", "'localhost'"
        )]
        [Alias('Ip')]
        [Parameter(Position = 0)]
        [String] $HostName = '127.0.0.1',

        [Parameter()]
        [int] $Port,

        # set: State.CorsAllowOrigin
        [Parameter()]
        [string[]] $CorsAllowOrigin = @('*'),

        # set: State.CorsAllowMethods
        [Parameter()]
        [string] $CorsAllowMethods = 'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD',

        # set: State.CorsAllowHeaders
        [Parameter()]
        [string] $CorsAllowHeaders = 'Content-Type, Authorization, X-Requested-With',

        # set: State.CorsAllowCredentials
        [Parameter()]
        [switch] $CorsAllowCredentials,

        # log request debug info to the console
        [Alias('DebugInfo')]
        [switch] $PSHost
    )
    if( $Script:Listener.IsListening ) {
        Stop-GitServe
    }
    $state = $Script:ModuleState
    if( $null -eq $Script:Listener ) {
        $Script:Listener = [Net.HttpListener]::new()
    }
    [Net.HttpListener] $curListener = $Script:Listener ?? [Net.HttpListener]::new()


    if( -not $Port ) { $Port = Get-Random -Minimum 3000 -Maximum 4000 }
    $state.HostName = $HostName
    $state.Port = $Port
    $state.CorsAllowOrigin = @($CorsAllowOrigin)
    $state.CorsAllowMethods = $CorsAllowMethods
    $state.CorsAllowHeaders = $CorsAllowHeaders
    $state.CorsAllowCredentials = [bool] $CorsAllowCredentials
    $prefix = 'http://{0}:{1}/' -f @(
        $state.HostName
        $state.Port
    )
    if( $null -eq $curListener ) {
        throw "Listener was null!"
    }
    $curListener.Prefixes.Add( $prefix )

    # foreach( $curPrefix in $prefix ) {
    # }
    $curListener.Prefixes
        | Join-String -f '    add prefix {0}' | Write-Host -fg 'gray50'

    try {
        $curListener.Start()
    } catch [Net.HttpListenerException] {
        # if $_ -match 'failed to listen on prefix.*existing registration'
        'Error, is port in use?' | Write-Error -ErrorId 'Start-GitServe.PortInUse' -Category ResourceExists
        $Script:Listener = $null
        return
    }

    "$( (Get-Date).ToString('u')) GitServe: started listening on: http://$( $state.HostName ):$( $state.Port ))"
        | Write-Host

    "Start-GitServe: <ctrl+c> to stop server" | Write-Host -fg darkblue

    $startRouteThreadSplat = @{
        Runspace      = [runspace]::DefaultRunspace
        Listener      = $curListener
        ThrottleLimit = 50
    }

    Start-RouteThread @startRouteThreadSplat
        | Write-Debug

    $startListenLoopSplat = @{
        Listener = $Script:Listener
        PSHost = $PSHost
    }
    Start-ListenLoop @startListenLoopSplat
}

function Stop-GitServe {  # 'Stop-GitServeServer' sounded bad
    <#
    .synopsis
        Stop listen server. Dispose of HttpListener and ThreadJobs
    .example
        > GitServe Stop
    .LINK
        Start-GitServe
    .LINK
        Stop-GitServe
    .LINK
        GitServe
    .LINK
        https://learn.microsoft.com/en-us/dotnet/api/system.net.httplistener?view=net-10.0
    #>
    [Alias('GitServe.Stop')]
    [CmdletBinding()]
    param()

    [Net.HttpListener] $list = $Script:Listener
    # Close HttpListener first so route jobs unblock from GetContextAsync().
    if( $null -ne $List ) {
        if( $List.IsListening ) {
            "$( (Get-Date).ToString('u')) GitServe: Stopped listening" | Write-Host
            $List.Stop()
        }
        $List.Close()
        $Script:Listener = $null
    }

    Get-Job -State Completed | ? Name -match 'GitServe.*' | Remove-Job

    $threadJobs = @( Get-Job | Where-Object Name -Match 'GitServe.*' )
    if( $threadJobs.Count -gt 0 ) {
        $threadJobs.Name
            | Join-String -sep ', ' -SingleQuote -op 'GitServe Jobs: ' -os '. Stopping...'
            | Write-Warning

        $threadJobs | Stop-Job -ErrorAction Continue
        $threadJobs | Remove-Job -Force -ErrorAction Continue
    }
}

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

function /repo/clone {
    <#
    .SYNOPSIS
        Clone a repository to the docker volume
    .Description
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/Clone?url=https://github.com/BurntSushi/ripgrep.git'
    .NOTES
        Response is not explicitly cached
    #>
    [OutputType( 'GitServe.Route.Repo.Clone' )]
    param(
        [Net.HttpListenerRequest] $Request
    )

    $Request | ConvertTo-Json -depth 1 -wa ignore | Write-Debug

    $parsedQuery = [Web.HttpUtility]::ParseQueryString( $Request.Url.Query.ToLower() )
    [string] $gitUrl = @( $parsedQuery.GetValues('url') )[0]

    InvokeCli.Git.CloneRepo -Url $gitUrl -path (GetConfig.ClonedRepoRoot -First)
        | Write-Debug

    [pscustomobject]@{
        PSTypeName         = 'GitServe.Route.Repo.Clone'
        Query              = $request.Url.PathAndQuery
        CloneUrl           = $gitUrl
        # DebugRequest       = $Request
    }

}

function /repo/metric/commit {
    <#
    .SYNOPSIS
        Number of commits grouped and sorted by: "<Year>-<Month>_<GitUserName>" as text Descending
    .DESCRIPTION
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/metric/commit?repo=BurntSushi/ripgrep'
        irm 'http://127.0.0.1:3001/repo/metric/commit?url=microsoft/vscode-tmdl'
    .EXAMPLE
    .LINK
        GitServe\Metric-GitServeCommitCount
    #>
    [OutputType( 'GitServe.Route.Repo.Metric.Commit' )]
    [Alias('GitServe.Get-Log')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Net.HttpListenerRequest] $Request
    )
    $endpointLabel = '/repo/metric/commit'
    $parsedQuery = [Web.HttpUtility]::ParseQueryString( $Request.Url.Query.ToLower() )
    [string] $OwnerRepoPair = @( $parsedQuery.GetValues('url') )

    if ( [String]::IsNullOrWhitespace( $ClonedRepoRoot ) ) {
        $ClonedRepoRoot = GetConfig.ClonedRepoRoot | Get-Item -ea 'stop'
        'RootPath: {0}' -f ( $ClonedRepoRoot ) | Write-Verbose
    }
    $RepoPath = Join-Path $ClonedRepoRoot $OwnerRepoPair # todo(sanitization): use a better escape and match method
    if( ! ( Test-Path $RepoPath )) {
        "${endpointLabel} Error: Invalid OwnerRepoPair! '${OwnerRepoPair}'" | Write-Host -fore red
        throw "${endpointLabel} Error: Invalid OwnerRepoPair! '${OwnerRepoPair}'"
    }

    #region Invoke Git Args
    # $binGit = Get-Command -CommandType Application -Name 'git' -ea 'Stop' -TotalCount 1
    [Collections.Generic.List[object]] $gitArgs = @(
        'log'
        # '-n'
        # '100'
        '-C'
        $RepoPath
        # $OwnerRoot # if not using provider, declare path
    )

    $gitArgs
        | Join-String -sep ' ' -op 'Clone: invoke ''git'' => '
        | Write-Verbose

    try {
        $SelectProperty = 'CommitDate', 'GitUserName', 'Date', 'Scope', 'CommitType', 'Merged', 'CommitHash', 'Trailer', 'Trailers'
        # [object[]]
        $results = Use-git -GitArg $gitArgs
            | GitServe.Metric.CommitCount
            # | Select-Object -Property $SelectProperty
    } catch {
        "${endpointLabel} Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
            | Write-Host
        "${endpointLabel} Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
            | Write-Error
    }
    finally { }

    return $results
    #endregion Invoke Git Args
}

function / {
    # This demo will be a lot of randomly generated content, so we'll set a random refresh rate
    # variable context is shared between functions, so other animations can know the ideal timeframe to use.

    # The refresh interval is the only dynamic part of this page.
    # $Html = '<h1>Docker</h1><p>Now: {0}</p>' -f (  Get-Date )

    [string] $Html = "<h1 style='text-align:center'> Responded in $( ([DateTime]::Now - $event.TimeGenerated) )</h1>"
    New-HtmlTemplate -Title 'Index' -HtmlContent $Html
}

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
    ,@( $cache.GetEnumerator() | %{
        [pscustomobject][ordered]@{
            PSTypeName = 'GitServe.Route.Cache.List'
            Key        = $_.Key
            ValueType  = $_.Value | % GetType | % Name | Sort-Object -unique | Join-String -sep ', '
        }
    })
}

function /repo/list {
    <#
    .SYNOPSIS
        Return user's cloned repos. Cached.
    .description

    .NOTES
        Caches response to module variable 'Script:ResponseCache'
    #>
    [OutputType( 'GitServe.Route.Repo.List' )]
    param()

    $cacheKey = '/repo/list'

    $searchRoot = @( GetConfig.ClonedRepoRoot )
    $findGitRepos = Get-ChildItem $searchRoot -Filter '.git' -Directory -Force -Recurse | ForEach-Object Parent

    $records = @(
        foreach ($repoPath in $findGitRepos) {
            $absolutePath = $repoPath.FullName
            $remote = ( & git -C $absolutePath remote get-url origin 2>$null ) ?? '<empty-remote>'
            $commitCount = ( & git -C $absolutePath rev-list --count HEAD )
            $newestCommitRelative = ( & git -C $absolutePath log -1 --format=%cr )
            $newestCommitDateOnly = ( & git -C $absolutePath log -n 1 --format=%cd --date=format:'%Y-%m-%d' )
            $ownerPathName = $repoPath.FullName | Split-path -Parent | split-path  -Leaf

            [pscustomobject][ordered]@{
                PSTypeName           = 'GitServe.Route.Repo.List'
                CommitCount          = $commitCount
                Name                 = $repoPath.BaseName
                NewestCommitDate     = $newestCommitDateOnly
                NewestCommitRelative = $newestCommitRelative
                Owner                = $ownerPathName
                OwnerRepoPair            = '{0}/{1}' -f @( $ownerPathName, $repoPath.BaseName )
                Path                 = $repoPath.FullName
                Remote               = $remote
                # '( git remote get-url origin 2>$null | out-null ) ?? '<missing>''
            }
        }
    )
    return $records
}

function /repo/log {
    <#
    .SYNOPSIS
        Return git logs based on repo OwnerRepoPair '/<owner>/<repo>'
    .DESCRIPTION
    .EXAMPLE
        irm 'http://127.0.0.1:3001/repo/log?repo=BurntSushi/ripgrep'
    .EXAMPLE

    .EXAMPLE
    .LINK
        GitServe\Invoke-GitClone
    .LINK
        GitServe\GitServe.Clone
    #>

    [OutputType( 'GitServe.Route.Repo.Log' )]
    [Alias('GitServe.Get-Log')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Net.HttpListenerRequest] $Request

        # [Alias('Name', 'RepoName')]
        # [Parameter(Mandatory)]
        # [string] $OwnerRepoPair
    )
    $parsedQuery = [Web.HttpUtility]::ParseQueryString( $Request.Url.Query.ToLower() )
    [string] $OwnerRepoPair = @( $parsedQuery.GetValues('url') )
    $UsingUGit = $true

    if ( [String]::IsNullOrWhitespace( $ClonedRepoRoot ) ) {
        $ClonedRepoRoot = GetConfig.ClonedRepoRoot | Get-Item -ea 'stop'
        'RootPath: {0}' -f ( $ClonedRepoRoot ) | Write-Verbose
    }
    $RepoPath = Join-Path $ClonedRepoRoot $OwnerRepoPair # todo(sanitization): use a better escape and match method
    if( ! ( Test-Path $RepoPath )) {
        "/repo/log Error: Invalid OwnerRepoPair! '${OwnerRepoPair}'" | Write-Host -fore red
        throw "/repo/log Error: Invalid OwnerRepoPair! '${OwnerRepoPair}'"
    }
    # Run real git with args:
    #region Invoke Real Git Args
    $binGit = Get-Command -CommandType Application -Name 'git' -ea 'Stop' -TotalCount 1
    [Collections.Generic.List[object]] $gitArgs = @(
        '-C'
        $RepoPath
        'log'
        '-n'
        '100'
        # $OwnerRoot # if not using provider, declare path
    )

    $gitArgs
        | Join-String -sep ' ' -op 'Clone: invoke ''git'' => '
        | Write-Verbose

    if( $UsingUGit ) { #  use regular git or ugit
        # note: this is because ugit doesn't support '-C' flag (edit: does if last)
        try {
            Push-Location $RepoPath -ea 'stop' -StackName 'GitServe.Get-Log'
            $gitArgs =  @( 'log', '-n', '100' )
            $SelectProperty = 'CommitDate', 'GitUserName', 'Date', 'Scope', 'CommitType', 'Merged', 'CommitHash', 'Trailer', 'Trailers'


            $results = & 'Ugit\git' @gitArgs
                | Select-Object -Property $SelectProperty
        } catch {
            "/repo/log Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
                | Write-Host
            "/repo/log Error: Failed to get logs for '${OwnerRepoPair}' => $($_.Exception.Message)"
                | Write-Error
        }
        finally {
            Pop-Location -ea 'ignore' -StackName 'GitServe.Get-Log'
        }
        return $results
    }

    # regular git
    $results = & $binGit @gitArgs

    <#
    $parsedQuery = [Web.HttpUtility]::ParseQueryString( $Request.Url.Query.ToLower() )
    [string] $gitUrl = @( $parsedQuery.GetValues('url') )[0]

    InvokeCli.Git.CloneRepo -Url $gitUrl -path (GetConfig.ClonedRepoRoot -First)
        | Write-Debug

    [pscustomobject]@{
        PSTypeName         = 'GitServe.Route.Repo.Clone'
        Query              = $request.Url.PathAndQuery
        CloneUrl           = $gitUrl
        # DebugRequest       = $Request
    }
    #>
    $results
    #endregion Invoke Real Git Args
}


#endregion Public Functions


#region Module.After.ps1

# Use Module Removed Event for Cleanup
# This could be turned into a "common module filename" at '/Private/Module.OnRemoveModule.ps1'

if( $ModuleState.Using_CleanupOnRemoveEvent ) {
    $ExecutionContext.SessionState.Module.OnRemove = {
        OnRemoveModule_Handler
    }
}


#endregion Module.After.ps1

