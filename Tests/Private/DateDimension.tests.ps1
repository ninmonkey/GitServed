BeforeAll {
    $error.clear()
    $PSStyle.OutputRendering = 'ansi'

    # rebuild, and import latest
    $ModuleName= 'GitServe'
    $ModuleRoot     = Join-path $PSScriptRoot '../..'
    $ModuleManifest = Join-Path $ModuleRoot "${ModuleName}.psd1" # ie: '/GitServe.psd1'
    $ToBuild        = Join-Path $ModuleRoot '/Build/Build.Module.ps1' | Get-Item -ea 'stop'
    $TestUtilsPs1  = Join-Path $ModuleRoot '/Tests/test_utils.psm1'

    & $ToBuild
    'Done' | Write-Host -bg 'green'

    Remove-module 'GitServe' -ea 'ignore'
    @(
        Import-Module  -PassThru -Force $ModuleManifest
        Import-Module  -PassThru -Force $TestUtilsPs1
    )
        | Join-String -p { $_.Name, $_.Version -join ': ' } -op "importing:...`n" -f "`n - {0}"
        | Pansies\Write-Host -fore 'goldenrod'
}

Describe 'Get-NextDatePeriod' {
    Context 'Get Periods' {
        It 'Current: <CurrentDate>, Period: <Period> is <ExpectedStr>' -ForEach @(
            @{
                CurrentDate = [datetime]::ParseExact('2026-03-04', 'yyyy-MM-dd', [cultureinfo]::GetCultureInfo('en-us'))
                Period      = 'month'
                ExpectedStr = '2026-03-04'
            }
            # @{
            #     CurrentDate = [datetime]::ParseExact('2026-03-07', 'yyyy-MM-dd', [cultureinfo]::GetCultureInfo('en-us'))
            #     Period      = 'month'
            #     ExpectedStr = '2026-03-04'
            # }

        ) {
            $datePeriod_splat = @{
                CurrentDate = $CurrentDate
                Period      = $Period
            }
            if( $null -ne $MaxDate ) {
                $datePeriod_splat['MaxDate'] = $MaxDate

            }
            GitServe.Get-NextDatePeriod @datePeriod_splat
                | % {  $_.ToString('yyyy-MM-dd', ([cultureinfo]::GetCultureInfo('en-us') ) ) }
                | Should -Be $ExpectedStr

        }
    }
}
# This is verbose, but the edge cases should be defined
# Describe "Test: IsBlank" -tag 'internal' {
#     Context 'Is.Null' {
#         It 'from Param: <value> is <expected>' -ForEach @(
#             @{ Value = $null ; Expected = $true }
#             @{ Value = ''    ; Expected = $false }
#             @{ Value = ' '   ; Expected = $false }
#         ) {
#             InModuleScope 'Mintils' -Parameters $_ {
#                 _Is.Null $Value   | Should -BeExactly $Expected
#             }
#         }
#         It 'from Pipeline: <value> is <expected>' -ForEach @(
#             @{ Value = $null ; Expected = $true }
#             @{ Value = ''    ; Expected = $false }
#             @{ Value = ' '   ; Expected = $false }
#         ) {
#             InModuleScope 'Mintils' -Parameters $_ {
#                 $value | _Is.Null | Should -BeExactly $Expected
#             }
#         }
#     }
# }
#
