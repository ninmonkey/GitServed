<#
to add


DateFromStr('yyyy-MM-dd)
DateToStr( parseExact )
DateIsEqual
DateOnlyIsEqual

#>


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
