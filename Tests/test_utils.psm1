<#
to add


DateFromStr('yyyy-MM-dd)
DateToStr( parseExact )
DateIsEqual
DateOnlyIsEqual

#>

$PSStyle.OutputRendering = 'Host' # for pester outputs

function Str.Predent {
    param( [int] $Depth = 1 )
    $prefix = '  ' * $depth -join ''
    $Input | Join-String -f "${prefix}{0}"
}
function Log.Warn {
    <#
    .SYNOPSIS
        Logs severity level: warn, to pester log indented with color
    #>
    param( [int] $Depth = 1, [string] $Title = 'Warn' )
    $Input
    | New-Text -bg $null -fg 'salmon' # '#333333'
    | Join-String -op "${Title}: "
    | Str.Predent -Depth $Depth
    | Write-host
}
function Log.Dim {
    <#
    .SYNOPSIS
        Logs severity level: Dim, to pester log indented with color
    #>
    param( [int] $Depth = 1 )
    $Input
    | New-Text -bg $null -fg '#666666' # '#333333'
    | Str.Predent -Depth $Depth
    | Write-host
}
function Log.Info {
    <#
    .SYNOPSIS
        Logs severity level: info, to pester log indented with color
    #>
    param( [int] $Depth = 1 )
    $Input
    | New-Text -bg '#67c8da' -fg '#333333'
    | Str.Predent -Depth $Depth
    | Write-host
}

function Date.FromStr  {
    <#
    .SYNOPSIS
        Create a [DateTime] from a DateOnly string
    #>
    [OutputType( [datetime] )]
    [cmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Position = 0)]
        [Alias('Text')]
        [string] $DateStr,

        [Parameter( Position = 1)]
        [string] $Culture = 'en-us',

        [Parameter( Position = 2)]
        [string] $Format = 'yyyy-MM-dd'
    )
    begin {
        $cult = [cultureinfo]::GetCultureInfo($Culture)
    }
    process {
        $date = [datetime]::ParseExact( $DateStr, $Format, $cult )
        if( $null -eq $date ) {
            throw "Date.FromStr: Failed to parse date string '${DateStr}',  Culture: ${Culture}, Format: ${Format}"
        }
        return $date
    }
}
function Date.Str  {
    <#
    .SYNOPSIS
        Create a [DateTime] from a DateOnly string
    .example
        Date.Str ([datetime]::now)
        Date.Str ([datetime]::now) -Culture 'de-de'
        '2024-03-03' | Date.Str
    #>
    [OutputType( [string] )]
    [cmdletBinding()]
    param(
        [Parameter( ValueFromPipeline, Position = 0)]
        [datetime] $Date,

        [Parameter( Position = 1)]
        [string] $Culture = 'en-us',

        [Parameter( Position = 2)]
        [string] $Format = 'yyyy-MM-dd'
    )
    begin {
        $cult = [cultureinfo]::GetCultureInfo($Culture)
    }
    process {
        [string] $display = $Date.ToString( $Format, $cult )
        if( [string]::IsNullOrWhiteSpace( $display ) ) {
            throw "Date.Str: Failed to format date '${Date}',  Culture: ${Culture}, Format: ${Format}"
        }
        return $display
    }
}

 function Helper.CloneRepoIfMissing {
        <#
        .SYNOPSIS
            ensure repo exists at "<SourceReposRoot/Owner/Repo>" otherwise clone it
        #>
        param(
            [Parameter(Mandatory)]
            [string] $OwnerRepoPair,

            # which exact hash to checkout on
            [Parameter(Mandatory)]
            [string] $CheckoutHash,

            # what to clone
            [Parameter(Mandatory)]
            [uri]$CloneUrl,

            # folder to clone under
            [Parameter(Mandatory)]
            [string] $RepoRoot

        )
        $found = GitServe.Repo.List -WithoutCache | ? OwnerRepoPair -eq $OwnerRepoPair
        if( $Found ) { return }

        "Missing ${ownerRepPair}... Cloning..." | Log.Warn
        $ownerName, $repoName = $OwnerRepoPair -split '/', 2

        $cloneParentDir = Join-Path $RepoRoot $ownerName
        mkdir $cloneParentDir -ea Ignore -Confirm:$False

        GitServe.Invoke-RealGit -Frompath $cloneParentDir -GitArgList @(
            'clone'
            $CloneUrl
        )

        $repoFullPath = Join-path $cloneParentDir $repoName
        "Cloned to: ${repoFullPath}" | Log.Info

        GitServe.Invoke-RealGit -FromPath $repoFullPath -GitArgList @(
            'checkout'
            $CheckoutHash
        ) | Write-Verbose

        "Checked hash: ${CheckoutHash}" | Log.Info

        # force clear cache because the clone uses raw git commands to clone, and because of commit hash change
        GitServe.Repo.List -WithoutCache
    }
