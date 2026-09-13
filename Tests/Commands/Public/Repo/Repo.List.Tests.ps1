#requires -Modules Pansies, Pester
#requires -PSEdition Core

$PSStyle.OutputRendering = 'ansi'

BeforeAll {
    $WorkspaceRoot = Get-Item -ea 'stop' ( Join-Path $PSScriptRoot '../../../..' )
    "workspace: ${WorkspaceRoot}" | Log.Dim
    # load newest build
    Import-Module -Force -PassThru ( Join-Path $WorkspaceRoot 'GitServe.psd1' )
    | Join-String -op 'Import: ' -p { $_.Name, $_.Version } | Write-Host -bg 'blue'


    # Load known repos for testing
    $SourceReposRoot = Get-Item -ea 'stop' 'C:\GitLoggerApp\Testcase-ClonedRepos'
    GitServe.Set-ConfigRepoRoot -Path $SourceReposRoot
    # GitServe.Repo.List -WithoutCache # force cache is right for this instance

    function CloneRepoIfMissing {
        <#
        .SYNOPSIS
            ensure repo exists at "<SourceReposRoot/Owner/Repo>" otherwise clone it
        #>
        param(
            [Parameter(Mandatory)]
            [string] $OwnerRepoPair,

            # which exact hash to checkout on
            [Parameter(Mandatory)]
            [string] $CheckoutHash,

            # what to clone
            [Parameter(Mandatory)]
            [uri]$CloneUrl,

            # folder to clone under
            [Parameter(Mandatory)]
            [string] $RepoRoot

        )
        $found = GitServe.Repo.List -WithoutCache | ? OwnerRepoPair -eq $OwnerRepoPair
        if( $Found ) { return }

        "Missing ${ownerRepPair}... Cloning..." | Log.Warn
        $ownerName, $repoName = $OwnerRepoPair -split '/', 2

        $cloneParentDir = Join-Path $RepoRoot $ownerName
        mkdir $cloneParentDir -ea Ignore -Confirm:$False

        GitServe.Invoke-RealGit -Frompath $cloneParentDir -GitArgList @(
            'clone'
            $CloneUrl
        )

        $repoFullPath = Join-path $cloneParentDir $repoName
        "Cloned to: ${repoFullPath}" | Log.Info

        GitServe.Invoke-RealGit -FromPath $repoFullPath -GitArgList @(
            'checkout'
            $CheckoutHash
        ) | Write-Verbose

        "Checked hash: ${CheckoutHash}" | Log.Info

        # force clear cache because the clone uses raw git commands to clone, and because of commit hash change
        GitServe.Repo.List -WithoutCache
    }

    $cloneRepoIfMissingSplat = @{
        CloneUrl      = 'https://github.com/burntsushi/ripgrep'
        OwnerRepoPair = 'burntsushi/ripgrep'
        RepoRoot      = $SourceReposRoot
        CheckoutHash  = '3fce3b5bb0236da2df6d99672afb8a719642eca7'
    }

    CloneRepoIfMissing @cloneRepoIfMissingSplat
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
        It 'cloned right date range' {
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
