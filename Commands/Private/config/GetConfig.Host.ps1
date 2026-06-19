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
