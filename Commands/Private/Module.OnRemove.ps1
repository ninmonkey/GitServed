function OnRemoveModule_Handler {
    <#
    .synopsis
        Free resources when module unloads: Cleanup threads and HttpListeners
    .description
        Automatically called by event: '$ExecutionContext.SessionState.Module.OnRemove'
    #>
    "GitServe: OnRemove => Cleaning up HttpListener and ThreadJobs..." | Write-Host -Fore 'Yellow'
    Stop-GitServe
}
