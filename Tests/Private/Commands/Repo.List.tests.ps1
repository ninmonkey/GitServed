#requires -Modules Pansies, Pester
#requires -PSEdition Core

$PSStyle.OutputRendering = 'ansi'

BeforeAll {
    $WorkspaceRoot = Get-Item -ea 'stop' ( Join-Path $PSScriptRoot '../../..' )
    # load newest build
    Import-Module -Force -PassThru ( Join-Path $WorkspaceRoot 'GitServe.psd1' )
    | Join-String -op 'Import: ' -p { $_.Name, $_.Version } | Write-Host -bg 'blue'

    # Load known repos for testing
    $SourceRepos = Get-Item -ea 'stop' 'C:\GitLoggerApp\Testcase-ClonedRepos'
    GitServe.Set-ConfigRepoRoot -Path $SourceRepos
    # GitServe.Repo.List -WithoutCache # force cache is right for this instance
}

Describe 'GitServe.Repo.List' {
    Context 'Required Testing Data' {
        # todo(pester): move to top level file that all subdirectories require this test before runnign
        It 'has repo: <OwnerRepoPair>' -ForEach @(
            @{ OwnerRepoPair = 'burntsushi/ripgrep' }
        ) {
            GitServe.Repo.List
            | Should-Any { $_.OwnerRepoPair -eq $OwnerRepoPair } -Because 'The required testing repo should exist'
        }
    }
    It 'Correct Types' {
        # It 'typeof' {
        #     $repos | GitServe.Repo.List
        #     $resp[0] | Should -BeOfType 'GitServe.Route.Repo.List'
        #     $resp[0] | Should -BeOfType 'GitServe.wrong.List'
        # }
        # It 'A' {
            $repos = GitServe.Repo.List
            $repos.Count | Should -Not -Be 0
            # $repos.Count | Should -Be 99
            # $repos.Count | Should -Be 99
            # $repos.Count | Should -Be 4
        # }
    }
}
