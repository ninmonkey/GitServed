<#
.Description
    Module built on: 2026-06-08 10:57:25Z
#>

#region Module.Before.ps1

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
})

[Net.HttpListener] $script:Listener = [Net.HttpListener]::new()


#endregion Module.Before.ps1


#region Private Module Functions

function _InvokeCli.Git.CloneRepo { # or FromDictionaryEntry
    <#
    .SYNOPSIS
        private invoke cloning git command
    .DESCRIPTION
    .EXAMPLE
    .LINK
        GitServe\Invoke-GitClone
    #>
    # [CmdletBinding()]
    # [Alias('_Cli.Git.Clone')]
    param(
        [Parameter(Mandatory)]
        [string] $CloneUrl,

        # CWD to clone from
        [Alias('GitCwd')]
        [string] $FromPath = '.',

        [Alias('VerboseOutput')]
        [switch] $PSHost
    )

    $CdStackName    = 'cli.git-clone'

    $uriPrefix, $OwnerName, $RepoName = $CloneUrl -split '/', -3
    $RepoName = $RepoName -replace '\.git$'

    <#
    example uri output values:
        > $cloneUrl = 'https://github.com/BurntSushi/ripgrep.git'
        > $uriPrefix, $OwnerName, $RepoName
        https://github.com, BurntSushi, ripgrep.git
    #>


    [ordered]@{ OwnerName = $OwnerName; RepoName = $RepoName; UriPrefix = $UriPrefix ; CloneUrl = $CloneUrl }
        | ConvertTo-Json -Compress -depth 2
        | Write-Verbose

    if( [String]::IsNullOrWhiteSpace( $OwnerName ) ) {
        throw "OwnerName from the CloneUrl is blank!"
    }

    Push-Location -Stack $CdStackName $FromPath

    # Run real git with args:
    #region Invoke Real Git Args
    $binGit = Get-Command -CommandType Application -Name 'git' -ea 'Stop' -TotalCount 1
    [Collections.Generic.List[object]] $gitArgs = @(
        'clone'
        $CloneUrl
    )

    if( -not (Test-Path (Join-Path $FromPath $ownerName)) ) {
        $gitArgs
            | Join-String -sep ' ' -op 'Clone: invoke ''git'' => '
            | Write-Host -fg 'gray60'

        $results = & $binGit @gitArgs
        if( $PSHost ) {
            $Results
        }
        # $results
    } else {
        "Directory '${ownerName}' already exists. Skipping clone."
            | Write-Host -fg 'Green'
    }

    Pop-Location -Stack $cdStackName # -ea Ignore

    #endregion Invoke Real Git Args
}

function OnRemoveModule_Handler { # or "Module.OnRemove" ?
    <#
    .synopsis
        Autocleanup module when module is unloaded
    .notes
        Could be named func 'Module.OnRemove' ?
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

function / {
    # This demo will be a lot of randomly generated content, so we'll set a random refresh rate
    # variable context is shared between functions, so other animations can know the ideal timeframe to use.

    # The refresh interval is the only dynamic part of this page.
    # $Html = '<h1>Docker</h1><p>Now: {0}</p>' -f (  Get-Date )

    [string] $Html = "<h1 style='text-align:center'> Responded in $( ([DateTime]::Now - $event.TimeGenerated) )</h1>"
    New-HtmlTemplate -Title 'Index' -HtmlContent $Html
}

#region Watch for events
function Start-ListenLoop {
    [CmdletBinding()]
    param(
        [ValidateNotNull()]
        [Parameter(Mandatory)]
        [Net.HttpListener] $Listener
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
}
#endregion Watch for events


#endregion Private Module Functions


#region Public Functions

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
        _InvokeCli.Git.CloneRepo -CloneUrl $CloneUrl -FromPath $FromPath -PSHost:$True
    }
    # [pscustomobject]@{
    #     PSTypeName = 'GitServe.Git.Clone'
    #     CloneUrl = $CloneUrl
    #     Result = '<NYI>'
    # }
}

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
    $prefix = 'http://{0}:{1}/' -f @(
        $state.HostName
        $state.Port
    )
    $prefix | join-string -op 'Prefix: ' | Write-host -bg 'orange'
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

    "Next: Start-RouteThread; Start-ListenLoop" | Write-Host -fg salmon

    $startRouteThreadSplat = @{
        Runspace      = [runspace]::DefaultRunspace
        Listener      = $curListener
        ThrottleLimit = 50
    }

    Start-RouteThread @startRouteThreadSplat

    $startListenLoopSplat = @{
        Listener = $Script:Listener
    }

    "before => startListenLoop" | Write-Host -fg 'yellow'
    Start-ListenLoop @startListenLoopSplat
    "after  => startListenLoop" | Write-Host -fg 'yellow'

    #   [Parameter()] [Runspace] $RunSpace = ([Runspace]::DefaultRunspace), # can param binding to default cause threadsafe issues, ie: is evaluated once, or before other lifetimes?
    #     [Net.HttpListener] $Listener = $Null,
    #     # [hashtable] $Query = [ordered]@{}, Request.Url ParsedQuery String
    #     # [hashtable] $JobParams = [ordered]@{},
        # [int] $ThrottleLimit = 50
}

