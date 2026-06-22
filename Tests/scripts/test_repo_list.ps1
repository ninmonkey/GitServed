<#
.SYNOPSIS
    Tests the endpoint: /repo/list
.EXAMPLE
    ./test_repo_list.ps1
#>
param(
    [int] $Port = 3001,
    [string] $HostName = 'http://127.0.0.1'
)

$UrlPrefix = "${HostName}:${Port}"
$QueryPath = 'repo/list'

[uri] $UrlRequest = "${UrlPrefix}/${QueryPath}"

( $resp = irm $UrlRequest -RetryIntervalSec 1 -MaximumRetryCount 1 -SkipHttpErrorCheck ) | ft

'## Vars' | Write-Host -fg Cyan
Get-Variable '*Url*', 'Resp' | ft -auto

'## $resp = Invoke-RestMethod -Url "{0}"' -f $UrlRequest.ToString() | Write-Host -fg cyan
$resp |Json | jq '. | keys'
