<#
.SYNOPSIS
   This script creates managed metadata site columns in SharePoint Online using PnP PowerShell.
.DESCRIPTION
   The script connects to SharePoint Online interactively and creates taxonomy fields based on the specified term sets.
.PARAMETER TenantUrl
   The URL of the tenant where SharePoint Online is hosted.
.PARAMETER SiteRelativeUrl
   The relative URL of the SharePoint site. Defaults to '/sites/KFCGD'.
.PARAMETER TermGroupName
   The name of the term group where term sets are located. Defaults to 'GestorDocumentalGD'.
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$TenantUrl,
    [string]$SiteRelativeUrl = '/sites/KFCGD',
    [string]$TermGroupName = 'GestorDocumentalGD'
)

# Connect to SharePoint Online interactively
Connect-PnPOnline -Url $TenantUrl -UseWebLogin

# Function to create a taxonomy field
function CreateTaxonomyField {
    param (
        [string]$FieldName,
        [string]$TermSetName,
        [bool]$IsMultiChoice = $false
    )

    $TermSet = Get-PnPTermSet -Group $TermGroupName -TermSet $TermSetName
    if ($null -eq $TermSet) {
        Write-Host "Term Set '$TermSetName' not found in group '$TermGroupName'. Skipping..."
        return
    }

    # Add the taxonomy field
    if ($IsMultiChoice) {
        Add-PnPTaxonomyField -FieldName $FieldName -Group 'GD Columns' -TermSet $TermSet.Id -SspId $TermSet.SspId -AllowMultipleValues $true -Required $false
    } else {
        Add-PnPTaxonomyField -FieldName $FieldName -Group 'GD Columns' -TermSet $TermSet.Id -SspId $TermSet.SspId -Required $false
    }
}

# Create taxonomy fields
CreateTaxonomyField -FieldName 'GD_Categoria' -TermSetName 'GD - Categoria'
CreateTaxonomyField -FieldName 'GD_Alcance' -TermSetName 'GD - Alcance'
CreateTaxonomyField -FieldName 'GD_Confidencialidad' -TermSetName 'GD - Confidencialidad'
CreateTaxonomyField -FieldName 'GD_PlantasAplicables' -TermSetName 'GD - Plantas y Centros' -IsMultiChoice $true
CreateTaxonomyField -FieldName 'GD_HomologacionPlanta' -TermSetName 'GD - Plantas y Centros' -IsMultiChoice $true
CreateTaxonomyField -FieldName 'GD_Producto' -TermSetName 'GD - Producto - Familia - SKU' -IsMultiChoice $true
CreateTaxonomyField -FieldName 'GD_DepartamentoResponsable' -TermSetName 'GD - Areas - Departamentos'
CreateTaxonomyField -FieldName 'GD_CargoLiderPO' -TermSetName 'GD - Cargos - Roles'
CreateTaxonomyField -FieldName 'GD_AmbitoPrograma' -TermSetName 'GD - Ambito - Programa'

# Attach fields to content types if they exist
$contentTypes = Get-PnPContentType
foreach ($contentType in $contentTypes) {
    if ($contentType.Name -eq 'GD – PO' -or $contentType.Name -eq 'GD – IT') {
        foreach ($fieldName in @('GD_Categoria', 'GD_Alcance', 'GD_Confidencialidad', 'GD_PlantasAplicables', 'GD_HomologacionPlanta', 'GD_Producto', 'GD_DepartamentoResponsable', 'GD_CargoLiderPO', 'GD_AmbitoPrograma')) {
            if (Get-PnPField -Identity $fieldName -ErrorAction SilentlyContinue) {
                Add-PnPFieldToContentType -Field $fieldName -ContentType $contentType -ErrorAction SilentlyContinue;
            }
        }
    }
}
