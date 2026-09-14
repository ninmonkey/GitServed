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

Describe '/repo/list' {
    It 'Contains exact response' {
        $expected = [pscustomobject]@{
            Name = 'ripgrep'
            NewestCommitDate = '2026-08-04'
            NewestCommitRelative = '6 weeks ago'
            Owner = 'burntsushi'
            OwnerRepoPair = 'burntsushi/ripgrep'
            Path = 'C:\GitLoggerApp\Testcase-ClonedRepos\burntsushi\ripgrep'
            Remote = 'https://github.com/burntsushi/ripgrep'
        }
        # irm '127.0.0.1:3333/repo/list'
        Helper.Invoke-RestMethod -RelativePath 'repo/list'
        | ? name -eq 'ripgrep'
        | Should-BeEquivalent $expected
    }
}
