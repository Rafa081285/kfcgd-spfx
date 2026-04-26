<#
.SYNOPSIS
    This script provisions content types in a SharePoint site.
.DESCRIPTION
    It ensures that the specified content types exist and attaches necessary fields.
.PARAMETER TenantUrl
    The URL of the SharePoint tenant.
.PARAMETER SiteRelativeUrl
    The relative URL of the SharePoint site. Default is '/sites/KFCGD'.
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$TenantUrl,
    [string]$SiteRelativeUrl = '/sites/KFCGD'
)

# Connect to SharePoint
Connect-PnPOnline -Url $TenantUrl -UseWebLogin

# Function to ensure content type exists
function Ensure-ContentTypeExists {
    param (
        [string]$ContentTypeName,
        [string]$ContentTypeID,
        [string]$GroupName
    )

    $contentType = Get-PnPContentType -Identity $ContentTypeID -ErrorAction SilentlyContinue
    if (-not $contentType) {
        $contentType = New-PnPContentType -Name $ContentTypeName -Id $ContentTypeID -Group $GroupName -FieldLinks @() -Description "Content Type for $ContentTypeName"
    }
    return $contentType
}

# Ensure the GD – PO and GD – IT content types exist
$gdPoContentType = Ensure-ContentTypeExists -ContentTypeName 'GD – PO' -ContentTypeID '0x010100000000000040B008C6F83247C3A5611F4F63C67BFE' -GroupName 'GD Content Types'
$gdItContentType = Ensure-ContentTypeExists -ContentTypeName 'GD – IT' -ContentTypeID '0x010100000000000051A0003C7B9D148EB9735386747416F3' -GroupName 'GD Content Types'

# Attach base fields from 02-sitecolumns
$currentFields = Get-PnPField -List $SiteRelativeUrl + '/02-sitecolumns'
foreach ($field in $currentFields) {
    Add-PnPFieldToContentType -Field $field -ContentType $gdPoContentType
    Add-PnPFieldToContentType -Field $field -ContentType $gdItContentType
}

# Attach taxonomy fields from 05
$taxonomyFields = Get-PnPField -List $SiteRelativeUrl + '/05'
foreach ($taxonomyField in $taxonomyFields) {
    if ($taxonomyField.InternalName) {
        Add-PnPFieldToContentType -Field $taxonomyField -ContentType $gdPoContentType
        Add-PnPFieldToContentType -Field $taxonomyField -ContentType $gdItContentType
    }
}