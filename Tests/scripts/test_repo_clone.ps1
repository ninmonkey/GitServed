<#
.SYNOPSIS
    Tests the endpoint: /repo/Clone?url
.EXAMPLE
    ./test_repo_clone.ps1
#>
param(
    [int] $Port = 3001,
    [string] $HostName = 'http://127.0.0.1',

    [Alias('Url', 'Repo')]
    [uri] $CloneRepoUrl = 'https://github.com/santisq/PSTree.git'
)

$UrlPrefix = "${HostName}:${Port}"
$QueryPath = 'repo/Clone?url={0}' -f ( $CloneRepoUrl )

[uri] $UrlRequest = "${UrlPrefix}/${QueryPath}"

( $resp = irm $UrlRequest -RetryIntervalSec 1 -MaximumRetryCount 1 -SkipHttpErrorCheck ) | ft

'## Vars' | Write-Host -fg Cyan
Get-Variable '*Url*', 'Resp' | ft -auto

'## $resp = Invoke-RestMethod -Url "{0}"' -f $UrlRequest.ToString() | Write-Host -fg cyan
$resp |Json | jq '. | keys'
