# "enter => '$( $MyInvocation.MyCommand.Name )'" | Write-Host

# # log env vars and configuration
# Get-ChildItem env:\
#     | ? Name -in 'PWSH_PORT', 'PWSH_HOST'
#     | Join-String { "$( $_.Key ) = $( $_.Value )" } -op 'Env Vars: ' -sep ', '
#     | write-host


# "server-routing.ps1 => Host: ${HostName}, Port: ${PortNumber}, Start: $( Get-Date )" | Write-Host


# if( $Listener.isListening -or $null -ne $Listener -or $null -ne $JobName ) {
#     # cleanup if previous invocation is still
#     $toDot = Get-Item -ea stop ( Join-Path $PSScriptRoot 'server-stop.ps1' )
#     . $toDot
# }
# # Step 1: Create a server:
# #region Event Server

# # We're going to create a job on a random port
# # $JobName = "http://localhost:$(Get-Random -Min 4200 -Max 42000)/"

# $JobName = "http://${HostName}:${PortNumber}/"
# $Listener = [Net.HttpListener]::new()
# $Listener.Prefixes.Add($JobName)
# $Listener.Start()

# "Job Name: ${JobName}" | Write-Host

# # Now we start our server in a thread job.
# # This lets us get requests in a background thread, and turn them into events.
# Start-ThreadJob -ScriptBlock {
#     param($MainRunspace, $Listener, $eventId = 'http')
#     while ($Listener.IsListening) {
#         $nextRequest = $Listener.GetContextAsync()
#         while (-not ($nextRequest.IsCompleted -or $nextRequest.IsFaulted -or $nextRequest.IsCanceled)) {

#         }
#         if ($nextRequest.IsFaulted) {
#             Write-Error -Exception $nextRequest.Exception -Category ProtocolError
#             continue
#         }
#         $context = $(try { $nextRequest.Result } catch { $_ })
#         if ($context.Request.Url -match '/favicon.ico$') {
#             $context.Response.StatusCode = 404
#             $context.Response.Close()
#             continue
#         }
#         $MainRunspace.Events.GenerateEvent(
#             $eventId, $Listener, @($context, $context.Request, $context.Response),
#             [Ordered]@{Url = $context.Request.Url;Context = $context;Request = $context.Request;Response = $context.Response}
#         )
#     }
# } -Name $JobName -ArgumentList ([Runspace]::DefaultRunspace, $Listener) -ThrottleLimit 50 |
#     Add-Member -NotePropertyMembers ([Ordered]@{HttpListener = $Listener}) -PassThru

# Write-Host "Now Serving @ $jobName" -ForegroundColor Green
# #endregion Event Server

# #region Server functions

# # Step 2: Define the functions that serve our website

# #region Root
# function / {
#     # This demo will be a lot of randomly generated content, so we'll set a random refresh rate
#     # variable context is shared between functions, so other animations can know the ideal timeframe to use.

#     # The refresh interval is the only dynamic part of this page.
#     $RefreshIn = $(Get-Random -Min 1kb -Max 2kb)
#     @(
#     "<html>","<head>"
#     "<title>There is no route table</title>"
#     "<link rel='stylesheet' href='/css' />" # link to a dynamically generated CSS file.
#     '<meta name="viewport" content="width=device-width, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0">'
#     "<script>setTimeout(() => { window.location.reload() }, $RefreshIn )</script>"
#     "</head>","<body>"
#     "<h1 style='text-align:center'> Responded in $(([DateTime]::Now - $event.TimeGenerated))</h1>"
#     "<h2 style='text-align:center'> Switching in $([TimeSpan]::FromMilliseconds($refreshIn))</h2>"
#     "<div style='text-align:center'>
#     <img src='/svg' width='25%' style='align:center' />
#     <iframe height='25%' width='100%' src='/3D' frameBorder='0' scrolling='no'></iframe>
#     </div>"
#     "</body>","</html>"
#     ) -join [Environment]::NewLine
# }

# function /HelloWorld { "Hello World" }
# function /RandomNumber { Get-Random }
# Set-Alias /RNG /RandomNumber
# function /RequestInfo { $request }

# function /myProc { Get-Process -Id $pid | Select-Object Name, Id, Path, StartTime }
# Set-Alias /MyProcess /myProc
# function /CSS {
#     # Pick a random background color
#     $bgColor = Get-Random -Max 0xffffff
#     # and xor it with white to get a contrasting foreground color
#     $fgColor = $bgColor -bxor 0xffffff
#     # make them into hex strings
#     $randomBackground = "#{0:x6}" -f $bgColor
#     $randomColor = "#{0:x6}" -f $fgColor

