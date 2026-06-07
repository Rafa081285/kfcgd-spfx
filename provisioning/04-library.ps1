<#
.SYNOPSIS
  Crea/asegura la biblioteca y configura Content Types.
.DESCRIPTION
  - Conecta con -Interactive
  - Biblioteca parametrizada con -LibraryTitle
  - Habilita Content Types
  - Agrega CTs "GD – PO" y "GD – IT"
  - NO elimina el CT "Document" por defecto (recomendado)
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$TenantUrl,

  [string]$SiteRelativeUrl = '/sites/ecu-devgestioncalidadplt',

  [string]$LibraryTitle = 'Gestor Documental',

  [string]$ClientId,
  [string]$Tenant
)

$siteUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
$connectParams = @{ Url = $siteUrl; Interactive = $true }
if ($ClientId) { $connectParams['ClientId'] = $ClientId }
if ($Tenant)   { $connectParams['Tenant']   = $Tenant }
#Connect-PnPOnline @connectParams

# Ensure library
$list = Get-PnPList -Identity $LibraryTitle -ErrorAction SilentlyContinue
if (-not $list) {
  New-PnPList -Title $LibraryTitle -Template DocumentLibrary | Out-Null
  Write-Host "Library created: $LibraryTitle"
} else {
  Write-Host "Library already exists: $LibraryTitle"
}

# Enable Content Types on the library
Set-PnPList -Identity $LibraryTitle -EnableContentTypes $true | Out-Null

# Ensure CTs exist at site level (created by 03)
$ctNames = @('GD – PO', 'GD – IT')
foreach ($ctName in $ctNames) {
  $ct = Get-PnPContentType -Identity $ctName -ErrorAction SilentlyContinue
  if (-not $ct) {
    Write-Warning "Content Type '$ctName' no existe en el sitio. Ejecuta 03-contenttypes.ps1 antes. (Se omite por ahora)"
    continue
  }

  # Add to library (idempotente)
  Add-PnPContentTypeToList -List $LibraryTitle -ContentType $ctName -ErrorAction SilentlyContinue | Out-Null
  Write-Host "Ensured CT in library: $ctName"
}

Write-Host "OK. Library ready: $LibraryTitle"
