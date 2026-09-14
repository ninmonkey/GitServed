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
        $expected = Get-Content ( Join-Path $PSScriptRoot './Data/repo.list-sushi.json' ) | ConvertFrom-Json

        Helper.Invoke-RestMethod -RelativePath 'repo/list'
        | ? name -eq 'ripgrep'
        | Should-BeEquivalent $expected
    }
}
