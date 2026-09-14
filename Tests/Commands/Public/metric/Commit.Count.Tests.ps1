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

Describe 'GitServe.Metric.CommitCount' {
    Context 'Contains exact response' {
        it 'for UGit' {
            $path = GitServe.Path.FromShortRepoName 'burntsushi\ripgrep'
            $expected = Get-Content ( Join-Path $PSScriptRoot './Data/commit.count-sushi.json' ) | ConvertFrom-Json
            $actual = GitServe.Invoke-UGit -Path $path log -After '2026-08-01' | GitServe.Metric.CommitCount
            $actual | Should-BeEquivalent $expected
        }
    }
}
