function Start-RouteThread {
    <#
    .SYNOPSIS
        (internal function) ThreadJOb[s] that map and run routes
    #>
    param(
        [Parameter()] [Runspace] $RunSpace = ([Runspace]::DefaultRunspace), # can param binding to default cause threadsafe issues, ie: is evaluated once, or before other lifetimes?
        [Net.HttpListener] $Listener = $Null,
        # [hashtable] $Query = [ordered]@{}, Request.Url ParsedQuery String
        [hashtable] $Params = [ordered]@{},
        [int] $ThrottleLimit = 50

    )
    # Now we start our server in a thread job.
    # This lets us get requests in a background thread, and turn them into events.
    Start-ThreadJob -ScriptBlock {
        param( $MainRunspace, $Listener, $Params, $eventId = 'http')
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
    } -Name $JobName -ArgumentList ( $MainRunspace, $Listener, $Params ) -ThrottleLimit $ThrottleLimit
        | Add-Member -NotePropertyMembers ([Ordered]@{HttpListener = $Listener }) -PassThru
}