function Start-GitServeMin {  # 'Start-GitServeServer' sounded bad
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
    [Alias('GitServe.StartMin')]
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
    '🟢 before : Start-RouteThread' | Write-Host -fg 'salmon'
    Start-RouteThread -RunSpace ([Runspace]::DefaultRunspace) -Listener $curListen
    '🟢 after  : Start-RouteThread' | Write-Host -fg 'salmon'

    '🟢 done' | Write-Host -fg 'salmon'
    if( $curListen.IsListening ) { $curListen.close() }
    Stop-GitServe

    # Start-RouteThread @startRouteThreadSplat

    # $startListenLoopSplat = @{
    #     Listener = $Script:Listener
    # }

    # "before => startListenLoop" | Write-Host -fg 'yellow'
    # Start-ListenLoop @startListenLoopSplat
    # "after  => startListenLoop" | Write-Host -fg 'yellow'

    #   [Parameter()] [Runspace] $RunSpace = ([Runspace]::DefaultRunspace), # can param binding to default cause threadsafe issues, ie: is evaluated once, or before other lifetimes?
    #     [Net.HttpListener] $Listener = $Null,
    #     # [hashtable] $Query = [ordered]@{}, Request.Url ParsedQuery String
    #     # [hashtable] $JobParams = [ordered]@{},
        # [int] $ThrottleLimit = 50
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
    param( )

    [Net.HttpListener] $list = $Script:Listener
    # 1] Stop ThreadJobs
    # 2] Stop, Close, and null HttpListener
    $threadJobs = Get-Job | ? Name -Match 'GitServe.*'
    if( $threadJobs.Count -gt 0 ) {
        $threadJobs.Name
            | Join-String -sep ', ' -SingleQuote -op 'GitServe Jobs already running: ' -os '. Stopping...'
            | Write-Warning
    }

    # I thought I'd want to exit jobs then close the listener? testing the inverse.
    if( $List.IsListening ) {
        "[w] $( (Get-Date).ToString('u')) GitServe: Stopped listening" | Write-Warning
        $List.Close()
        $list = $Null
    }
    # # old method:
    # $threadJobs | Stop-Job -PassThru | Receive-Job -AutoRemoveJob -Wait

    # Force stop jobs immediately, don't wait for output
    if ($threadJobs.Count -gt 0) {
        return
        $threadJobs | Stop-Job -Force -Confirm:$false -ErrorAction Continue
        Start-Sleep -Milliseconds 250
        # Forcefully remove any remaining jobs
        Get-Job | Where-Object Name -Match 'GitServe.*' | Remove-Job -Force -Confirm:$false -ErrorAction Continue
    }

}

function Start-RouteThread {
    <#
    .SYNOPSIS
        (internal function) ThreadJOb[s] that map and run routes
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

