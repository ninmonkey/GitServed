# GitServe
- [GitServe](#gitserve)
- [Examples](#examples)
  - [Get Repos](#get-repos)
  - [Misc](#misc)
  - [Using RepoShortNames](#using-reposhortnames)
  - [Config](#config)
    - [Change Default RepoRoot](#change-default-reporoot)
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


## Config

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