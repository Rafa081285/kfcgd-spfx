<#
.SYNOPSIS
  Crea columnas de taxonomía (Managed Metadata) en el sitio.
.DESCRIPTION
  - Conecta con -Interactive
  - Resuelve Term Group + Term Set
  - Crea campos MM idempotentes
  - Multi-value donde corresponde (GD_Producto, GD_PlantasAplicables, GD_HomologacionPlanta)
.NOTES
  Ejecutar después de 01-termstore.ps1 y antes de 03-contenttypes.ps1
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$TenantUrl,

  [string]$SiteRelativeUrl = '/',

  [string]$TermGroupName = 'GestorDocumentalGD',

  [string]$ClientId,
  [string]$Tenant
)

$siteUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
$connectParams = @{ Url = $siteUrl; Interactive = $true }
if ($ClientId) { $connectParams['ClientId'] = $ClientId }
if ($Tenant)   { $connectParams['Tenant']   = $Tenant }
#Connect-PnPOnline @connectParams

$group = 'GD Columns'

function Get-TermSetByName {
  param(
    [Parameter(Mandatory=$true)][string]$TermGroupName,
    [Parameter(Mandatory=$true)][string]$TermSetName
  )

  # En PnP.PowerShell, esta forma es la más consistente cuando ya conoces el nombre del term set y el grupo
  $ts = Get-PnPTermSet -Identity $TermSetName -TermGroup $TermGroupName -ErrorAction SilentlyContinue
  if (-not $ts) {
    throw "No se encontró el TermSet '$TermSetName' en el grupo '$TermGroupName'."
  }
  return $ts
}

function Ensure-TaxonomyField {
  param(
    [Parameter(Mandatory=$true)][string]$InternalName,
    [Parameter(Mandatory=$true)][string]$DisplayName,
    [Parameter(Mandatory=$true)][string]$TermSetName,
    [switch]$Multi
  )

  if (Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue) {
    Write-Host "Field exists: $InternalName"
    return
  }

  # Validación: que el term set exista
  $null = Get-TermSetByName -TermGroupName $TermGroupName -TermSetName $TermSetName

  # Importante: Dependiendo de tu versión de PnP.PowerShell, la firma de Add-PnPTaxonomyField puede variar.
  # Esta variante (con TermSetPath + MultiValue) es la que suele funcionar en versiones modernas.
  Add-PnPTaxonomyField `
    -DisplayName $DisplayName `
    -InternalName $InternalName `
    -Group $group `
    -TermSetPath "$TermGroupName|$TermSetName" `
    -MultiValue:$($Multi.IsPresent) `
    -AddToDefaultView:$false | Out-Null

  Write-Host "Created taxonomy field: $InternalName (TermSet: $TermSetName)"
}

# Campos MM
Ensure-TaxonomyField -InternalName 'GD_Categoria'               -DisplayName 'Categoría'                -TermSetName 'GD - Categoria'
Ensure-TaxonomyField -InternalName 'GD_Alcance'                 -DisplayName 'Alcance'                  -TermSetName 'GD - Alcance'
Ensure-TaxonomyField -InternalName 'GD_Confidencialidad'        -DisplayName 'Confidencialidad'         -TermSetName 'GD - Confidencialidad'
Ensure-TaxonomyField -InternalName 'GD_PlantasAplicables'       -DisplayName 'Plantas aplicables'       -TermSetName 'GD - Plantas y Centros' -Multi
Ensure-TaxonomyField -InternalName 'GD_HomologacionPlanta'      -DisplayName 'Homologación planta'      -TermSetName 'GD - Plantas y Centros' -Multi
Ensure-TaxonomyField -InternalName 'GD_Producto'                -DisplayName 'Producto'                 -TermSetName 'GD - Producto - Familia - SKU' -Multi
Ensure-TaxonomyField -InternalName 'GD_DepartamentoResponsable' -DisplayName 'Departamento responsable' -TermSetName 'GD - Areas - Departamentos'
Ensure-TaxonomyField -InternalName 'GD_CargoLiderPO'            -DisplayName 'Cargo líder PO'           -TermSetName 'GD - Cargos - Roles'
Ensure-TaxonomyField -InternalName 'GD_AmbitoPrograma'          -DisplayName 'Ámbito/Programa'          -TermSetName 'GD - Ambito - Programa'

Write-Host "OK. Taxonomy fields provisioned."
