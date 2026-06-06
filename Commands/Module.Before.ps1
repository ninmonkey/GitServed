$script:ModuleState = [hashtable]::Synchronized(@{
    HostName = $null
    Port = $null
})