#     # Declare a little filter to make things CSS
#     filter toCss {
#         $cssString =
#             @(if ($_ -is [string]) {
#                 $_
#             } elseif ($_ -is [Collections.IDictionary]) {
#                 @(
#                 foreach ($key in $_.Keys) {
#                     $value = $_[$key]
#                     if ($value -is [Collections.IDictionary]) {
#                         "$key { $($value | toCss) }"
#                     } else {
#                         "${key}: $value;"
#                     }
#                 }) -join ' '
#             }) -join [Environment]::NewLine
#         $cssString = [PSObject]::new($cssString)
#         $cssString.pstypenames.insert(0,'text/css')
#         $cssString
#     }


#     [Ordered]@{
#         body = [Ordered]@{
#             background = $randomBackground
#             color = $randomColor
#             a = [Ordered]@{
#                 color = $randomColor
#             }
#             height = '100vh'
#             width = '100vw'
#         }
#         fontFamily = 'Arial, sans-serif'
#     } |
#     toCss
# }


# function /pattern {
# $response.ContentType = 'image/svg+xml'
# @"
# <svg xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg">
#     <defs>
#         <pattern id="SimplePattern" width="0.1" height="0.1">
#             <circle cx="2.5" cy="2.5" r="0.5" fill="#4488ff" />
#             <line x1="0" x2="5" y1="2.5" y2="2.5" stroke="#4488ff" stroke-width="0.1" />
#             <line y1="0" y2="5" x1="2.5" x2="2.5" stroke="#4488ff" stroke-width="0.1" />
#         </pattern>
#     </defs>
#     <rect fill="url(#SimplePattern)" width="100%" height="100%" opacity="0.3" />
# </svg>
# "@

# }
# function /svg {
#     $response.ContentType = 'image/svg+xml'
#     $bgColor = Get-Random -Max 0xffffff
#     $fgColor = $bgColor -bxor 0xffffff
#     $randomFill = "#{0:x6}" -f $bgColor
#     $randomStroke = "#{0:x6}" -f $fgColor
#     $SideCount = 3..6 | Get-Random
#     $anglePerPoint = 360 / $SideCount
#     $InitialRotation = Get-Random -Max 360

#     $fromPoints = @(
#         'M'
#         foreach ($n in 1..$SideCount) {
#             $x = 50 + (Get-Random -Min -25 -Max 25)
#             $y = 50 + (Get-Random -Min -25 -Max 25)
#             "$x,$y"
#         }
#         'Z'
#     ) -join ' '
#     $toPoints = @(
#         'M'
#         foreach ($n in 1..$SideCount) {
#             $x = 50 + (Get-Random -Min -25 -Max 25)
#             $y = 50 + (Get-Random -Min -25 -Max 25)
#             "$x,$y"
#         }
#         'Z'
#     ) -join ' '
#     $colorAnimation = @(
#         "<animate attributeName='fill' dur='$($RefreshIn / 1000)s' values='$($RandomFill, $randomStroke, $randomFill -join ';')' repeatCount='indefinite' />"
#         "<animate attributeName='stroke' dur='$($RefreshIn / 1000)s' values='$($randomStroke, $randomFill, $randomStroke -join ';')' repeatCount='indefinite' />"
#     )

#     @(
#         "<svg xmlns='http://www.w3.org/2000/svg' width='100%' height='100%' viewBox='0 0 100 100'>"
#         "<circle cx='50' cy='50' r='40' stroke='$RandomStroke' stroke-width='3' fill='$randomFill'>"
#         $colorAnimation
#         "</circle>"
#         "<path d='$fromPoints' fill='$randomFill' stroke='$randomStroke' stroke-width='1%'>"
#         "<animate attributeName='d' dur='$($RefreshIn / 1000)s' values='$($FromPoints, $toPoints, $fromPoints -join ';')' repeatCount='indefinite' />"
#         $colorAnimation
#         "</path>"
#         "</svg>"
#     ) -join [Environment]::newLine
# }

