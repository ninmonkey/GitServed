function New-HtmlTemplate {
    <#
    .SYNOPSIS
        Return a bare-bones html doc with the right charset
    #>
    param(
        [string] $Title = 'GitServe',

        [Alias('Content')]
        [string] $HtmlContent = '<h1>GitLogger</h1>'
    )
    [string] $template = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${Title}</title>
</head>
<body>
${HtmlContent}
</body>
</html>
"@
    $template -join [Environment]::NewLine
}
