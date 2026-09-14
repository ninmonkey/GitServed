<#
.SYNOPSIS
    Re-Import and host GitServe using TestCase Pester config
#>
param(
    [string] $CloneRepoRoot = 'C:\GitLoggerApp\Testcase-ClonedRepos'
)

try { GitServe.Stop } catch { }
$error.clear()
Import-Module -ea 'stop' "${PSScriptRoot}/../../Gitserve.psd1" -Force -PassThru
$curHost = GitServe.Get-ConfigHost
GitServe.Set-ConfigRepoRoot -Path $CloneRepoRoot
GitServe.Start -HostName $curHost.Host -Port $curHost.Port -PSHost
