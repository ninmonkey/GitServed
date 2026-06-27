<#
.SYNOPSIS
    Tests command: Metric.CommitCount
.EXAMPLE
    git log | Metric-GitServeCommitCount
.EXAMPLE
    ./test_metric_commitcount.ps1

#>
param(
    [string] $RepoPath = 'H:/RootClonedRepos/burntsushi/ripgrep'
)

Import-Module (Join-Path $PSScriptRoot '../../GitServe')
Import-module Ugit

( $out = & (gmo Gitserve) { git log -C (gi -ea 'stop' $RepoPath )  | GitServe.Metric.CommitCount } )

$out[0] | fl * -Force

'## Vars' | Write-Host -fg Cyan
Get-Variable 'RepoPath', 'out' | ft -auto

$out | Json | jq '.[0] | keys' -c
