BeforeAll {
    $error.clear()
    $PSStyle.OutputRendering = 'ansi'

    # rebuild, and import latest
    $ModuleName= 'GitServe'
    $ModuleRoot     = Join-path $PSScriptRoot '../..'
    $ModuleManifest = gi -ea 'stop' ( Join-Path $ModuleRoot "${ModuleName}.psd1" ) # ie: '/GitServe.psd1'
    $ToBuild        = Join-Path $ModuleRoot '/Build/Build.Module.ps1' | Get-Item -ea 'stop'
    $TestUtilsPs1  = Join-Path $ModuleRoot '/Tests/test_utils.ps1'

    & $ToBuild
    'Build Done' | Write-Host -bg 'green'
    # . $TestUtilsPs1
    'Pester imports: Done' | Write-Host -bg 'green'

    # Remove-module 'GitServe' -ea 'ignore'
    @(
        Import-Module  -PassThru -Force $ModuleManifest
        # Import-Module  -PassThru -Force $TestUtilsPs1
    )
        | Join-String -p { $_.Name, $_.Version -join ': ' } -op "importing:...`n" -f "`n - {0}"
        | Pansies\Write-Host -fore 'goldenrod'
}

Describe 'Get-NextDatePeriod' {
    Context 'Get Periods' {
        It 'Current: <CurrentDate>, Period: <Period> is <ExpectedStr>' -ForEach @(
            @{
                CurrentDate =  Date.FromStr '2026-03-04'
                Period      = 'month'
                ExpectedStr = '2026-04-04'
            }
            @{
                CurrentDate =  Date.FromStr '2026-07-04'
                Period      = 'week'
                ExpectedStr = '2026-07-11'
            }
        ) {
            $datePeriod_splat = @{
                CurrentDate = $CurrentDate
                Period      = $Period
            }
            if( $null -ne $MaxDate ) {
                $datePeriod_splat['MaxDate'] = $MaxDate

            }
            # clean(future): use the newer should verb syntax
            $newDate = GitServe.Get-NextDatePeriod @datePeriod_splat
            Date.Str $newDate | Should -Be $ExpectedStr

        }
    }
}
