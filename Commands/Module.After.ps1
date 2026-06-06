# Use Module Removed Event for Cleanup
# This could be turned into a "common module filename" at '/Private/Module.OnRemoveModule.ps1'

if( $ModuleState.Using_CleanupOnRemoveEvent ) {
    $ExecutionContext.SessionState.Module.OnRemove = {
        OnRemoveModule_Handler
    }
}