# function /Media {
#     if (-not $request.Url.Query) { return 404 }
#     $parsedQueryString = [Web.HttpUtility]::ParseQueryString($request.Url.Query)
#     $mediaFile = $parsedQueryString['file']
#     if (-not $mediaFile) { return 404 }
#     $mediaFileExists = Get-Item $mediaFile
#     if (-not $mediaFileExists) { return 404 }
#     switch ($mediaFileExists.Extension) {
#         '.mp3' { $response.ContentType = 'audio/mpeg' }
#         '.wav' { $response.ContentType = 'audio/wav' }
#         '.ogg' { $response.ContentType = 'audio/ogg' }
#         '.avi' { $response.ContentType = 'video/x-msvideo' }
#         '.mkv' { $response.ContentType = 'video/x-matroska' }
#         '.mpg' { $response.ContentType = 'video/mpeg' }
#         '.mp4' { $response.ContentType = 'video/mp4' }
#         '.webm' { $response.ContentType = 'video/webm' }
#         default {
#             return 415
#         }
#     }
#     return $mediaFileExists
# }

# Set-Alias /Audio /Media
# Set-Alias /Video /Media

# function /3D {
#     $Random3dScene = @(
# "let geometry = null"
# "let material = null"
# "let newshape = null"
# "let shapes = []"
# foreach ($n in 1..(Get-Random -Min 1 -Max 16)) {
# @"
# geometry = $(
#     switch ('Box', 'Sphere', 'Cylinder','Cone','Torus','TorusKnot','Ring' | Get-Random) {
#         Box {
#             "new THREE.BoxGeometry( $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 1 -Max 24) );"
#         }
#         Sphere {
#             "new THREE.SphereGeometry( $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 1 -Max 24) );"
#         }
#         Cylinder {
#             "new THREE.CylinderGeometry( $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 3 -Max 12) );"
#         }
#         Cone {
#             "new THREE.ConeGeometry( $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 3 -Max 12) );"
#         }
#         Torus {
#             "new THREE.TorusGeometry( $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 3 -Max 12), $(Get-Random -Min 3 -Max 12) );"
#         }
#         TorusKnot {
#             "new THREE.TorusKnotGeometry( $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 3 -Max 12), $(Get-Random -Min 3 -Max 12), $(Get-Random -Min 3 -Max 12)  );"
#         }
#         Ring {
#             "new THREE.RingGeometry( $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 1 -Max 24), $(Get-Random -Min 3 -Max 12) );"
#         }
#     }
# )
# material = $(
#     switch ('MeshBasicMaterial', 'LineBasicMaterial', 'LineDashedMaterial' | Get-Random) {
#         MeshBasicMaterial {
#             "new THREE.MeshBasicMaterial( { color: 0x$("{0:x6}" -f (Get-Random -Max 0xffffff)), wireframe: $('true', 'false' | Get-Random) } );"
#         }
#         LineBasicMaterial {
#             "new THREE.LineBasicMaterial( { color: 0x$("{0:x6}" -f (Get-Random -Max 0xffffff)), linewidth: $(Get-Random -Min 1 -Max 3) } );"
#         }
#         LineDashedMaterial {
#             "new THREE.LineDashedMaterial( { color: 0x$("{0:x6}" -f (Get-Random -Max 0xffffff)), linewidth: $(Get-Random -Min 1 -Max 3), dashSize: $(Get-Random -Min 1 -Max 10) } );"
#         }
#     }
# )
# newshape = new THREE.Mesh( geometry, material );
# newshape.position.x = $(Get-Random -Min -100 -Max 100);
# newshape.position.y = $(Get-Random -Min -100 -Max 100);
# newshape.position.z = $(Get-Random -Min -100 -Max 100);
# newshape.rotation.x = $(Get-Random -Min 0 -Max 180);
# newshape.rotation.y = $(Get-Random -Min 0 -Max 180);
# newshape.rotation.z = $(Get-Random -Min 0 -Max 180);
# scene.add(newshape);
# shapes.push(newshape);
# "@
# }
# ) -join [Environment]::NewLine

#     $OrbitSpeed = (Get-Random -Min 1 -Max 100)*.01

#     $Random3dControls = @(
# "
# let controls = new OrbitControls( camera, renderer.domElement );
# controls.minDistance = $(Get-Random -Min 1 -Max 10);
# controls.maxDistance = $(Get-Random -Min 1 -Max 10);
# controls.autoRotate = true;
# controls.autoRotateSpeed = $OrbitSpeed;
# controls.listenToKeyEvents( window );
# controls.enableDamping = true;
# controls.addEventListener( 'change', renderer.render( scene, camera ) );
# "
# )

