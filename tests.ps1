<#
.synopsis
    main pester testing for CI. Runs path: ./Tests/Commands/*
#>
$error.clear()

$Config = New-PesterConfiguration

$Config.Run.Path         = './Tests/Commands'
$Config.Output.Verbosity = 'Detailed'
$Config.TestResult.Enabled = $true
# $config.Run.Exit = $true # https://pester.dev/tutorial/ci/test-script
$Config.TestResult.OutputPath = './testResults.xml'


# shared imports
Import-Module -Force ( Gi -ea 'stop' (  Join-Path $PSScriptRoot 'Tests/test_utils.psm1' ) )

# always rebuild
.\Build\Build.Module.ps1

Invoke-Pester -Configuration $Config

"wrote: ${fg:blue}./testResults.xml"
