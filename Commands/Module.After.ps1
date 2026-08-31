# Ensure global 'git' alias resolves to RealGit instead of ugit
#   either [1] remove it
# Remove-Alias -Name 'git'
#   or [2] set to GitServe.Invoke-RealGit )
#       Set-Alias git -Value GitServe.Invoke-RealGit # -Force # -Scope Global

Set-Alias 'UGit' -value 'ugit\Use-Git'

# Use Module Removed Event for Cleanup
# This could be turned into a "common module filename" at '/Private/Module.OnRemoveModule.ps1'

if( $ModuleState.Using_CleanupOnRemoveEvent ) {
    $ExecutionContext.SessionState.Module.OnRemove = {
        OnRemoveModule_Handler
    }
}