#     $sceneAnimation = @(
# @"
# for (let i = 0; i < shapes.length; i++) {
#     let cube = shapes[i];
#     cube.rotation.x += $((Get-Random -Min 1 -Max 100) / 1000);
#     cube.rotation.y += $((Get-Random -Min 1 -Max 100) / 1000);
# }
# "@
# ) -join [Environment]::NewLine

#     $3dScene = @"
# import * as THREE from 'three';
# import { CSS3DRenderer, CSS3DObject } from 'three/addons/renderers/CSS3DRenderer.js';
# import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
# import { TrackballControls } from 'three/addons/controls/TrackballControls.js';

# const scene = new THREE.Scene();
# const camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 );

# $Random3dScene


# $(
#     if ($CssRenderer) {
#         "
# const renderer = new CSS3DRenderer();
# document.getElementById( 'container-3d' ).appendChild( renderer.domElement );
# "
#     } else {
#         "
# const renderer = new THREE.WebGLRenderer({alpha: true});
# renderer.setClearColor( 0xffffff, 0 );
# renderer.setAnimationLoop( animate );
# document.body.appendChild( renderer.domElement );
# "
#     }

# )

# renderer.setSize( window.innerWidth, window.innerHeight );

# camera.position.z = $(Get-Random -Min 100 -Max 200);

# window.addEventListener( 'resize', () => {
#     camera.aspect = window.innerWidth / window.innerHeight;
#     camera.updateProjectionMatrix();
#     renderer.setSize( window.innerWidth, window.innerHeight );
#     renderer.render( scene, camera );
# } );

# $Random3dControls

# function animate() {
#     $sceneAnimation

#     renderer.render( scene, camera );

# }
# "@


#     @"
# <html lang='$(Get-Culture)'>
#     <head>
#         <meta charset="utf-8">
#         <title>There is no route table</title>
#         <style>body { margin: 0; }</style>
#     </head>
#     <script type="importmap">$(
#         ConvertTo-JSON -InputObject ([Ordered]@{
#             "imports" = [Ordered]@{
#                 "three" = "https://cdn.jsdelivr.net/npm/three@latest/build/three.module.js"
#                 "three/addons/" = "https://cdn.jsdelivr.net/npm/three@latest/examples/jsm/"
#             }
#         })
#     )</script>
#     </head>
#     <body>
#     <div id="container-3d"></div>
#     <script type="module">$3dScene</script>
#     </body>
# "@
# }
# #endregion Server functions

# #region Watch for events
# # While the listener is listening:
# while ($Listener.IsListening) {
#     # Get every http* event
#     foreach ($event in @(Get-Event HTTP*)) {
#         # Try to get the context, request, and response from the event
#         $context, $request, $response = $event.SourceArgs
#         # and if there is no output stream, continue
#         if (-not $response.OutputStream) {
#             continue
#         }

#         # If we haven't already, cache a pointer to possible routes.
#         if (-not $script:PossibleRoutes) {
#             # (in this case, we'll presume any command with a slash in it could be a route)
#             $script:PossibleRoutes = $ExecutionContext.SessionState.InvokeCommand.GetCommands('*/*','Alias,Function', $true)
#         }

#         $mappedCommand = $null

#         $schemeAndHostSegment = $request.Url.Scheme,
#             '://',
#             $request.Url.DnsSafeHost -join ''

#         $portSegment =
#             if ($request.Url.Port -notin '80', '443') {
#                 ':' + $request.Url.Port
#             }

#         # Now let's create a list of possible route names for this request, in the order we'd prefer them
#         $possibleRouteNames = @(
#             # $schemeAndHostSegment, $portSegment, $request.Url.LocalPath -join ''
#             # $schemeAndHostSegment, $request.Url.LocalPath -join ''
#             # "$schemeAndHostSegment/"
#             # $schemeAndHostSegment
#             $request.Url.LocalPath
#             # For this example, we'll just use the local path.
#             # (this will work for a single server, for multitenant hosting, you'd need to include the host)
#         )

#         # Now we'll loop through the possible route names
#         foreach ($possibleRouteName in $possibleRouteNames ) {
#             # and see if a command exists for that route
#             $commandExists = @($script:PossibleRoutes -match "^$([Regex]::Escape($possibleRouteName))$")[0]
#             if ($commandExists) {
#                 $mappedCommand = $commandExists
#                 break
#             }
#         }

