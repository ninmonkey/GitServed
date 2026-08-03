
function _new-PaginationKey {
    # standard record shape for "Get-DatePaginationKey" return value
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

    #>
    [Alias('GitServe.Get-DatePaginationKey')]
    [OutputType( 'GitServe.Date.PaginationKey[]' )]
    [CmdletBinding()]
    param(
        # First date
        [Parameter(Mandatory)]
        [datetime] $StartDate,

        [ValidateSet('day', 'week', 'month', 'year')]
        [string] $Period = 'month'
    )
    [Collections.Generic.List[Object]] $allKeys = @()

    if( $Period -ne 'month' ) { throw "NYI: param $Period " }

    [datetime] $startDate_firstOfMonth = # first day of month of the input
        [datetime]::ParseExact(
            $StartDate.ToString('yyyy-MM-01'),
            'yyyy-MM-dd', ([cultureinfo]::GetCultureInfo('en-us')) )

    [datetime] $nextMonthDate_firstOfMonth = $startDate_firstOfMonth.AddMonths( 1 )

    $splat_dates = @{
        Since = $startDate_firstOfMonth
        Until = $nextMonthDate_firstOfMonth
    }


    # finish implementing

    $allKeys.Add(
        ( _new-PaginationKey @splat_dates )
    )

    return ,$allKeys
}
