<#
.SYNOPSIS
  Script to provision a document library in SharePoint using PnP.PowerShell
.DESCRIPTION
  This script checks if the document library exists and provisions it if not. It also configures content types as specified.
.PARAMETER TenantUrl
  The URL of the tenant.
.PARAMETER SiteRelativeUrl
  The relative URL of the site. Default is '/sites/KFCGD'.
.PARAMETER LibraryTitle
  The title of the document library. Default is 'Gestor Documental'.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantUrl,
    [string]$SiteRelativeUrl = '/sites/KFCGD',
    [string]$LibraryTitle = 'Gestor Documental'
)

# Connect to SharePoint
Connect-PnPOnline -Url $TenantUrl -UseWebLogin

# Check if the document library exists
$libraryExists = Get-PnPList -Identity $LibraryTitle -ErrorAction SilentlyContinue

if (-not $libraryExists) {
    # Provision the document library
    New-PnPList -Title $LibraryTitle -Template DocumentLibrary
    Write-Host "Document library '$LibraryTitle' created."
} else {
    Write-Host "Document library '$LibraryTitle' already exists."
}

# Enable content types
Set-PnPList -Identity $LibraryTitle -EnableContentTypes $true

# Add content types
Add-PnPContentTypeToList -List $LibraryTitle -ContentType "GD – PO"
Add-PnPContentTypeToList -List $LibraryTitle -ContentType "GD – IT"

# Remove default document content type if safe
$defaultContentType = Get-PnPContentType -List $LibraryTitle | Where-Object { $_.Name -eq 'Document' }
if ($defaultContentType -and ($defaultContentType.Id -ne $null)) {
    # Check if it is safe to remove
    $safeToRemove = $true  # Insert logic to determine if safe to remove
    if ($safeToRemove) {
        Remove-PnPContentTypeFromList -List $LibraryTitle -ContentType $defaultContentType
        Write-Host "Default content type 'Document' removed."
    } else {
        Write-Host "Safe to remove check failed. Default content type 'Document' not removed."
    }
} else {
    Write-Host "Default content type 'Document' not found."
}