#         # If we've mapped a command
#         if ($mappedCommand) {
#             # Run it, and capture all of the streams
#             $result = . $mappedCommand $request *>&1

#             # The result can tell us it is a content type by giving itself a content type as a type name
#             $ContentTypePattern = '^(?>audio|application|font|image|message|model|text|video)/.+?'
#             $resultIsContentType = @($result.pstypenames -match $ContentTypePattern)[0]
#             # If the result was a content type
#             if ($resultIsContentType) {
#                 # set that header
#                 $response.ContentType = $resultIsContentType
#             }

#             # If the result was a string
#             if ($result -is [int] -and $result -ge 300 -and $result -lt 600) {
#                 # set the status code
#                 $response.StatusCode = $result
#                 $response.Close()
#             }
#             elseif ($result -is [string]) {
#                 # encode it using $OutputEncoding and close the response
#                 <#
#                 bug: this line sometimes errors as

#                     > $response.Close($outputEncoding.GetBytes($result), $false

#                     Exception calling "Close" with "2" argument(s): "Cannot access a disposed object.
#                     Object name:  'System.Threading.ThreadPoolBoundHandle'."

#                 cause might be $listener.dispose() before removing jobs?
#                 #>
#                 $response.Close($outputEncoding.GetBytes($result), $false)
#             }
#             # If the result was a byte[]
#             elseif ($result -is [byte[]]) {
#                 # respond with the bytes
#                 $response.Close($result, $false)
#             }
#             elseif ($result -is [IO.FileInfo]) {
#                 $BufferSize = 1mb
#                 $serveFileJob = Start-ThreadJob -Name ($Request.Url -replace '^https?', 'file') -ScriptBlock {
#                     param($result, $Request, $response, $BufferSize = 1mb)
#                     if ($request.Method -eq 'HEAD') {
#                         $response.ContentLength64 = $result.Length
#                         $response.Close()
#                         return
#                     }

#                     $response.Headers["Accept-Ranges"] = "bytes";
#                     $range = $request.Headers['Range']
#                     $rangeStart, $rangeEnd = 0, 0
#                     $fileStream = [IO.File]::OpenRead($result.Fullname)
#                     if ($range) {
#                         $null = $range -match 'bytes=(?<Start>\d{1,})(-(?<End>\d{1,})){0,1}'
#                         $rangeStart, $rangeEnd = ($matches.Start -as [long]), ($matches.End -as [long])
#                     }
#                     if ($rangeStart -gt 0 -and $rangeEnd -gt 0) {
#                         $buffer = [byte[]]::new($BufferSize)
#                         $fileStream.Seek($rangeStart, 'Begin')
#                         $bytesRead = $fileStream.Read($buffer, 0, $BufferSize)
#                         $contentRange = "$RangeStart-$($RangeStart + $bytesRead - 1)/$($fileStream.Length)"
#                         $response.StatusCode = 206;
#                         $response.ContentLength64 = $bytesRead;
#                         $response.Headers["Content-Range"] = $contentRange
#                         $response.OutputStream.Write($buffer, 0, $bytesRead)
#                         $response.OutputStream.Close()
#                     } else {
#                         # if that stream has a content length
#                         if ($result.ContentLength64 -gt 0) {
#                             # set the content length
#                             $response.ContentLength64 = $result.ContentLength64
#                         }
#                         # Then copy the stream to the response.
#                         $fileStream.CopyTo($response.OutputStream)
#                     }
#                     $response.Close()
#                     $fileStream.Close()
#                     $fileStream.Dispose()
#                 } -ThrottleLimit 100 -ArgumentList $result, $request, $response
#             }
#             else {
#                 # otherwise, convert the result to JSON
#                 # and set the content type to application/json if it is not already set
#                 if (-not $response.ContentType) {
#                     $response.ContentType = 'application/json'
#                 }
#                 $response.Close($outputEncoding.GetBytes((ConvertTo-Json -InputObject $result)), $false)
#             }
#             Write-Host "Responded to $($request.Url) in $([DateTime]::Now - $event.TimeGenerated)" -ForegroundColor Cyan
#         }
#         else {
#             $response.StatusCode = 404
#             $response.Close()
#         }
#         $event | Remove-Event
#     }
# }
# #endregion Watch for events

# "exit => '$( $MyInvocation.MyCommand.Name )'" | Write-Host
