. .\build\Build.Module.ps1 &&  ipmo ./Gitserve -PassThru  | Join-String
GitServe.Start -Port 3001 -PSHost
