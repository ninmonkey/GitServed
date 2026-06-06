function OnRemoveModule_Handler { # or "Module.OnRemove" ?
    <#
    .synopsis
        Autocleanup module when module is unloaded
    .notes
        Could be named func 'Module.OnRemove' ?
    #>
    "GitServe: OnRemove => Cleaning up HttpListener and ThreadJobs..." | Write-Host -Fore 'Yellow'
    Stop-GitServe
}
