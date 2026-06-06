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
