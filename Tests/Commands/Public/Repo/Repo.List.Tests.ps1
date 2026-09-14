#requires -Modules Pansies, Pester
#requires -PSEdition Core

$PSStyle.OutputRendering = 'ansi'

BeforeAll {
    # Load known repos for testing
    $SourceReposRoot = Helper.TestCloneReposRoot
    GitServe.Set-ConfigRepoRoot -Path $SourceReposRoot
    # GitServe.Repo.List -WithoutCache # force cache is right for this instance

    $cloneRepoIfMissingSplat = @{
        CloneUrl      = 'https://github.com/burntsushi/ripgrep'
        OwnerRepoPair = 'burntsushi/ripgrep'
        RepoRoot      = $SourceReposRoot
        CheckoutHash  = '3fce3b5bb0236da2df6d99672afb8a719642eca7'
    }

    Helper.CloneRepoIfMissing @cloneRepoIfMissingSplat
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
        It 'cloned right date range' -Tag 'UsesClone' {
            $one = GitServe.Repo.List | ? OwnerRepoPair -eq 'burntsushi/ripgrep'
            $one.NewestCommitDate | Should-Be -Expected '2026-08-04' -because 'Tests require this date range'
            $one.Remote | Should-MatchString -Expected 'https://github.com/BurntSushi/ripgrep' # .git suffix depends on clone command

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
