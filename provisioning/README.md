# PnP PowerShell Provisioning Scripts

This directory contains PowerShell scripts for provisioning various SharePoint resources for KFCGD.

## Scripts Overview

1. **01-termstore.ps1**: Creates a term store group and term sets with the agreed taxonomy.
2. **02-sitecolumns.ps1**: Creates site columns with agreed internal names.
3. **03-contenttypes.ps1**: Creates content types inheriting from the Document content type and adds required site columns.
4. **04-library.ps1**: Creates a document library titled 'Gestor Documental', enables content types, adds GD content types, and the site columns.

## Usage

Each script requires the tenant URL as a parameter, and you can connect using the following command:
```powershell
Connect-PnPOnline -Url <tenant>/sites/KFCGD -Interactive
```

## Script Details

### 01-termstore.ps1
```powershell
param(
    [string]$tenantUrl
)

# Connect to PnP Online
Connect-PnPOnline -Url $tenantUrl -Interactive

# Create Term Store Group
$groupName = "GestorDocumentalGD"
$termStore = Get-PnPTermStore
$group = Get-PnPTermGroup -TermStore $termStore | Where-Object { $_.Name -eq $groupName }
if (-not $group) {
    $group = New-PnPTermGroup -Name $groupName
}

# Create Term Sets (Closed)
# Add idempotency checks for term sets here...
```

### 02-sitecolumns.ps1
```powershell
param(
    [string]$tenantUrl
)

# Connect to PnP Online
Connect-PnPOnline -Url $tenantUrl -Interactive

# Create Site Columns
# Add idempotency checks for site columns here...
```

### 03-contenttypes.ps1
```powershell
param(
    [string]$tenantUrl
)

# Connect to PnP Online
Connect-PnPOnline -Url $tenantUrl -Interactive

# Create Content Types GD – PO and GD – IT
# Add idempotency checks for content types...
```

### 04-library.ps1
```powershell
param(
    [string]$tenantUrl
)

# Connect to PnP Online
Connect-PnPOnline -Url $tenantUrl -Interactive

# Create Document Library
# Enable Content Types
# Add GD Content Types and Site Columns
```

