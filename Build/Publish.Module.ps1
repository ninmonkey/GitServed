# $publishModuleSplat = @{
#     Name = 'GitServe'
#     Repository = 'PSGallery'
#     NuGetApiKey = $env:PSGalleryApiKey
#     ProjectUri = 'https://github.com/ninmonkey/GitServed'

# }

# Publish-Module @publishModuleSplat

$publishPSResourceSplat = @{
    Confirm    = $true
    # WhatIf     = $true
    Name       = 'GitServe'
    ApiKey     = $env:PSGalleryApiKey
    Repository = 'PSGallery'

    # Path = 'str'
    # DestinationPath = 'str'
    # Credential = 'cred'
    # SkipDependenciesCheck = $true
    # SkipModuleManifestValidate = $true
}

Publish-PSResource @publishPSResourceSplat
