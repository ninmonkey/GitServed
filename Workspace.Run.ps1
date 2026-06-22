
# ensure clean, force does not always
try { GitServe.Stop } catch  { } ; Remove-Module GitServe -ea ignore

. .\build\Build.Module.ps1 &&  ipmo ./Gitserve -PassThru -Force  | Join-String
GitServe.Start -Port 3001 -PSHost
