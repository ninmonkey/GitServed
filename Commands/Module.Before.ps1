# Ensure http outputs default to utf8
$OutputEncoding = (
    [Console]::OutputEncoding = [Console]::InputEncoding =
    [System.Text.UTF8Encoding]::new( <# bool: encoderShouldEmitUTF8Identifier #> $false )
)

# Core config passed to ThreadJobs
$script:ModuleState = [hashtable]::Synchronized(@{
    HostName = $null
    Port = $null
    JobName = $null
    Using_CleanupOnRemoveEvent = $true
    CorsAllowOrigin = @('*')
    CorsAllowMethods = 'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD'
    CorsAllowHeaders = 'Content-Type, Authorization, X-Requested-With'
    CorsAllowCredentials = $false

    ClonedRepoRoot = @( 'c:/GitLoggerApp/ClonedRepos', '/cloned-repos' ) # configure with: GitServe.Set-ConfigRepoRoot

    JsonCacheRepoList = Join-Path $env:LocalAppData 'GitServe\Cache\RepoList.json'  # fix(portability): make defaults cross platform like linux ~/.GitServe/Cache/RepoList.json
})

# Core shared cache # nyi
$script:ResponseCache = [hashtable]::Synchronized(@{})

[Net.HttpListener] $script:Listener = [Net.HttpListener]::new()

#region Init Json Cache for RepoList
if( -not ( Test-Path ( $script:ModuleState.JsonCacheRepoList ) ) ) {
    New-Item -path $script:ModuleState.JsonCacheRepoList -Force
}
#endregion Init Json Cache for RepoList
