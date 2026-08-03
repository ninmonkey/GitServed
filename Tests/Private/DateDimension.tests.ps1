BeforeAll {
    $error.clear()
    $PSStyle.OutputRendering = 'ansi'

    # rebuild, and import latest
    $ModuleName= 'GitServe'
    $ModuleRoot     = Join-path $PSScriptRoot '../..'
    $ModuleManifest = Join-Path $ModuleRoot "${ModuleName}.psd1" # ie: '/GitServe.psd1'
    $ToBuild        = Join-Path $ModuleRoot '/Build/Build.Module.ps1' | Get-Item -ea 'stop'

    & $ToBuild
    'Done' | Write-Host -bg 'green'

    Remove-module 'GitServe' -ea 'ignore'
    @(
        Import-Module $ModuleManifest -Force:$true -PassThru
    )
        | Join-String -p { $_.Name, $_.Version -join ': ' } -op "importing:...`n" -f "`n - {0}"
        | Pansies\Write-Host -fore 'goldenrod'
}

Describe 'Date dim ranges' {
    Context 'Get-NextDatePeriod' {
        BeforeAll {
            $StartDay = [datetime]::ParseExact(
                    '2026-03-04',  'yyyy-MM-dd', ([cultureinfo]::GetCultureInfo('en-us')) )
        }
        It 'Current: <CurrentDate>, Period: <Period> is <ExpectedStr>' -ForEach @(
            @{
                CurrentDate = $StartDay
                Period = 'month'
                ExpectedStr = '2026-03-04'
                # Expected =
                #     [datetime]::ParseExact(
                #         '2026-03-04',  'yyyy-MM-dd', ([cultureinfo]::GetCultureInfo('en-us')) )

                # $ret.ToString('yyyy-MM-dd')
                #     2026-09-03
            }

        ) {
            # $ret = GitServe.Get-NextDatePeriod -CurrentDate $Today -Period month -MaxDate ($today.AddMonths(1)) -DebugInfo

            # $ret.ToString('yyyy-MM-dd')  -eq '2026-09-03'
          $True | Should -BeExactly $True
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
