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

    # if null, do not return a key. but do not throw since  inputs were valid.
    if( $null -eq $NextDate ) {
        Write-Warning 'NextDate was null for input'
        return
    }

    # inputs are invalid, so throw
    if( $maxDate -le $curDate ) {
        throw "MaxDate cannot be less than CurDate!"
    }

    # if non-null, but still out of bounds: wrap within bounds
    if( $nextDate -ge $maxDate ) {
        $nextDate = $maxDate # [Math]::Min
    }

    if( $DebugInfo ) {
        @{
            Current = $CurrentDate
            Next    = $NextDate
            Period  = $Period
        } | ConvertTo-Json -Compress | Write-Debug
    }

    # all conditions are valid
    return $nextDate
}
