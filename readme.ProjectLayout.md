# App Layout for GetServed

- `/Commands` - Powershell module commands
  - `/Commands/Private` - Internal functions
  - `/Commands/Public` - Public module commands
- `/Routes` - HttpServer Routes
  - `/Routes/Public` - all web routes that require no auth
- `/Static` - Static Resources
- `/Build` - Scripts to Build the module
- `/.vscode` - vscode config for build and launching
  - [launch.json](.vscode/launch.json)
  - [tasks.json](.vscode/tasks.json)
- `/Tests`
  - `/Tests/Private` - Pester tests of module internals
  - `/Tests/scripts` - Stand alone scripts for testing. Not pester tests