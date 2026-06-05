#requires -PSEdition Core
#requires -Modules pansies
<#
.SYNOPSIS
    Builds the current repo's module including FormatData
.Description
Uses standard names across repos:
    - Build.Module.ps1 - Assemble module
    - Build.ezout.ps1 - Build FormatData
.EXAMPLE
    # If you want to inspect the summary, dot source it
    . .\Build\Build.Module.ps1; $commands_summary ;

.Example
    # Show summaries of functions assembled:

    . .\Build\Build.Module.ps1; $commands_summary ;
    $commands_private | ft
    $commands_public  | ft
    $commands_summary | ft
#>
$myFile       = $MyInvocation.MyCommand.ScriptBlock.File
$myModuleName = 'GitServed'
$myRoot       = $myFile | Split-Path | Split-Path
$BuildConfig = @{
    LineEnding = "`r`n"
}
$cdStackName = "${myModuleName}.build"
Import-Module Pansies

Push-Location -Stack $cdStackName $myRoot
$commands_public   = @(
    # to recurse or not ?
    @( foreach ( $potentialDirectory in 'Commands/Public' ) {
        Get-ChildItem -Recurse -ea ignore -Path ( Join-Path $myRoot $potentialDirectory )
    })
    | Where-Object name -NotMatch '^Scrap'
    | Where-Object name -NotMatch '^ModuleBody\.ps1'
    | ? Extension -in '.ps1' #, '.psm1', '.psd1'
)
$commands_private   = @(
    # to recurse or not ?
    @( foreach ( $potentialDirectory in 'Commands/Private') {
        Get-ChildItem -Recurse -ea ignore -Path ( Join-Path $myRoot $potentialDirectory )
    })
    | Where-Object name -NotMatch '^Scrap'
    | Where-Object name -NotMatch '^ModuleBody\.ps1'
    | ? Extension -in '.ps1' #, '.psm1', '.psd1'
)

$moduleBody = Join-Path 'Commands' 'ModuleBody.ps1' | Get-Item -ea ignore

[Collections.Generic.List[object]] $commands_summary = @()
$commands_summary.AddRange(
    @(
        $commands_public
        | %{
            $item = $_
            [pscustomobject]@{
                PSTypeName    = 'build.getserve.command.public'
                Public        = $true
                Name          = $Item.Name
                Size          = '{0:n2} kb' -f ( $Item.Length / 1kb )
                LastWriteTime = $Item.LastWriteTime
                Verb          = @( $Item.BaseName -split '-', 2 )[0]
                # Path          = $Item
                FullName      = $Item                                  # convert to alias
                # Documentation = ''
                # HasRequiresStatment        = $false
                # HasUsingNamespaceStatement = $false
            }
        }
        | Sort-Object Verb, Name
    )
)
$commands_summary.AddRange(
    @(
        $commands_private
        | %{
            $item = $_
            [pscustomobject]@{
                PSTypeName    = 'build.getserve.command.private'
                Public        = $False
                Name          = $Item.Name
                Size          = '{0:n2} kb' -f ( $Item.Length / 1kb )
                LastWriteTime = $Item.LastWriteTime
                Verb          = @( $Item.BaseName -split '-', 2 )[0]
                # Path          = $Item
                FullName      = $Item                                  # convert to alias
                # Documentation = ''
                # HasRequiresStatment        = $false
                # HasUsingNamespaceStatement = $false
            }
        }
        | Sort-Object Verb, Name
    )
)

$destinationRoot = $myRoot

$commands_summary
    | Join-String -f "`n {0}" -op 'Commands' -p {
        [System.IO.Path]::GetRelativePath( $myRoot, $_.FullName )
    }
    | Write-Host -fg 'magenta'
Pop-Location -Stack $cdStackName

if( $commands_summary.count -gt 0 ) {
    $myModuleFile = Join-Path $DestinationRoot "${myModuleName}.psm1"

    @(
        foreach ( $item in ( $commands_summary | ? -Not Public ) )  {
            ( Get-Content -raw (Get-Item $item.FullName ) ) -replace '\r?\n', $BuildConfig.LineEnding
        }
        # todo: optimize IO. And minimize any extra memory allocations for strings
        foreach ( $item in ( $commands_summary | ? Public ) )  {
            ( Get-Content -raw (Get-Item $item.FullName ) ) -replace '\r?\n', $BuildConfig.LineEnding
        }

        foreach( $item in $moduleBody ) {
            ( Get-Content -raw (Get-Item $item.FullName ) ) -replace '\r?\n', $BuildConfig.LineEnding
        }
    )
    | Join-String -sep $BuildConfig.LineEnding
    | Set-Content -Path $MyModuleFile -encoding UTF8 -ProgressAction Continue # -Confirm
}
return
if ($commands_public) {
    $myFormatFile = Join-Path $destinationRoot "$myModuleName.format.ps1xml"
    $commands_public
        | Out-FormatData -Module $MyModuleName
        | Set-Content $myFormatFile -Encoding UTF8 -Verbose -ProgressAction Continue # -Confirm
    Get-Item $myFormatFile
}

$types = @(
    # Add your own Write-TypeView statements here
    # or declare them in the 'Types' directory
    Join-Path $myRoot Types
        | Get-Item -ea ignore
        | Import-TypeView

)

if ($types) {
    $myTypesFile = Join-Path $destinationRoot "$myModuleName.types.ps1xml"
    $types
        | Out-TypeData
        | Set-Content $myTypesFile -Encoding UTF8 -Verbose -ProgressAction Continue # -Confirm

    Get-Item $myTypesFile
}
Pop-Location
