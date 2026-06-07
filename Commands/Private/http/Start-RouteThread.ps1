function Start-RouteThread {
    <#
    .SYNOPSIS
        (internal function) ThreadJOb[s] that map and run routes
    #>
    param(
        [Parameter()] [Runspace] $RunSpace = ([Runspace]::DefaultRunspace), # can param binding to default cause threadsafe issues, ie: is evaluated once, or before other lifetimes?
        [Net.HttpListener] $Listener = $Null,
        # [hashtable] $Query = [ordered]@{}, Request.Url ParsedQuery String
        # [hashtable] $JobParams = [ordered]@{},
        [int] $ThrottleLimit = 50
    )
    $state = $Script:Module
    $JobName =  'GitServe http://{0}:{1}/' -f @(
        $state.HostName
        $state.Port
    )

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
            $nextRequest = $Listener.GetContextAsync()

            while (-not ( $nextRequest.IsCompleted -or $nextRequest.IsFaulted -or $nextRequest.IsCanceled )) {
                # no-op?
            }
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
    } -Name $JobName -ArgumentList ( $MainRunspace, $Listener, $ThreadParams ) -ThrottleLimit $ThrottleLimit
        | Add-Member -NotePropertyMembers (
            [Ordered]@{
                HttpListener = $Listener
            }
        ) -PassThru
}
