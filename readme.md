# Git Served

name `GetServed`, `GitServed` ?

This does two things:

- Query and search git repos from a pwsh TUI
- Or query from any language from a local rest API


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

- `/Commands` - Powershell module commands
- `/Server` - HttpServer Routes
- `/Static` - Static Resources