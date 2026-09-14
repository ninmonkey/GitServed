<#
.synopsis
    main pester testing for CI. Runs path: ./Tests/Commands/*
#>
#region pester config
$PSStyle.OutputRendering = 'Host'
$error.clear()

$script:Config = New-PesterConfiguration

$Config.Output.Verbosity     = 'Detailed'
$Config.Run.Exit = $true # run the tests, write both artifacts, exit non-zero if anything failed. ( see: https://pester.dev/tutorial/ci/test-script )

$Config.TestResult.Enabled   = $true
$Config.CodeCoverage.Enabled = $false

$Config.Run.Path          = './Tests/Commands'
$Config.CodeCoverage.Path = './Tests/Commands'

$Config.TestResult.OutputPath   = './testResults.xml'
$Config.CodeCoverage.OutputPath = './coverage.xml'

#endregion pester config

# always rebuild module at least once
#   Maybe redundant with Pester.BeforeContainer.ps1
.\Build\Build.Module.ps1

Invoke-Pester -Configuration $Config

#region post-testing end
# log if/where files were saved
if( $Config.CodeCoverage.Enabled ) {
    "wrote: `"${fg:blue}$( $config.CodeCoverage.OutputPath.Value )${fg:clear}`""
}
if( $Config.TestResult.Enabled ) {
    "wrote: `"${fg:blue}$( $config.TestResult.OutputPath.Value )${fg:clear}`""
}
#endregion post-testing end
