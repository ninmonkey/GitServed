function Get-GitServeNextDateForPeriod {
    <#
    .synopsis
        For a given time period, get the next closest date
    .link
        GitServe.Get-NextDatePeriod
    .link
        GitServe.Get-DatePaginationKey
    #>
    [Alias(
        'NextDateForPeriod',
        'GitServe.Get-NextDatePeriod'
    )]
    [CmdletBinding()]
    [OutputType( [datetime] )]
    param(
        # Relative this date
        [ValidateNotNull()]
        [Parameter(mandatory, position = 0 )]
        [datetime] $CurrentDate,

        # Amount of time to add: ( 'year' | 'month' | 'week' | 'day' | 'hour' | 'minute' | 'second' )
        [Parameter(Mandatory, position = 1)]
        [ValidateSet( 'year', 'month', 'week', 'day', 'hour', 'minute', 'second' )]
        [string] $Period = 'month',

        # optionally truncate max values when they go past MaxDate
        [Alias('UntilDate')]
        [Parameter(Position = 2)]
        [datetime] $MaxDate,

        # -Debug except it skips serialization when not being used
        [switch] $DebugInfo
    )

    $NextDate = switch( $Period ) {
        'year' {
            $CurrentDate.AddYears( 1 )
        }
        'month' {
            $CurrentDate.AddMonths( 1 )
        }
        'week' {
            $CurrentDate.AddDays( 7 )
        }
        'day' {
            $CurrentDate.AddDays( 1 )
        }
        'hour' {
            $CurrentDate.AddHours( 1 )
        }
        'minute' {
            $CurrentDate.AddMinutes( 1 )
        }
        'second' {
            $CurrentDate.AddSeconds( 1 )
        }
        default { throw "Unhandled $Period" }
    }

    # inputs are invalid, so throw
    if( $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('MaxDate') -and  $maxDate -le $CurrentDate ) {
        throw "Get-GitServeNextDateForPeriod: MaxDate cannot be less than initial CurDate! ( Max: ${MaxDate}, Current: ${CurrentDate} )"
    }

    # if nextDate is non-null, but still out of bounds: wrap within bounds
    # ( only when MaxDate was defined )
    if(
        $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('MaxDate') -and
        $nextDate -ge $maxDate
    ) {
        $nextDate = $maxDate # ie: [Math]::Min
    }

    if( ( $null -eq $NextDate ) -or $DebugInfo) {
    # $NextDate | Write-Host -bg blue
        @{
            Current = $CurrentDate
            Next    = $NextDate
            Max     = $MaxDate
            Period  = $Period
        } | ConvertTo-Json -Compress | Write-Debug -Debug
    }
    # if null, do not return a key. but do not throw since  inputs were valid.
    if( $null -eq $NextDate ) {
        # Write-Warning 'Get-GitServeNextDateForPeriod: NextDate was null for input'
        return $null
    }


    # all conditions are valid
    return $nextDate
}
