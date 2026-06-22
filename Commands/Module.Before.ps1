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
