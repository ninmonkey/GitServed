# GitServe
- [GitServe](#gitserve)
- [Examples](#examples)
  - [Get Repos](#get-repos)
  - [Misc](#misc)
  - [Using RepoShortNames](#using-reposhortnames)
  - [Metrics](#metrics)
  - [Config](#config)
    - [Get Host, RepoRoot](#get-host-reporoot)
    - [Change Default RepoRoot](#change-default-reporoot)
  - [Cloning](#cloning)
- [`git` and `ugit` example](#git-and-ugit-example)
  - [Invoke RealGit / `git.exe`](#invoke-realgit--gitexe)
  - [Invoke `UGit`](#invoke-ugit)
- [Tips](#tips)
  - [Aliases and Command names](#aliases-and-command-names)
  - [Search Commands by Names](#search-commands-by-names)


To install and import:
```powershell
Install-PSResource GitServe
Import-Module GitServe
```

# Examples

## Get Repos

```powershell
# save and print cloned repo summary
$cloned = GitServe.Repo.List
$cloned | ft -auto
```

View the newest commits
```powershell
$cloned | Select -first 5 | Ft -AutoSize
```
```
Name             NewestCommitDate NewestCommitRelative Owner      OwnerRepoPair       Path
----             ---------------- -------------------- -----      -------------       ----
fzf              2026-08-17       8 days ago           junegunn   junegunn/fzf        C:\...\junegunn\fzf
vscode           2026-08-17       7 days ago           microsoft  microsoft/vscode    C:\...\microsoft\vscode
GitServed        2026-08-10       2 weeks ago          ninmonkey  ninmonkey/GitServed C:\...\ninmonkey\GitServed
Snippets         2026-08-07       3 weeks ago          Jaykul     Jaykul/Snippets     C:\...\Jaykul\Snippets
```

## Misc

Jump to the path of a repository
```powershell
Push-Location $cloned[0].Path
```

## Using RepoShortNames

If you need the absolute filepath to a repository, you can use a **RepoShortName** as shorthand.
```powershell
$cloned[0].OwnerRepoPair
# output: junegunn/fzf
GitServe.Path.FromShortRepoName -ShortRepoName 'junegunn/fzf'
# output: C:\GitLoggerApp\ClonedRepos\junegunn\fzf
```
**Jump** to repository using short repo names
```powershell

Push-Location ( GitServe.Path.FromShortRepoName -ShortRepoName 'junegunn/fzf' )
# enter: C:\GitLoggerApp\ClonedRepos\junegunn\fzf
```

**List all short names**
```powershell
(GitServe.Repo.List).OwnerRepoPair
```

## Metrics

```powershell
GitServe.Invoke-UGit log | GitServe.Metric.CommitCount -Period day
GitServe.Invoke-UGit log | GitServe.Metric.CommitCount -Period month
```
<details><summary>Output (Click to expand)

</summary>


```powershell
> GitServe.Invoke-UGit log -After '2024-01-01' 
    | GitServe.Metric.CommitCount -Period year
    | Sort CommitDate -Descending
    | ft Year, Month, *name*, CommitCount 


Year Month GitUserName    CommitCount
---- ----- -----------    -----------
2026     3 Snowy                    1
2026     4 sharpchen                1
2026     1 Justin Chung             1
2026     4 Andy Jordan              1
2026     2 Anam Navied              1
2025     9 xtqqczze                 1
2025     4 Maxime Labelle           1
2025     5 Mahir Cadirci            1
2025     7 jftkcs                   1
2025     2 Fabrice Sanga            1
2025    10 Dongbo Wang             20
2025     8 Andy Jordan              9
2024    11 Sean Wheeler             1
2024    10 Dongbo Wang             21
2024     6 Andy Jordan              1
```

</details>


## Config


### Get Host, RepoRoot

**Get Config**
```powershell
GitServe.Get-ConfigHost

# or
GitServe.Get-ConfigHost | ConvertTo-Json -Compress
```
output
```json
{"Host":"127.0.0.1","Port":3001,"Url":"http://127.0.0.1:3001"}
```
```powershell
GitServe.Get-ConfigRepoRoot 
# output: C:\GitLoggerApp\ClonedRepos
```

### Change Default RepoRoot

```powershell

GitServe.Set-ConfigRepoRoot -Path 'c:\myRepos'
GitServe.Repo.List | Ft # now lists the new location

# using multiple roots
GitServe.Set-ConfigRepoRoot -Path 'c:\root1', 'c:\anotherRoot'
GitServe.Repo.List | Ft
```

## Cloning

```powershell
GitServe.Git.Clone 'https://github.com/BurntSushi/ripgrep.git'
```

# `git` and `ugit` example

## Invoke RealGit / `git.exe`

To run
```powershell
git --no-pager log -n 4 --format=oneline --color=always
```
use
```powershell
GitServe.Invoke-RealGit --no-pager, log, -n, 4, --format=oneline, --color=always
# or the same using cmdlet parameters
GitServe.Invoke-RealGit -NoPager -ColorAlways log, -n, 4, --format=oneline
```    
----
Using a custom `-Format` (tab completions)
```powershell
GitServe.Invoke-RealGit -Format oneline log, -n, 4, --abbrev-commit, --after=2022-12-01
```    

`-DryRun` Do not actually invoke git. Just print the arguments that would be used

```powershell
GitServe.Invoke-RealGit -DryRun -FromPath 'C:\data\myGit\GitServed' -ArgList 'log', '-n', '2'
# output: Calling RealGit => git -C C:\data\myGit\GitServed log -n 2
```    
---

> [!TIP]
> You can run git commands from any directory. Native git uses `git -C 'path'` .
> GitServe uses `-FromPath`


To run
```powershell
git -C ( gi 'c:\data\myGit\GitServed' ) log -n 2
```
use
```powershell
GitServe.Invoke-RealGit -FromPath 'C:\data\myGit\GitServed' -ArgList 'log', '-n', '2'
```    

---
```powershell

# example: list HEAD files
# the original command was: git.exe -C (gi '.') ls-tree -r HEAD --name-only
GitServe.Invoke-RealGit -Path '.' -GitArgList 'ls-tree', '-r', 'HEAD', '--name-only'
```    
```powershell

# show tags, jump to tag
GitServe.Invoke-RealGit -ColorAlways -NoPager tag, -n
# out: v0.0.12
GitServe.Invoke-RealGit -ColorAlways -NoPager show, v0.0.12

# show hash and message since tag
GitServe.Invoke-RealGit -ColorAlways -NoPager log, v0.0.12..HEAD, --oneline

# print bare messages without hash
GitServe.Invoke-RealGit -ColorAlways -NoPager log, v0.0.12..HEAD, --format=%s
```    

## Invoke `UGit`



# Tips

## Aliases and Command names

Commands are exported with normal names ex: `Get-GitServeRepoList`
Shorter aliases are prefixed by `GitServe.*`
<!-- Routes are prefixed by `GitServe.Route.*` -->

```powershell
# example regular name and alias name
Get-GitServeRepoList
GitServe.Repo.List
```

## Search Commands by Names

```powershell
# List all
GitServe.<tab>

# Wildcard search
GitServe.*repo<tab>
```
> [!TIP]
> This works best with the hotkey **MenuComplete**. This is `<ctrl+space>` but some terminals override it. I set mine to `<tab>` using

```powershell
Set-PSReadLineKeyHandler -Chord 'Tab' -Function MenuComplete
```


<!-- This does two things:

- Query and search git repos from a pwsh TUI
- Or query from any language from a local rest API

## Naming? `GetServed` vs `GitServed` ?

- `GitServed` - is **this module** that serves git repos over REST and TUI
- `GetServed` - the re-usable module pattern that was used to create this module

## How to Run

Build, Run example

## Future Plans

### Server: Rebuild changes and Run

```ps1
ServeIt stop
build-module.ps1 # build module changes 
ServeIt start 3001
```

### User Commands
```ps1
# Get request to current session
ServeIt /repo/list 
ServeIt /repo/clone @{ url = 'https://github.com/BurntSushi/ripgrep.git' }
```
**Output**
```log
Responded to http://127.0.0.1:3001/repo/list in 00:00:00.4901109
Responded to http://127.0.0.1:3001/repo/clone?url=https://github.com/BurntSushi/ripgrep.git in 00:00:00.4901109
```
## TUI - Autocompletes query routes

- fzf and completions but TUI

## App Layout

See: [readme.ProjectLayout.md](readme.ProjectLayout.md)


## Debugging the module

To quickly rebuild and run a test server, run:
```ps1
.\Workspace.Run.ps1
```

An example that stops, rebuilds, and reloads module changes
```ps1
. ./Scratch/debug_harness.ps1
``` -->