<#
.SYNOPSIS
  Crea el Term Set "GD - Lineas de Proceso" y el campo de taxonomía GD_LineaProceso.
.DESCRIPTION
  - Conecta con -Interactive
  - Asegura que el Term Group GestorDocumentalGD existe (creado por ../01-termstore.ps1)
  - Crea el Term Set "GD - Lineas de Proceso" (Closed) con términos semilla si no existe
  - Crea el campo de taxonomía GD_LineaProceso (multi-valor) si no existe
.NOTES
  Ejecutar DESPUÉS de ../01-termstore.ps1 y ../02-sitecolumns.ps1
  Ejecutar ANTES  de 03-rd-contenttype.ps1
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$TenantUrl,

  [string]$SiteRelativeUrl = '/sites/ecu-devgestioncalidadplt',

  [string]$TermGroupName = 'GestorDocumentalGD',

  [string]$ClientId,
  [string]$Tenant
)

$siteUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
$connectParams = @{ Url = $siteUrl; Interactive = $true }
if ($ClientId) { $connectParams['ClientId'] = $ClientId }
if ($Tenant)   { $connectParams['Tenant']   = $Tenant }
#Connect-PnPOnline @connectParams

$group        = 'GD Columns'
$termSetName  = 'GD - Lineas de Proceso'

# ─────────────────────────────────────────────────────────────────────────────
# 1) Asegurar Term Set + términos semilla
# ─────────────────────────────────────────────────────────────────────────────

Write-Host "Ensuring Term Group: $TermGroupName"
$termGroup = Get-PnPTermGroup -Identity $TermGroupName -ErrorAction SilentlyContinue
if (-not $termGroup) {
  throw "Term Group '$TermGroupName' no encontrado. Ejecuta ../01-termstore.ps1 primero."
}

Write-Host "Ensuring Term Set:   $termSetName"
$termSet = Get-PnPTermSet -Identity $termSetName -TermGroup $TermGroupName -ErrorAction SilentlyContinue
if (-not $termSet) {
  New-PnPTermSet -Name $termSetName -TermGroup $TermGroupName | Out-Null
  # Re-fetch: New-PnPTermSet no devuelve el objeto de forma fiable en todas las versiones
  $termSet = Get-PnPTermSet -Identity $termSetName -TermGroup $TermGroupName
  Write-Host "Created Term Set: $termSetName"

  # Términos semilla (líneas de proceso típicas en planta KFC)
  $seedTerms = @(
    'Todas',
    'Fileteado',
    'Corte',
    'Cocción',
    'Marinado',
    'Empaque',
    'Congelación',
    'Distribución',
    'Control de Calidad',
    'Limpieza y Desinfección',
    'Mantenimiento'
  )

  foreach ($term in $seedTerms) {
    $existing = Get-PnPTerm -Identity $term -TermSet $termSetName -TermGroup $TermGroupName -ErrorAction SilentlyContinue
    if (-not $existing) {
      New-PnPTerm -Name $term -TermSet $termSetName -TermGroup $TermGroupName -ErrorAction SilentlyContinue | Out-Null
      Write-Host "  Created term: $term"
    } else {
      Write-Host "  Term exists:  $term"
    }
  }
} else {
  Write-Host "Term Set already exists (skip): $termSetName"
}

# ─────────────────────────────────────────────────────────────────────────────
# 2) Crear campo de taxonomía GD_LineaProceso (multi-valor)
# ─────────────────────────────────────────────────────────────────────────────

if (Get-PnPField -Identity 'GD_LineaProceso' -ErrorAction SilentlyContinue) {
  Write-Host "Field exists (skip): GD_LineaProceso"
} else {
  Add-PnPTaxonomyField `
    -DisplayName  'Líneas de proceso' `
    -InternalName 'GD_LineaProceso' `
    -Group        $group `
    -TaxonomyItemId $termSet.Id `
    -MultiValue:$true `
    -AddToDefaultView:$false | Out-Null

  Write-Host "Created taxonomy field: GD_LineaProceso (TermSet: $termSetName, multi-valor)"
}

Write-Host ""
Write-Host "OK. Taxonomy field for 'Documentos relacionados' provisioned."
