<#
.SYNOPSIS
    Tests the endpoint: /repo/log?url=repoName/ownerName
.EXAMPLE
    ./test_repo_log.ps1
#>
param(
    [int] $Port = 3001,
    [string] $HostName = 'http://127.0.0.1',

    [Alias('Name', 'ShortName')]
    $OwnerRepoName = 'santisq/PSTree'
)

$UrlPrefix = "${HostName}:${Port}"
$QueryPath = 'repo/log?url={0}' -f ( $OwnerRepoName )

[uri] $UrlRequest = "${UrlPrefix}/${QueryPath}"

( $resp = irm $UrlRequest -RetryIntervalSec 1 -MaximumRetryCount 1 -SkipHttpErrorCheck | Select -first 5 ) | ft

'## Vars' | Write-Host -fg Cyan
Get-Variable '*Url*', 'Resp' | ft -auto

'## $resp = Invoke-RestMethod -Url "{0}"' -f $UrlRequest.ToString() | Write-Host -fg cyan
# $resp | Select-Object  -First 1 |Json | jq '. | keys'
$resp | Json | jq '.[0] | keys'

Write-Warning 'todo(case): Verify OwnerRepoName is case-insensitive'
