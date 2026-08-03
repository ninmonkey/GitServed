
function _new-PaginationKey {
    <#
    .synopsis
        (internal) standard record shape for "Get-DatePaginationKey" return value
    .DESCRIPTION
        Used for git (log/shortlog) parameters and other pagination
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [datetime] $Since,

        [Parameter(Mandatory)]
        [datetime] $Until
    )

    [pscustomobject][ordered]@{
        PSTypeName   = 'GitServe.Date.PaginationKey'
        Since        = $Since
        Until        = $Until
        SinceDisplay = $Since.ToString('yyyy-MM-dd')
        UntilDisplay = $Until.ToString('yyyy-MM-dd')
    }
}
function Get-GitServeDatePaginationKey {
    <#
    .synopsis
        Get keys to paginate a date range, ex: for git log filters
    .DESCRIPTION
    .example
        > GitServe.Get-DatePaginationKey -StartDate (Get-Date)
    .example
        > GitServe.Get-DatePaginationKey -StartDate '2026-01-03'
        > GitServe.Get-DatePaginationKey -StartDate '2026-04-01'

        Since                  Until                  SinceDisplay  UntilDisplay
        -----                  -----                  ------------  ------------
        2026-01-01 12:00:00 AM 2026-02-01 12:00:00 AM 2026-01-01    2026-02-01
        2026-04-01 12:00:00 AM 2026-05-01 12:00:00 AM 2026-04-01    2026-05-01
    .link
        GitServe.Get-NextDatePeriod
    .link
        GitServe.Get-DatePaginationKey
    #>
    [Alias('GitServe.Get-DatePaginationKey')]
    [OutputType( 'GitServe.Date.PaginationKey[]' )]
    [CmdletBinding()]
    param(
        # First date
        [Parameter(Mandatory)]
        [datetime] $StartDate,

        # Amount of time to add. 1 month is the default value. Values: ( 'year' | 'month' | 'week' | 'day' | 'hour' | 'minute' | 'second' )
        [ValidateSet( 'year', 'month', 'week', 'day', 'hour', 'minute', 'second' )]
        [string] $Period = 'month',

        # Optional ending date. If set, this will return an array of all steps until the final one.
        # otherwise, ending is the default net first date step
        [Parameter()]
        [datetime] $UntilDate
    )
    [Collections.Generic.List[Object]] $allKeys = @()

    [datetime] $startDate_firstOfMonth = # first day of month of the input
        [datetime]::ParseExact(
            $StartDate.ToString('yyyy-MM-01'),
            'yyyy-MM-dd', ([cultureinfo]::GetCultureInfo('en-us')) )


    $startPeriod = $startDate_firstOfMonth
    while( $true ) {
        $splat_nextPeriod = @{
            CurrentDate = $startPeriod
            Period      = $Period
        }

        if( $null -ne $UntilDate ) {
            $splat_nextPeriod['MaxDate'] = $UntilDate
        }

        # initial value was: nextMonthDate_firstOfMonth
        $nextPeriod = GitServe.Get-NextDatePeriod @splat_nextPeriod
        if( $null -eq $nextPeriod ) {
            Write-Error "GitServe.Get-DatePaginationKey: Unhandled Period: ${period} ! StartPeriod: ${StartPeriod}, End: ${UntilDate}, StartDate: ${StartDate})"
            break
        }

        $splat_dates = @{
            Since = $startPeriod
            Until = $nextPeriod
        }
        $allKeys.Add(
            ( _new-PaginationKey @splat_dates )
        )
        $startPeriod = $nextPeriod
    }
    return ,$allKeys
}
